-- ===================================
-- SCRIPT PARA ADICIONAR MÚLTIPLAS FORMAS DE PAGAMENTO POR VENDA
-- Execute este script no PostgreSQL
-- ===================================

-- ===================================
-- TABELA: pagamentos_venda
-- Armazena cada pagamento de uma venda (múltiplas formas permitidas)
-- ===================================
CREATE TABLE IF NOT EXISTS pagamentos_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER NOT NULL REFERENCES vendas(id) ON DELETE CASCADE,
    forma_pagamento_id INTEGER NOT NULL REFERENCES formas_pagamento(id),
    valor DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pagamentos_venda_valor_positivo CHECK (valor > 0)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_pagamentos_venda_venda_id ON pagamentos_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_pagamentos_venda_forma_pagamento_id ON pagamentos_venda(forma_pagamento_id);

-- ===================================
-- VIEW: Vendas com pagamentos
-- ===================================
CREATE OR REPLACE VIEW v_vendas_com_pagamentos AS
SELECT
    v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    json_agg(
        json_build_object(
            'forma_pagamento', fp.nome,
            'valor', pv.valor
        ) ORDER BY pv.id
    ) FILTER (WHERE pv.id IS NOT NULL) as pagamentos
FROM vendas v
LEFT JOIN pagamentos_venda pv ON v.id = pv.venda_id
LEFT JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
GROUP BY v.id, v.numero, v.total, v.data_venda, v.terminal;

-- ===================================
-- Comentários
-- ===================================
COMMENT ON TABLE pagamentos_venda IS 'Armazena os pagamentos de cada venda (permite múltiplas formas de pagamento)';
COMMENT ON COLUMN pagamentos_venda.venda_id IS 'ID da venda';
COMMENT ON COLUMN pagamentos_venda.forma_pagamento_id IS 'ID da forma de pagamento utilizada';
COMMENT ON COLUMN pagamentos_venda.valor IS 'Valor pago com esta forma de pagamento';

-- ===================================
-- VERIFICAÇÃO
-- ===================================
-- Executar para verificar:
-- SELECT * FROM pagamentos_venda;
-- SELECT * FROM v_vendas_com_pagamentos;
