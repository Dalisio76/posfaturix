-- =============================================
-- SIMPLIFICAÇÃO DA NUMERAÇÃO DE VENDAS
-- Muda de: VD1733317895234 para: 1, 2, 3...
-- =============================================

-- 1. Adicionar coluna numero_venda (numérico) se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vendas' AND column_name = 'numero_venda'
    ) THEN
        ALTER TABLE vendas ADD COLUMN numero_venda INTEGER;
    END IF;
END $$;

-- 2. Criar índice único na coluna numero_venda
DROP INDEX IF EXISTS idx_vendas_numero_venda;
CREATE UNIQUE INDEX idx_vendas_numero_venda ON vendas(numero_venda) WHERE numero_venda IS NOT NULL;

-- 3. Atualizar vendas existentes com numeração sequencial
-- (Apenas se houver vendas sem numero_venda)
WITH vendas_numeradas AS (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) as novo_numero
    FROM vendas
    WHERE numero_venda IS NULL
)
UPDATE vendas v
SET numero_venda = vn.novo_numero
FROM vendas_numeradas vn
WHERE v.id = vn.id;

-- 4. Criar função para obter próximo número de venda
CREATE OR REPLACE FUNCTION obter_proximo_numero_venda()
RETURNS INTEGER AS $$
DECLARE
    proximo_numero INTEGER;
BEGIN
    SELECT COALESCE(MAX(numero_venda), 0) + 1
    INTO proximo_numero
    FROM vendas;

    RETURN proximo_numero;
END;
$$ LANGUAGE plpgsql;

-- 5. Comentários explicativos
COMMENT ON COLUMN vendas.numero_venda IS 'Número sequencial simples da venda (1, 2, 3...)';
COMMENT ON COLUMN vendas.numero IS 'Número legado/técnico da venda (mantido para compatibilidade)';
COMMENT ON FUNCTION obter_proximo_numero_venda() IS 'Retorna o próximo número sequencial disponível para uma venda';

-- Verificar resultado
SELECT
    'Total de vendas:' as info,
    COUNT(*) as total,
    MIN(numero_venda) as primeiro,
    MAX(numero_venda) as ultimo
FROM vendas;

-- Exibir exemplos
SELECT
    id,
    numero as numero_antigo,
    numero_venda as numero_novo,
    total,
    data_venda
FROM vendas
ORDER BY id DESC
LIMIT 5;
