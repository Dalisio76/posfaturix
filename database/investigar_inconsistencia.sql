-- ===================================
-- INVESTIGAR INCONSISTÊNCIA NOS TOTAIS
-- ===================================
-- Problema: Soma das formas (1279) != Total de entradas (1019)
-- Diferença: 260 MT

\echo '========================================='
\echo '1. VER DADOS DO CAIXA FECHADO'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    data_abertura,
    data_fechamento,
    -- Vendas pagas
    total_vendas_pagas,
    qtd_vendas_pagas,
    -- Formas de pagamento
    total_cash,
    qtd_transacoes_cash,
    total_emola,
    qtd_transacoes_emola,
    total_mpesa,
    qtd_transacoes_mpesa,
    total_pos,
    qtd_transacoes_pos,
    -- Pagamentos de dívidas
    total_dividas_pagas,
    qtd_dividas_pagas,
    -- Totais
    total_entradas,
    total_saidas,
    saldo_final,
    -- Validação
    (total_cash + total_emola + total_mpesa + total_pos) as soma_formas_calculada,
    (total_cash + total_emola + total_mpesa + total_pos) - total_entradas as diferenca
FROM caixas
WHERE numero = 'CX20251112-063434';

\echo ''
\echo '========================================='
\echo '2. VERIFICAR VENDAS NO PERÍODO'
\echo '========================================='

-- Vendas pagas (tipo_venda = NORMAL ou NULL)
SELECT
    'VENDAS PAGAS' as tipo,
    COUNT(*) as quantidade,
    SUM(v.total) as soma_total
FROM vendas v
WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)

UNION ALL

-- Vendas a crédito (tipo_venda = DIVIDA)
SELECT
    'VENDAS CRÉDITO' as tipo,
    COUNT(*) as quantidade,
    SUM(v.total) as soma_total
FROM vendas v
WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
  AND v.tipo_venda = 'DIVIDA';

\echo ''
\echo '========================================='
\echo '3. VERIFICAR PAGAMENTOS DE VENDAS'
\echo '========================================='

-- Pagamentos de vendas PAGAS (tipo_venda = NORMAL ou NULL)
SELECT
    fp.nome as forma_pagamento,
    COUNT(pv.id) as qtd_pagamentos,
    SUM(pv.valor) as total_pago,
    COUNT(DISTINCT pv.venda_id) as qtd_vendas_distintas
FROM pagamentos_venda pv
INNER JOIN vendas v ON pv.venda_id = v.id
INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
GROUP BY fp.nome
ORDER BY fp.nome;

\echo ''
\echo '========================================='
\echo '4. SOMA TOTAL DOS PAGAMENTOS DE VENDAS'
\echo '========================================='

SELECT
    'PAGAMENTOS DE VENDAS' as tipo,
    COUNT(*) as qtd_pagamentos,
    SUM(pv.valor) as soma_pagamentos
FROM pagamentos_venda pv
INNER JOIN vendas v ON pv.venda_id = v.id
WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL);

\echo ''
\echo '========================================='
\echo '5. VERIFICAR PAGAMENTOS DE DÍVIDAS'
\echo '========================================='

-- Pagamentos de dívidas por forma
SELECT
    fp.nome as forma_pagamento,
    COUNT(*) as qtd_pagamentos,
    SUM(pd.valor) as total_pago
FROM pagamentos_divida pd
INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
WHERE pd.data_pagamento >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND pd.data_pagamento <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
GROUP BY fp.nome
ORDER BY fp.nome;

\echo ''
\echo '========================================='
\echo '6. SOMA TOTAL DOS PAGAMENTOS DE DÍVIDAS'
\echo '========================================='

SELECT
    'PAGAMENTOS DE DÍVIDAS' as tipo,
    COUNT(*) as qtd_pagamentos,
    SUM(pd.valor) as soma_pagamentos
FROM pagamentos_divida pd
WHERE pd.data_pagamento >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND pd.data_pagamento <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434');

\echo ''
\echo '========================================='
\echo '7. ANÁLISE DETALHADA POR FORMA'
\echo '========================================='

-- CASH: Vendas + Dívidas
SELECT
    'CASH' as forma,
    'Pagamentos de Vendas' as origem,
    COUNT(*) as qtd,
    SUM(pv.valor) as total
FROM pagamentos_venda pv
INNER JOIN vendas v ON pv.venda_id = v.id
INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
  AND UPPER(fp.nome) = 'CASH'
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)

UNION ALL

SELECT
    'CASH' as forma,
    'Pagamentos de Dívidas' as origem,
    COUNT(*) as qtd,
    SUM(pd.valor) as total
FROM pagamentos_divida pd
INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
WHERE pd.data_pagamento >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
  AND pd.data_pagamento <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
  AND UPPER(fp.nome) = 'CASH'

UNION ALL

SELECT
    'CASH' as forma,
    'TOTAL (deve bater com caixa.total_cash)' as origem,
    NULL as qtd,
    SUM(valor) as total
FROM (
    SELECT pv.valor
    FROM pagamentos_venda pv
    INNER JOIN vendas v ON pv.venda_id = v.id
    INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
    WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
      AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
      AND UPPER(fp.nome) = 'CASH'
      AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)

    UNION ALL

    SELECT pd.valor
    FROM pagamentos_divida pd
    INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
    WHERE pd.data_pagamento >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
      AND pd.data_pagamento <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
      AND UPPER(fp.nome) = 'CASH'
) AS todos_cash;

\echo ''
\echo '========================================='
\echo '8. COMPARAÇÃO FINAL'
\echo '========================================='

WITH dados_calculados AS (
    -- Pagamentos de vendas por forma
    SELECT
        UPPER(fp.nome) as forma,
        SUM(pv.valor) as valor_vendas
    FROM pagamentos_venda pv
    INNER JOIN vendas v ON pv.venda_id = v.id
    INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
    WHERE v.data_venda >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
      AND v.data_venda <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
      AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
    GROUP BY UPPER(fp.nome)
),
dividas_calculadas AS (
    -- Pagamentos de dívidas por forma
    SELECT
        UPPER(fp.nome) as forma,
        SUM(pd.valor) as valor_dividas
    FROM pagamentos_divida pd
    INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
    WHERE pd.data_pagamento >= (SELECT data_abertura FROM caixas WHERE numero = 'CX20251112-063434')
      AND pd.data_pagamento <= (SELECT data_fechamento FROM caixas WHERE numero = 'CX20251112-063434')
    GROUP BY UPPER(fp.nome)
)
SELECT
    COALESCE(d.forma, div.forma) as forma_pagamento,
    COALESCE(d.valor_vendas, 0) as valor_vendas,
    COALESCE(div.valor_dividas, 0) as valor_dividas,
    COALESCE(d.valor_vendas, 0) + COALESCE(div.valor_dividas, 0) as total_calculado,
    CASE
        WHEN COALESCE(d.forma, div.forma) = 'CASH' THEN (SELECT total_cash FROM caixas WHERE numero = 'CX20251112-063434')
        WHEN COALESCE(d.forma, div.forma) = 'EMOLA' THEN (SELECT total_emola FROM caixas WHERE numero = 'CX20251112-063434')
        WHEN COALESCE(d.forma, div.forma) = 'MPESA' THEN (SELECT total_mpesa FROM caixas WHERE numero = 'CX20251112-063434')
        WHEN COALESCE(d.forma, div.forma) = 'POS' THEN (SELECT total_pos FROM caixas WHERE numero = 'CX20251112-063434')
    END as valor_no_caixa,
    CASE
        WHEN COALESCE(d.forma, div.forma) = 'CASH' THEN
            (COALESCE(d.valor_vendas, 0) + COALESCE(div.valor_dividas, 0)) - (SELECT total_cash FROM caixas WHERE numero = 'CX20251112-063434')
        WHEN COALESCE(d.forma, div.forma) = 'EMOLA' THEN
            (COALESCE(d.valor_vendas, 0) + COALESCE(div.valor_dividas, 0)) - (SELECT total_emola FROM caixas WHERE numero = 'CX20251112-063434')
        WHEN COALESCE(d.forma, div.forma) = 'MPESA' THEN
            (COALESCE(d.valor_vendas, 0) + COALESCE(div.valor_dividas, 0)) - (SELECT total_mpesa FROM caixas WHERE numero = 'CX20251112-063434')
        WHEN COALESCE(d.forma, div.forma) = 'POS' THEN
            (COALESCE(d.valor_vendas, 0) + COALESCE(div.valor_dividas, 0)) - (SELECT total_pos FROM caixas WHERE numero = 'CX20251112-063434')
    END as diferenca
FROM dados_calculados d
FULL OUTER JOIN dividas_calculadas div ON d.forma = div.forma
ORDER BY forma_pagamento;

\echo ''
\echo '========================================='
\echo 'INVESTIGAÇÃO CONCLUÍDA!'
\echo '========================================='
\echo 'Analise os valores acima para identificar'
\echo 'onde está a diferença de 260 MT'
\echo '========================================='
