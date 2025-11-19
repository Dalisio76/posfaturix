-- ===================================
-- MIGRAÇÃO: Produtos Avançados
-- 1. Código automático
-- 2. Preço de compra
-- 3. Produto contável (Sim/Não)
-- 4. IVA (Incluso/Isento)
-- 5. Composição de produtos (Menu)
-- ===================================

-- ===================================
-- 1. ADICIONAR COLUNAS À TABELA PRODUTOS
-- ===================================

-- Preço de compra
ALTER TABLE produtos
ADD COLUMN IF NOT EXISTS preco_compra DECIMAL(10,2) DEFAULT 0 NOT NULL;

-- Produto contável (true = conta estoque, false = não conta estoque)
ALTER TABLE produtos
ADD COLUMN IF NOT EXISTS contavel BOOLEAN DEFAULT true NOT NULL;

-- IVA (Incluso ou Isento)
ALTER TABLE produtos
ADD COLUMN IF NOT EXISTS iva VARCHAR(20) DEFAULT 'Incluso' NOT NULL;

-- ===================================
-- 2. CRIAR SEQUÊNCIA PARA CÓDIGO AUTOMÁTICO
-- ===================================

-- Criar sequência começando do próximo número disponível
DO $$
DECLARE
    max_codigo INTEGER;
BEGIN
    -- Buscar o maior código numérico existente
    SELECT COALESCE(MAX(CAST(codigo AS INTEGER)), 0) INTO max_codigo
    FROM produtos
    WHERE codigo ~ '^\d+$';  -- Apenas códigos numéricos

    -- Criar sequência começando do próximo número
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS produtos_codigo_seq START WITH %s', max_codigo + 1);
END $$;

-- Função para gerar próximo código
CREATE OR REPLACE FUNCTION get_proximo_codigo_produto()
RETURNS TEXT AS $$
BEGIN
    RETURN nextval('produtos_codigo_seq')::TEXT;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 3. CRIAR TABELA DE COMPOSIÇÃO DE PRODUTOS
-- Um produto pode ser composto por outros produtos
-- ===================================

CREATE TABLE IF NOT EXISTS produto_composicao (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    produto_componente_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    quantidade DECIMAL(10,2) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(produto_id, produto_componente_id),
    -- Evitar auto-referência
    CHECK (produto_id != produto_componente_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_produto_composicao_produto ON produto_composicao(produto_id);
CREATE INDEX IF NOT EXISTS idx_produto_composicao_componente ON produto_composicao(produto_id);

-- Comentários
COMMENT ON TABLE produto_composicao IS 'Composição de produtos - produtos que são formados por outros produtos';
COMMENT ON COLUMN produto_composicao.produto_id IS 'Produto principal (ex: CAIXA)';
COMMENT ON COLUMN produto_composicao.produto_componente_id IS 'Produto componente (ex: MEIA CAIXA)';
COMMENT ON COLUMN produto_composicao.quantidade IS 'Quantidade do componente necessária (ex: 2)';

-- ===================================
-- 4. ATUALIZAR PRODUTOS EXISTENTES
-- ===================================

-- Definir valores padrão para produtos já cadastrados
UPDATE produtos
SET preco_compra = 0
WHERE preco_compra IS NULL;

UPDATE produtos
SET contavel = true
WHERE contavel IS NULL;

UPDATE produtos
SET iva = 'Incluso'
WHERE iva IS NULL;

-- ===================================
-- 5. ATUALIZAR VIEWS
-- ===================================

-- Recriar view v_produtos_completo com novos campos
DROP VIEW IF EXISTS v_produtos_completo CASCADE;

CREATE OR REPLACE VIEW v_produtos_completo AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.familia_id,
    p.preco,
    p.preco_compra,
    p.estoque,
    p.ativo,
    p.contavel,
    p.iva,
    p.created_at,
    p.updated_at,
    p.setor_id,
    p.area_id,
    f.nome as familia_nome,
    s.nome as setor_nome,
    a.nome as area_nome,
    -- Calcular margem de lucro
    CASE
        WHEN p.preco_compra > 0 THEN
            ROUND(((p.preco - p.preco_compra) / p.preco_compra * 100)::numeric, 2)
        ELSE 0
    END as margem_lucro_percentual,
    -- Verificar se tem composição
    EXISTS(SELECT 1 FROM produto_composicao pc WHERE pc.produto_id = p.id) as tem_composicao
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id;

-- View: Produtos com composição detalhada
CREATE OR REPLACE VIEW v_produtos_com_composicao AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.contavel,
    pc.produto_componente_id,
    comp.codigo as componente_codigo,
    comp.nome as componente_nome,
    pc.quantidade as componente_quantidade,
    comp.estoque as componente_estoque
FROM produtos p
INNER JOIN produto_composicao pc ON p.id = pc.produto_id
INNER JOIN produtos comp ON pc.produto_componente_id = comp.id
WHERE p.ativo = true AND comp.ativo = true
ORDER BY p.nome, comp.nome;

-- View: Resumo de produtos não-contáveis
CREATE OR REPLACE VIEW v_produtos_nao_contaveis AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.preco,
    COUNT(pc.id) as total_componentes
FROM produtos p
LEFT JOIN produto_composicao pc ON p.id = pc.produto_id
WHERE p.contavel = false AND p.ativo = true
GROUP BY p.id, p.codigo, p.nome, p.preco
ORDER BY p.nome;

-- ===================================
-- 6. FUNÇÕES ÚTEIS
-- ===================================

-- Função: Buscar composição de um produto
CREATE OR REPLACE FUNCTION get_composicao_produto(p_produto_id INTEGER)
RETURNS TABLE (
    componente_id INTEGER,
    componente_codigo VARCHAR(50),
    componente_nome VARCHAR(200),
    quantidade DECIMAL(10,2),
    estoque_disponivel INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.produto_componente_id,
        comp.codigo,
        comp.nome,
        pc.quantidade,
        comp.estoque
    FROM produto_composicao pc
    INNER JOIN produtos comp ON pc.produto_componente_id = comp.id
    WHERE pc.produto_id = p_produto_id
    AND comp.ativo = true
    ORDER BY comp.nome;
END;
$$ LANGUAGE plpgsql;

-- Função: Verificar se produto tem estoque suficiente (considerando composição)
CREATE OR REPLACE FUNCTION verificar_estoque_disponivel(
    p_produto_id INTEGER,
    p_quantidade_desejada INTEGER
)
RETURNS TABLE (
    disponivel BOOLEAN,
    mensagem TEXT
) AS $$
DECLARE
    v_contavel BOOLEAN;
    v_estoque INTEGER;
    v_tem_composicao BOOLEAN;
    v_componente RECORD;
    v_quantidade_necessaria DECIMAL;
    v_estoque_componente INTEGER;
BEGIN
    -- Buscar informações do produto
    SELECT contavel, estoque INTO v_contavel, v_estoque
    FROM produtos
    WHERE id = p_produto_id;

    -- Se produto é contável, verificar estoque direto
    IF v_contavel THEN
        IF v_estoque >= p_quantidade_desejada THEN
            RETURN QUERY SELECT true, 'Estoque disponível'::TEXT;
        ELSE
            RETURN QUERY SELECT false, format('Estoque insuficiente. Disponível: %s, Necessário: %s', v_estoque, p_quantidade_desejada)::TEXT;
        END IF;
        RETURN;
    END IF;

    -- Produto não-contável: verificar composição
    SELECT EXISTS(SELECT 1 FROM produto_composicao WHERE produto_id = p_produto_id) INTO v_tem_composicao;

    IF NOT v_tem_composicao THEN
        RETURN QUERY SELECT true, 'Produto não-contável sem composição'::TEXT;
        RETURN;
    END IF;

    -- Verificar estoque de cada componente
    FOR v_componente IN
        SELECT pc.produto_componente_id, pc.quantidade, comp.nome, comp.estoque
        FROM produto_composicao pc
        INNER JOIN produtos comp ON pc.produto_componente_id = comp.id
        WHERE pc.produto_id = p_produto_id
    LOOP
        v_quantidade_necessaria := v_componente.quantidade * p_quantidade_desejada;

        IF v_componente.estoque < v_quantidade_necessaria THEN
            RETURN QUERY SELECT
                false,
                format('Estoque insuficiente de "%s". Disponível: %s, Necessário: %s',
                    v_componente.nome,
                    v_componente.estoque,
                    v_quantidade_necessaria)::TEXT;
            RETURN;
        END IF;
    END LOOP;

    -- Todos os componentes têm estoque
    RETURN QUERY SELECT true, 'Estoque disponível (componentes)'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Função: Abater estoque de produto (considerando composição)
CREATE OR REPLACE FUNCTION abater_estoque_produto(
    p_produto_id INTEGER,
    p_quantidade INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_contavel BOOLEAN;
    v_componente RECORD;
    v_quantidade_abater DECIMAL;
BEGIN
    -- Buscar se produto é contável
    SELECT contavel INTO v_contavel
    FROM produtos
    WHERE id = p_produto_id;

    -- Se produto é contável, abater estoque direto
    IF v_contavel THEN
        UPDATE produtos
        SET estoque = estoque - p_quantidade,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_produto_id;
        RETURN;
    END IF;

    -- Produto não-contável: abater estoque dos componentes
    FOR v_componente IN
        SELECT produto_componente_id, quantidade
        FROM produto_composicao
        WHERE produto_id = p_produto_id
    LOOP
        v_quantidade_abater := v_componente.quantidade * p_quantidade;

        UPDATE produtos
        SET estoque = estoque - v_quantidade_abater,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_componente.produto_componente_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 7. TRIGGERS
-- ===================================

-- Trigger: Gerar código automático antes de inserir produto
CREATE OR REPLACE FUNCTION trigger_gerar_codigo_produto()
RETURNS TRIGGER AS $$
BEGIN
    -- Se código não foi fornecido ou está vazio, gerar automaticamente
    IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
        NEW.codigo := get_proximo_codigo_produto();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS before_insert_produto_codigo ON produtos;
CREATE TRIGGER before_insert_produto_codigo
    BEFORE INSERT ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION trigger_gerar_codigo_produto();

-- ===================================
-- 8. VERIFICAÇÃO
-- ===================================

-- Ver estrutura atualizada
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;

-- Ver produtos com novos campos
SELECT id, codigo, nome, preco, preco_compra, contavel, iva, estoque
FROM produtos
LIMIT 5;

-- Ver composições
SELECT * FROM v_produtos_com_composicao;

-- Testar geração de código
-- SELECT get_proximo_codigo_produto();

-- Testar função de composição
-- SELECT * FROM get_composicao_produto(1);

-- Testar verificação de estoque
-- SELECT * FROM verificar_estoque_disponivel(1, 5);

-- ===================================
-- 9. DADOS DE EXEMPLO
-- ===================================

-- Exemplo: Criar produto "CAIXA" não-contável composto por "MEIA CAIXA"

-- Inserir MEIA CAIXA (contável)
-- INSERT INTO produtos (nome, familia_id, preco, preco_compra, estoque, contavel, iva)
-- VALUES ('MEIA CAIXA', 1, 100.00, 80.00, 50, true, 'Incluso');

-- Inserir CAIXA (não-contável)
-- INSERT INTO produtos (nome, familia_id, preco, preco_compra, contavel, iva)
-- VALUES ('CAIXA COMPLETA', 1, 190.00, 150.00, false, 'Incluso');

-- Criar composição: CAIXA = 2x MEIA CAIXA
-- INSERT INTO produto_composicao (produto_id, produto_componente_id, quantidade)
-- VALUES (
--     (SELECT id FROM produtos WHERE nome = 'CAIXA COMPLETA'),
--     (SELECT id FROM produtos WHERE nome = 'MEIA CAIXA'),
--     2
-- );

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. Código automático é gerado automaticamente ao inserir produto
-- 2. Produtos não-contáveis devem ter composição definida
-- 3. Ao vender produto não-contável, estoque dos componentes é abatido
-- 4. IVA pode ser 'Incluso' ou 'Isento'
-- 5. Preço de compra padrão é 0
-- 6. Contável padrão é true
--
-- Para rollback:
-- DROP TABLE IF EXISTS produto_composicao CASCADE;
-- DROP SEQUENCE IF EXISTS produtos_codigo_seq;
-- ALTER TABLE produtos DROP COLUMN IF EXISTS preco_compra;
-- ALTER TABLE produtos DROP COLUMN IF EXISTS contavel;
-- ALTER TABLE produtos DROP COLUMN IF EXISTS iva;
-- ===================================
