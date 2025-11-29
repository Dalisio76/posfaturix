-- ===================================
-- Adicionar Código de Barras aos Produtos
-- ===================================

-- 1. Adicionar coluna codigo_barras na tabela produtos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'produtos' AND column_name = 'codigo_barras'
    ) THEN
        ALTER TABLE produtos ADD COLUMN codigo_barras VARCHAR(50);
    END IF;
END $$;

-- 2. Criar índice único para código de barras (permite NULL mas não duplicados)
CREATE UNIQUE INDEX IF NOT EXISTS idx_produtos_codigo_barras ON produtos(codigo_barras)
    WHERE codigo_barras IS NOT NULL;

-- 3. Criar índice para busca rápida por código de barras
CREATE INDEX IF NOT EXISTS idx_produtos_codigo_barras_lower ON produtos(LOWER(codigo_barras))
    WHERE codigo_barras IS NOT NULL;

-- 4. Função para buscar produto por código de barras
CREATE OR REPLACE FUNCTION buscar_produto_por_codigo_barras(p_codigo_barras VARCHAR(50))
RETURNS TABLE (
    id INTEGER,
    codigo VARCHAR(50),
    nome VARCHAR(200),
    codigo_barras VARCHAR(50),
    familia_id INTEGER,
    familia_nome VARCHAR(100),
    preco DECIMAL(10,2),
    estoque INTEGER,
    ativo BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.codigo,
        p.nome,
        p.codigo_barras,
        p.familia_id,
        f.nome as familia_nome,
        p.preco,
        p.estoque,
        p.ativo
    FROM produtos p
    LEFT JOIN familias f ON f.id = p.familia_id
    WHERE LOWER(p.codigo_barras) = LOWER(p_codigo_barras)
      AND p.ativo = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 5. Função para validar código de barras (EAN-13, EAN-8, UPC, etc.)
CREATE OR REPLACE FUNCTION validar_codigo_barras(p_codigo VARCHAR(50))
RETURNS BOOLEAN AS $$
DECLARE
    tamanho INTEGER;
BEGIN
    -- Remove espaços e verifica se está vazio
    p_codigo := TRIM(p_codigo);
    IF p_codigo IS NULL OR p_codigo = '' THEN
        RETURN true; -- NULL é válido (opcional)
    END IF;

    -- Verifica se contém apenas dígitos
    IF p_codigo !~ '^[0-9]+$' THEN
        RETURN false;
    END IF;

    tamanho := LENGTH(p_codigo);

    -- Tamanhos válidos: EAN-13 (13), EAN-8 (8), UPC-A (12), UPC-E (6)
    IF tamanho NOT IN (6, 8, 12, 13) THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 6. Trigger para validar código de barras antes de inserir/atualizar
CREATE OR REPLACE FUNCTION trigger_validar_codigo_barras()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.codigo_barras IS NOT NULL THEN
        -- Remove espaços em branco
        NEW.codigo_barras := TRIM(NEW.codigo_barras);

        -- Se ficou vazio, transforma em NULL
        IF NEW.codigo_barras = '' THEN
            NEW.codigo_barras := NULL;
            RETURN NEW;
        END IF;

        -- Valida formato
        IF NOT validar_codigo_barras(NEW.codigo_barras) THEN
            RAISE EXCEPTION 'Código de barras inválido: %. Use apenas números com 6, 8, 12 ou 13 dígitos (EAN/UPC).',
                NEW.codigo_barras
                USING HINT = 'Formatos válidos: EAN-13 (13 dígitos), EAN-8 (8 dígitos), UPC-A (12 dígitos), UPC-E (6 dígitos)';
        END IF;

        -- Verifica duplicidade
        IF EXISTS (
            SELECT 1 FROM produtos
            WHERE codigo_barras = NEW.codigo_barras
              AND id != COALESCE(NEW.id, -1)
        ) THEN
            RAISE EXCEPTION 'Código de barras % já existe em outro produto!', NEW.codigo_barras
                USING HINT = 'Cada código de barras deve ser único.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validar_codigo_barras_produto ON produtos;
CREATE TRIGGER trigger_validar_codigo_barras_produto
    BEFORE INSERT OR UPDATE ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION trigger_validar_codigo_barras();

-- 7. View de produtos com código de barras
CREATE OR REPLACE VIEW vw_produtos_com_codigo_barras AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.codigo_barras,
    f.nome as familia_nome,
    p.preco,
    p.estoque,
    p.ativo,
    CASE
        WHEN p.codigo_barras IS NOT NULL THEN 'Sim'
        ELSE 'Não'
    END as tem_codigo_barras
FROM produtos p
LEFT JOIN familias f ON f.id = p.familia_id
WHERE p.ativo = true
ORDER BY p.nome;

-- 8. Comentários
COMMENT ON COLUMN produtos.codigo_barras IS 'Código de barras do produto (EAN-13, EAN-8, UPC-A, UPC-E)';
COMMENT ON FUNCTION buscar_produto_por_codigo_barras IS 'Busca produto por código de barras escaneado';
COMMENT ON FUNCTION validar_codigo_barras IS 'Valida formato de código de barras (EAN/UPC)';

-- 9. Verificação
SELECT 'Coluna codigo_barras adicionada com sucesso!' as status
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'produtos' AND column_name = 'codigo_barras'
);

-- Mostrar produtos sem código de barras
SELECT
    COUNT(*) as total_produtos,
    COUNT(codigo_barras) as com_codigo_barras,
    COUNT(*) - COUNT(codigo_barras) as sem_codigo_barras
FROM produtos
WHERE ativo = true;

COMMIT;
