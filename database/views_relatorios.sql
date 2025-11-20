-- ===================================
-- VIEWS PARA SISTEMA DE RELATÓRIOS
-- Execute este arquivo no PostgreSQL para criar/atualizar as views
-- ===================================

-- ===================================
-- VIEW: Resumo Completo do Caixa
-- ===================================
DROP VIEW IF EXISTS v_resumo_caixa CASCADE;
CREATE OR REPLACE VIEW v_resumo_caixa AS
SELECT
    c.id,
    c.numero,
    c.terminal,
    c.usuario,
    c.status,
    c.data_abertura,
    c.data_fechamento,

    -- VENDAS PAGAS
    c.total_vendas_pagas,
    c.qtd_vendas_pagas,

    -- VENDAS A CRÉDITO (não entra no saldo)
    c.total_vendas_credito,
    c.qtd_vendas_credito,

    -- POR FORMA DE PAGAMENTO
    c.total_cash,
    c.qtd_transacoes_cash,
    c.total_emola,
    c.qtd_transacoes_emola,
    c.total_mpesa,
    c.qtd_transacoes_mpesa,
    c.total_pos,
    c.qtd_transacoes_pos,

    -- PAGAMENTOS DE DÍVIDAS
    c.total_dividas_pagas,
    c.qtd_dividas_pagas,

    -- DESPESAS
    c.total_despesas,
    c.qtd_despesas,

    -- TOTAIS FINAIS
    c.total_entradas,
    c.total_saidas,
    c.saldo_final,

    -- VALIDAÇÃO
    (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) as soma_formas_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN 'OK'
        ELSE 'ERRO'
    END as status_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN TRUE
        ELSE FALSE
    END as totais_corretos,

    c.observacoes,
    c.created_at
FROM caixas c
ORDER BY c.data_abertura DESC;

COMMENT ON VIEW v_resumo_caixa IS 'Resumo completo de todos os caixas com validação';

-- ===================================
-- VIEW: Detalhes de Despesas do Caixa (ATUALIZADA COM CATEGORIA)
-- ===================================
DROP VIEW IF EXISTS v_despesas_caixa CASCADE;
CREATE OR REPLACE VIEW v_despesas_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    d.id as despesa_id,
    d.descricao,
    d.valor,
    d.categoria,
    d.data_despesa,
    d.observacoes,
    d.usuario
FROM caixas c
CROSS JOIN despesas d
WHERE d.data_despesa >= c.data_abertura
  AND d.data_despesa <= COALESCE(c.data_fechamento, NOW())
ORDER BY d.data_despesa DESC;

COMMENT ON VIEW v_despesas_caixa IS 'Lista detalhada de despesas por caixa com categoria';

-- ===================================
-- VIEW: Detalhes de Pagamentos de Dívidas do Caixa
-- ===================================
DROP VIEW IF EXISTS v_pagamentos_divida_caixa CASCADE;
CREATE OR REPLACE VIEW v_pagamentos_divida_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    pd.id as pagamento_id,
    pd.divida_id,
    pd.valor,
    pd.data_pagamento,
    pd.observacoes,
    fp.nome as forma_pagamento,
    cli.nome as cliente_nome,
    cli.contacto as cliente_contacto,
    d.valor_total as divida_total,
    d.valor_pago as divida_pago,
    d.valor_restante as divida_restante
FROM caixas c
CROSS JOIN pagamentos_divida pd
INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
INNER JOIN dividas d ON pd.divida_id = d.id
INNER JOIN clientes cli ON d.cliente_id = cli.id
WHERE pd.data_pagamento >= c.data_abertura
  AND pd.data_pagamento <= COALESCE(c.data_fechamento, NOW())
ORDER BY pd.data_pagamento DESC;

COMMENT ON VIEW v_pagamentos_divida_caixa IS 'Lista detalhada de pagamentos de dívidas por caixa com dados do cliente';

-- ===================================
-- VIEW: Produtos Vendidos no Caixa
-- ===================================
DROP VIEW IF EXISTS v_produtos_vendidos_caixa CASCADE;
CREATE OR REPLACE VIEW v_produtos_vendidos_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    v.id as venda_id,
    v.numero as venda_numero,
    v.data_venda,
    v.total as venda_total,
    p.id as produto_id,
    p.nome as produto_nome,
    iv.quantidade,
    iv.preco_unitario,
    iv.subtotal,
    (iv.quantidade * iv.preco_unitario) as total_vendido
FROM caixas c
CROSS JOIN vendas v
INNER JOIN itens_venda iv ON v.id = iv.venda_id
INNER JOIN produtos p ON iv.produto_id = p.id
WHERE v.data_venda >= c.data_abertura
  AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
ORDER BY v.data_venda DESC, p.nome;

COMMENT ON VIEW v_produtos_vendidos_caixa IS 'Lista detalhada de produtos vendidos por caixa';

-- ===================================
-- VIEW: Resumo de Produtos Vendidos (Agregado)
-- ===================================
DROP VIEW IF EXISTS v_resumo_produtos_caixa CASCADE;
CREATE OR REPLACE VIEW v_resumo_produtos_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    p.id as produto_id,
    p.nome as produto_nome,
    SUM(iv.quantidade) as quantidade_total,
    iv.preco_unitario,
    SUM(iv.subtotal) as total_vendido
FROM caixas c
CROSS JOIN vendas v
INNER JOIN itens_venda iv ON v.id = iv.venda_id
INNER JOIN produtos p ON iv.produto_id = p.id
WHERE v.data_venda >= c.data_abertura
  AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
GROUP BY c.id, c.numero, p.id, p.nome, iv.preco_unitario
ORDER BY total_vendido DESC;

COMMENT ON VIEW v_resumo_produtos_caixa IS 'Resumo agregado de produtos vendidos por caixa';

-- ===================================
-- VIEW: Caixa Atual (Aberto)
-- ===================================
DROP VIEW IF EXISTS v_caixa_atual CASCADE;
CREATE OR REPLACE VIEW v_caixa_atual AS
SELECT
    c.*,
    (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) as soma_formas_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN 'OK'
        ELSE 'ERRO: Totais não batem!'
    END as status_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN TRUE
        ELSE FALSE
    END as totais_corretos
FROM caixas c
WHERE c.status = 'ABERTO'
ORDER BY c.data_abertura DESC
LIMIT 1;

COMMENT ON VIEW v_caixa_atual IS 'Retorna o caixa atualmente aberto com validação de totais';

-- ===================================
-- VERIFICAÇÃO FINAL
-- ===================================
SELECT
    'v_resumo_caixa' as view_name,
    COUNT(*) as total_registros
FROM v_resumo_caixa

UNION ALL

SELECT
    'v_despesas_caixa' as view_name,
    COUNT(*) as total_registros
FROM v_despesas_caixa

UNION ALL

SELECT
    'v_produtos_vendidos_caixa' as view_name,
    COUNT(*) as total_registros
FROM v_produtos_vendidos_caixa

UNION ALL

SELECT
    'v_resumo_produtos_caixa' as view_name,
    COUNT(*) as total_registros
FROM v_resumo_produtos_caixa

UNION ALL

SELECT
    'v_caixa_atual' as view_name,
    COUNT(*) as total_registros
FROM v_caixa_atual;
