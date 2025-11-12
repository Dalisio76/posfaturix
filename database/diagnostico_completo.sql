-- ===================================
-- DIAGNÓSTICO COMPLETO DO FECHO DE CAIXA
-- ===================================

\echo '========================================='
\echo '1. VERIFICAR TABELA CAIXAS'
\echo '========================================='

-- Ver se a tabela existe
SELECT 'Tabela caixas existe' as status
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name = 'caixas';

-- Ver estrutura da tabela
\d caixas

-- Ver registros na tabela
SELECT
    id,
    numero,
    status,
    data_abertura,
    data_fechamento,
    total_vendas_pagas,
    total_cash,
    total_emola,
    total_mpesa,
    total_pos,
    total_entradas,
    total_saidas,
    saldo_final
FROM caixas
ORDER BY id DESC
LIMIT 5;

\echo ''
\echo '========================================='
\echo '2. VERIFICAR FUNCTIONS'
\echo '========================================='

-- Ver se as funções existem
SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%caixa%'
ORDER BY routine_name;

\echo ''
\echo '========================================='
\echo '3. VERIFICAR VIEWS'
\echo '========================================='

-- Ver views existentes
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
AND table_name LIKE '%caixa%'
ORDER BY table_name;

\echo ''
\echo '========================================='
\echo '4. TESTAR CAIXA ABERTO'
\echo '========================================='

-- Ver se há caixa aberto
SELECT
    id,
    numero,
    status,
    data_abertura,
    total_vendas_pagas,
    total_cash,
    total_entradas,
    saldo_final
FROM caixas
WHERE status = 'ABERTO';

\echo ''
\echo '========================================='
\echo '5. BUSCAR ÚLTIMO CAIXA'
\echo '========================================='

-- Ver último caixa (aberto ou fechado)
SELECT
    id,
    numero,
    status,
    total_vendas_pagas,
    total_entradas,
    total_saidas,
    saldo_final
FROM caixas
ORDER BY id DESC
LIMIT 1;

\echo ''
\echo '========================================='
\echo '6. TESTAR FUNÇÃO calcular_totais_caixa'
\echo '========================================='

-- Pegar ID do último caixa
DO $$
DECLARE
    v_caixa_id INTEGER;
BEGIN
    SELECT id INTO v_caixa_id
    FROM caixas
    ORDER BY id DESC
    LIMIT 1;

    IF v_caixa_id IS NOT NULL THEN
        RAISE NOTICE 'Calculando totais para caixa ID: %', v_caixa_id;
        PERFORM calcular_totais_caixa(v_caixa_id);
        RAISE NOTICE 'Cálculo concluído!';
    ELSE
        RAISE NOTICE 'Nenhum caixa encontrado!';
    END IF;
END $$;

\echo ''
\echo '========================================='
\echo '7. VER RESULTADO APÓS CALCULAR'
\echo '========================================='

-- Ver dados após calcular
SELECT
    id,
    numero,
    status,
    total_vendas_pagas,
    qtd_vendas_pagas,
    total_cash,
    total_emola,
    total_mpesa,
    total_pos,
    total_entradas,
    total_saidas,
    saldo_final
FROM caixas
ORDER BY id DESC
LIMIT 1;

\echo ''
\echo '========================================='
\echo '8. VERIFICAR VENDAS NO PERÍODO'
\echo '========================================='

-- Ver se há vendas
SELECT
    COUNT(*) as total_vendas,
    COALESCE(SUM(total), 0) as soma_total,
    MIN(data_venda) as primeira_venda,
    MAX(data_venda) as ultima_venda
FROM vendas
WHERE data_venda >= (SELECT data_abertura FROM caixas ORDER BY id DESC LIMIT 1);

\echo ''
\echo '========================================='
\echo '9. VERIFICAR PAGAMENTOS DE VENDAS'
\echo '========================================='

-- Ver pagamentos das vendas
SELECT
    fp.nome as forma_pagamento,
    COUNT(*) as qtd_pagamentos,
    COALESCE(SUM(pv.valor), 0) as total_pago
FROM pagamentos_venda pv
INNER JOIN vendas v ON pv.venda_id = v.id
INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
WHERE v.data_venda >= (SELECT data_abertura FROM caixas ORDER BY id DESC LIMIT 1)
GROUP BY fp.nome
ORDER BY fp.nome;

\echo ''
\echo '========================================='
\echo '10. DIAGNÓSTICO FINAL'
\echo '========================================='

-- Resumo diagnóstico
SELECT
    'DIAGNÓSTICO' as tipo,
    CASE
        WHEN EXISTS (SELECT 1 FROM caixas) THEN 'OK'
        ELSE 'ERRO: Tabela vazia'
    END as tabela_caixas,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'abrir_caixa') THEN 'OK'
        ELSE 'ERRO: Função não existe'
    END as funcao_abrir,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'calcular_totais_caixa') THEN 'OK'
        ELSE 'ERRO: Função não existe'
    END as funcao_calcular,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'fechar_caixa') THEN 'OK'
        ELSE 'ERRO: Função não existe'
    END as funcao_fechar;

\echo ''
\echo '========================================='
\echo 'DIAGNÓSTICO COMPLETO CONCLUÍDO!'
\echo '========================================='
