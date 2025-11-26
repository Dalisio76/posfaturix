-- ===================================
-- SISTEMA DE CANCELAMENTO DE ITENS
-- Descrição: Log de cancelamentos de itens de pedidos com justificativa
-- Data: 2025
-- ===================================

-- ===================================
-- TABELA: cancelamentos_item_pedido
-- ===================================
CREATE TABLE IF NOT EXISTS cancelamentos_item_pedido (
    id SERIAL PRIMARY KEY,
    item_pedido_id INTEGER NOT NULL REFERENCES itens_pedido(id) ON DELETE CASCADE,
    pedido_id INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_id INTEGER NOT NULL,
    produto_nome VARCHAR(200) NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
    usuario_nome VARCHAR(200),
    justificativa TEXT NOT NULL,
    data_cancelamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- ÍNDICES
-- ===================================
CREATE INDEX IF NOT EXISTS idx_cancelamentos_pedido ON cancelamentos_item_pedido(pedido_id);
CREATE INDEX IF NOT EXISTS idx_cancelamentos_usuario ON cancelamentos_item_pedido(usuario_id);
CREATE INDEX IF NOT EXISTS idx_cancelamentos_data ON cancelamentos_item_pedido(data_cancelamento);

-- ===================================
-- VIEW: Cancelamentos com detalhes
-- ===================================
CREATE OR REPLACE VIEW v_cancelamentos_pedido AS
SELECT
    c.id,
    c.pedido_id,
    p.numero as pedido_numero,
    p.mesa_id,
    m.numero as mesa_numero,
    c.produto_nome,
    c.quantidade,
    c.preco_unitario,
    c.subtotal,
    c.usuario_nome,
    c.justificativa,
    c.data_cancelamento
FROM cancelamentos_item_pedido c
INNER JOIN pedidos p ON c.pedido_id = p.id
INNER JOIN mesas m ON p.mesa_id = m.id
ORDER BY c.data_cancelamento DESC;

-- ===================================
-- COMENTÁRIOS
-- ===================================
COMMENT ON TABLE cancelamentos_item_pedido IS 'Log de itens cancelados de pedidos com justificativa';
COMMENT ON COLUMN cancelamentos_item_pedido.justificativa IS 'Motivo do cancelamento do item';

-- ===================================
-- FIM DO SCRIPT
-- ===================================
