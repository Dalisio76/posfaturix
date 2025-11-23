-- ===================================
-- TABELA: Acertos de Stock
-- Registra todos os ajustes de estoque realizados
-- ===================================

-- ===================================
-- 1. CRIAR TABELA ACERTOS_STOCK
-- ===================================
CREATE TABLE IF NOT EXISTS acertos_stock (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    estoque_anterior INTEGER NOT NULL,
    estoque_novo INTEGER NOT NULL,
    diferenca INTEGER GENERATED ALWAYS AS (estoque_novo - estoque_anterior) STORED,
    motivo VARCHAR(100) NOT NULL,
    observacao TEXT,
    setor_id INTEGER REFERENCES setores(id),
    area_id INTEGER REFERENCES areas(id),
    usuario VARCHAR(100),
    data TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 2. ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_acertos_produto ON acertos_stock(produto_id);
CREATE INDEX IF NOT EXISTS idx_acertos_data ON acertos_stock(data);
CREATE INDEX IF NOT EXISTS idx_acertos_setor ON acertos_stock(setor_id);
CREATE INDEX IF NOT EXISTS idx_acertos_area ON acertos_stock(area_id);
CREATE INDEX IF NOT EXISTS idx_acertos_motivo ON acertos_stock(motivo);

-- ===================================
-- 3. TRIGGER PARA ATUALIZAR ESTOQUE DO PRODUTO
-- ===================================
CREATE OR REPLACE FUNCTION atualizar_estoque_produto()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar o estoque do produto com o novo valor
    UPDATE produtos
    SET estoque = NEW.estoque_novo,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.produto_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_atualizar_estoque ON acertos_stock;
CREATE TRIGGER trigger_atualizar_estoque
AFTER INSERT ON acertos_stock
FOR EACH ROW
EXECUTE FUNCTION atualizar_estoque_produto();

-- ===================================
-- 4. VIEWS ÚTEIS
-- ===================================

-- View: Acertos com informações completas
CREATE OR REPLACE VIEW v_acertos_completo AS
SELECT
    a.id,
    a.produto_id,
    p.codigo as produto_codigo,
    p.nome as produto_nome,
    p.preco as produto_preco,
    a.estoque_anterior,
    a.estoque_novo,
    a.diferenca,
    a.motivo,
    a.observacao,
    a.setor_id,
    s.nome as setor_nome,
    a.area_id,
    ar.nome as area_nome,
    f.id as familia_id,
    f.nome as familia_nome,
    a.usuario,
    a.data,
    a.created_at,
    a.updated_at,
    -- Calcular valor da diferença
    (a.diferenca * p.preco) as valor_diferenca
FROM acertos_stock a
INNER JOIN produtos p ON a.produto_id = p.id
LEFT JOIN setores s ON a.setor_id = s.id
LEFT JOIN areas ar ON a.area_id = ar.id
LEFT JOIN familias f ON p.familia_id = f.id
ORDER BY a.data DESC;

-- View: Resumo de acertos por período
CREATE OR REPLACE VIEW v_acertos_resumo AS
SELECT
    DATE(a.data) as data_acerto,
    COUNT(*) as total_acertos,
    SUM(CASE WHEN a.diferenca > 0 THEN 1 ELSE 0 END) as acertos_positivos,
    SUM(CASE WHEN a.diferenca < 0 THEN 1 ELSE 0 END) as acertos_negativos,
    SUM(ABS(a.diferenca)) as total_diferencas,
    SUM(a.diferenca * p.preco) as valor_total_diferenca
FROM acertos_stock a
INNER JOIN produtos p ON a.produto_id = p.id
GROUP BY DATE(a.data)
ORDER BY DATE(a.data) DESC;

-- View: Acertos por motivo
CREATE OR REPLACE VIEW v_acertos_por_motivo AS
SELECT
    a.motivo,
    COUNT(*) as total_acertos,
    SUM(ABS(a.diferenca)) as total_diferencas,
    SUM(a.diferenca * p.preco) as valor_total_diferenca
FROM acertos_stock a
INNER JOIN produtos p ON a.produto_id = p.id
GROUP BY a.motivo
ORDER BY total_acertos DESC;

-- View: Acertos por setor
CREATE OR REPLACE VIEW v_acertos_por_setor AS
SELECT
    s.id as setor_id,
    s.nome as setor_nome,
    COUNT(a.id) as total_acertos,
    SUM(ABS(a.diferenca)) as total_diferencas,
    SUM(a.diferenca * p.preco) as valor_total_diferenca
FROM setores s
LEFT JOIN acertos_stock a ON s.id = a.setor_id
LEFT JOIN produtos p ON a.produto_id = p.id
GROUP BY s.id, s.nome
ORDER BY s.nome;

-- ===================================
-- 5. FUNÇÕES ÚTEIS
-- ===================================

-- Função: Buscar acertos por período
CREATE OR REPLACE FUNCTION buscar_acertos_por_periodo(
    p_data_inicio TIMESTAMP,
    p_data_fim TIMESTAMP,
    p_produto_nome VARCHAR DEFAULT NULL,
    p_setor_id INTEGER DEFAULT NULL,
    p_area_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    id INTEGER,
    produto_codigo VARCHAR,
    produto_nome VARCHAR,
    estoque_anterior INTEGER,
    estoque_novo INTEGER,
    diferenca INTEGER,
    motivo VARCHAR,
    setor_nome VARCHAR,
    area_nome VARCHAR,
    familia_nome VARCHAR,
    usuario VARCHAR,
    data TIMESTAMP,
    valor_diferenca DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.produto_codigo,
        a.produto_nome,
        a.estoque_anterior,
        a.estoque_novo,
        a.diferenca,
        a.motivo,
        a.setor_nome,
        a.area_nome,
        a.familia_nome,
        a.usuario,
        a.data,
        a.valor_diferenca
    FROM v_acertos_completo a
    WHERE a.data >= p_data_inicio
    AND a.data <= p_data_fim
    AND (p_produto_nome IS NULL OR a.produto_nome ILIKE '%' || p_produto_nome || '%')
    AND (p_setor_id IS NULL OR a.setor_id = p_setor_id)
    AND (p_area_id IS NULL OR a.area_id = p_area_id)
    ORDER BY a.data DESC;
END;
$$ LANGUAGE plpgsql;

-- Função: Registrar acerto de stock
CREATE OR REPLACE FUNCTION registrar_acerto_stock(
    p_produto_id INTEGER,
    p_estoque_novo INTEGER,
    p_motivo VARCHAR,
    p_observacao TEXT DEFAULT NULL,
    p_usuario VARCHAR DEFAULT 'Sistema'
)
RETURNS INTEGER AS $$
DECLARE
    v_estoque_anterior INTEGER;
    v_acerto_id INTEGER;
    v_setor_id INTEGER;
    v_area_id INTEGER;
BEGIN
    -- Obter estoque anterior e setor/área do produto
    SELECT estoque, setor_id, area_id
    INTO v_estoque_anterior, v_setor_id, v_area_id
    FROM produtos
    WHERE id = p_produto_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado', p_produto_id;
    END IF;

    -- Inserir acerto
    INSERT INTO acertos_stock (
        produto_id,
        estoque_anterior,
        estoque_novo,
        motivo,
        observacao,
        setor_id,
        area_id,
        usuario
    ) VALUES (
        p_produto_id,
        v_estoque_anterior,
        p_estoque_novo,
        p_motivo,
        p_observacao,
        v_setor_id,
        v_area_id,
        p_usuario
    )
    RETURNING id INTO v_acerto_id;

    RETURN v_acerto_id;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 6. VERIFICAÇÃO
-- ===================================

-- Ver estrutura da tabela
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'acertos_stock'
ORDER BY ordinal_position;

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. A coluna 'diferenca' é calculada automaticamente (GENERATED)
-- 2. O trigger atualiza o estoque do produto automaticamente ao inserir um acerto
-- 3. Use a função registrar_acerto_stock() para garantir integridade dos dados
-- 4. As views facilitam consultas e relatórios
-- 5. Os índices melhoram a performance das consultas
--
-- Exemplo de uso da função:
-- SELECT registrar_acerto_stock(
--     p_produto_id := 1,
--     p_estoque_novo := 150,
--     p_motivo := 'Acerto Manual',
--     p_observacao := 'Contagem física',
--     p_usuario := 'Admin'
-- );
--
-- Para rollback:
-- DROP TABLE acertos_stock CASCADE;
-- ===================================
