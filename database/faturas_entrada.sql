-- ===================================
-- TABELAS: Faturas de Entrada (Compras)
-- Sistema de registro de compras de fornecedores
-- ===================================

-- ===================================
-- 1. CRIAR TABELA FATURAS_ENTRADA
-- ===================================
CREATE TABLE IF NOT EXISTS faturas_entrada (
    id SERIAL PRIMARY KEY,
    fornecedor_id INTEGER NOT NULL REFERENCES fornecedores(id) ON DELETE RESTRICT,
    numero_fatura VARCHAR(50) NOT NULL,
    data_fatura DATE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    observacoes TEXT,
    usuario VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fornecedor_id, numero_fatura)
);

-- ===================================
-- 2. CRIAR TABELA ITENS_FATURA_ENTRADA
-- ===================================
CREATE TABLE IF NOT EXISTS itens_fatura_entrada (
    id SERIAL PRIMARY KEY,
    fatura_id INTEGER NOT NULL REFERENCES faturas_entrada(id) ON DELETE CASCADE,
    produto_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE RESTRICT,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 3. ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_faturas_entrada_fornecedor ON faturas_entrada(fornecedor_id);
CREATE INDEX IF NOT EXISTS idx_faturas_entrada_data ON faturas_entrada(data_fatura);
CREATE INDEX IF NOT EXISTS idx_faturas_entrada_numero ON faturas_entrada(numero_fatura);
CREATE INDEX IF NOT EXISTS idx_itens_fatura_entrada_fatura ON itens_fatura_entrada(fatura_id);
CREATE INDEX IF NOT EXISTS idx_itens_fatura_entrada_produto ON itens_fatura_entrada(produto_id);

-- ===================================
-- 4. VIEWS ÚTEIS
-- ===================================

-- View: Faturas com informações do fornecedor
CREATE OR REPLACE VIEW v_faturas_entrada_completo AS
SELECT
    f.id,
    f.fornecedor_id,
    fo.nome as fornecedor_nome,
    fo.nif as fornecedor_nif,
    f.numero_fatura,
    f.data_fatura,
    f.total,
    f.observacoes,
    f.usuario,
    f.created_at,
    f.updated_at,
    -- Contagem de itens
    (SELECT COUNT(*) FROM itens_fatura_entrada WHERE fatura_id = f.id) as total_itens
FROM faturas_entrada f
INNER JOIN fornecedores fo ON f.fornecedor_id = fo.id
ORDER BY f.data_fatura DESC, f.created_at DESC;

-- View: Itens de fatura com informações do produto
CREATE OR REPLACE VIEW v_itens_fatura_entrada_completo AS
SELECT
    i.id,
    i.fatura_id,
    i.produto_id,
    p.codigo as produto_codigo,
    p.nome as produto_nome,
    i.quantidade,
    i.preco_unitario,
    i.subtotal,
    f.numero_fatura,
    f.data_fatura,
    fo.nome as fornecedor_nome
FROM itens_fatura_entrada i
INNER JOIN produtos p ON i.produto_id = p.id
INNER JOIN faturas_entrada f ON i.fatura_id = f.id
INNER JOIN fornecedores fo ON f.fornecedor_id = fo.id;

-- View: Resumo de compras por fornecedor
CREATE OR REPLACE VIEW v_resumo_compras_fornecedor AS
SELECT
    fo.id as fornecedor_id,
    fo.nome as fornecedor_nome,
    COUNT(DISTINCT f.id) as total_faturas,
    SUM(f.total) as total_comprado,
    AVG(f.total) as media_por_fatura,
    MIN(f.data_fatura) as primeira_compra,
    MAX(f.data_fatura) as ultima_compra
FROM fornecedores fo
LEFT JOIN faturas_entrada f ON fo.id = f.fornecedor_id
WHERE fo.ativo = true
GROUP BY fo.id, fo.nome
ORDER BY total_comprado DESC NULLS LAST;

-- View: Produtos mais comprados
CREATE OR REPLACE VIEW v_produtos_mais_comprados AS
SELECT
    p.id as produto_id,
    p.codigo as produto_codigo,
    p.nome as produto_nome,
    COUNT(DISTINCT i.fatura_id) as total_faturas,
    SUM(i.quantidade) as quantidade_total_comprada,
    AVG(i.preco_unitario) as preco_medio_compra,
    SUM(i.subtotal) as total_gasto
FROM produtos p
LEFT JOIN itens_fatura_entrada i ON p.id = i.produto_id
WHERE p.ativo = true
GROUP BY p.id, p.codigo, p.nome
HAVING SUM(i.quantidade) > 0
ORDER BY quantidade_total_comprada DESC;

-- ===================================
-- 5. COMENTÁRIOS
-- ===================================
COMMENT ON TABLE faturas_entrada IS 'Registro de faturas de compra de fornecedores';
COMMENT ON TABLE itens_fatura_entrada IS 'Itens de cada fatura de compra';
COMMENT ON COLUMN faturas_entrada.fornecedor_id IS 'Fornecedor da fatura';
COMMENT ON COLUMN faturas_entrada.numero_fatura IS 'Número da fatura do fornecedor';
COMMENT ON COLUMN faturas_entrada.data_fatura IS 'Data de emissão da fatura';
COMMENT ON COLUMN faturas_entrada.total IS 'Valor total da fatura';
COMMENT ON COLUMN itens_fatura_entrada.quantidade IS 'Quantidade comprada';
COMMENT ON COLUMN itens_fatura_entrada.preco_unitario IS 'Preço de compra unitário';
COMMENT ON COLUMN itens_fatura_entrada.subtotal IS 'Subtotal do item (quantidade × preço)';

-- ===================================
-- 6. VERIFICAÇÃO
-- ===================================

-- Ver estrutura das tabelas
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('faturas_entrada', 'itens_fatura_entrada')
ORDER BY table_name, ordinal_position;

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. A constraint UNIQUE(fornecedor_id, numero_fatura) evita faturas duplicadas
-- 2. O DELETE CASCADE em itens_fatura_entrada remove automaticamente os itens ao deletar uma fatura
-- 3. O DELETE RESTRICT em fornecedor_id e produto_id impede deletar se houver faturas
-- 4. Os CHECK constraints garantem valores positivos
-- 5. As views facilitam consultas complexas
-- 6. Ao inserir uma fatura, o estoque dos produtos deve ser atualizado (feito na aplicação)
--
-- Para rollback:
-- DROP TABLE itens_fatura_entrada CASCADE;
-- DROP TABLE faturas_entrada CASCADE;
-- ===================================
