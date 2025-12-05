-- ====================================
-- ADICIONAR CAMPO ESTOQUE_MINIMO
-- ====================================
-- Esta migration adiciona o campo estoque_minimo na tabela produtos
-- para permitir o controle de stock baixo

-- Adicionar coluna estoque_minimo
ALTER TABLE produtos
ADD COLUMN IF NOT EXISTS estoque_minimo INTEGER DEFAULT 0;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_produtos_estoque_baixo
ON produtos(estoque_minimo) WHERE estoque < estoque_minimo;

-- Comentário na coluna
COMMENT ON COLUMN produtos.estoque_minimo IS 'Quantidade mínima de estoque antes de alertar';
