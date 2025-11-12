-- ===================================
-- FECHAR CAIXA DE TESTE
-- ===================================

\echo '========================================='
\echo '1. VER CAIXA ABERTO'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    data_abertura
FROM caixas
WHERE status = 'ABERTO';

\echo ''
\echo '========================================='
\echo '2. CALCULAR TOTAIS DO CAIXA'
\echo '========================================='

DO $$
DECLARE
    v_caixa_id INTEGER;
BEGIN
    SELECT id INTO v_caixa_id FROM caixas WHERE status = 'ABERTO' LIMIT 1;

    IF v_caixa_id IS NOT NULL THEN
        RAISE NOTICE 'Calculando totais do caixa ID: %', v_caixa_id;
        PERFORM calcular_totais_caixa(v_caixa_id);
        RAISE NOTICE 'Cálculo concluído!';
    ELSE
        RAISE NOTICE 'Nenhum caixa aberto!';
    END IF;
END $$;

\echo ''
\echo '========================================='
\echo '3. VER TOTAIS CALCULADOS'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    -- Vendas
    total_vendas_pagas,
    qtd_vendas_pagas,
    -- Formas de pagamento
    total_cash,
    total_emola,
    total_mpesa,
    total_pos,
    -- Soma das formas (deve bater com total_entradas)
    (total_cash + total_emola + total_mpesa + total_pos) as soma_formas,
    -- Totais
    total_entradas,
    total_saidas,
    saldo_final,
    -- Diferença (deve ser 0 ou próximo de 0)
    ABS((total_cash + total_emola + total_mpesa + total_pos) - total_entradas) as diferenca
FROM caixas
WHERE status = 'ABERTO';

\echo ''
\echo '========================================='
\echo '4. FECHAR O CAIXA'
\echo '========================================='

DO $$
DECLARE
    v_caixa_id INTEGER;
    v_resultado RECORD;
BEGIN
    SELECT id INTO v_caixa_id FROM caixas WHERE status = 'ABERTO' LIMIT 1;

    IF v_caixa_id IS NOT NULL THEN
        RAISE NOTICE 'Fechando caixa ID: %', v_caixa_id;

        FOR v_resultado IN SELECT * FROM fechar_caixa(v_caixa_id, 'Teste de fechamento')
        LOOP
            RAISE NOTICE '=== RESULTADO DO FECHAMENTO ===';
            RAISE NOTICE 'Sucesso: %', v_resultado.sucesso;
            RAISE NOTICE 'Número: %', v_resultado.numero_caixa;
            RAISE NOTICE 'Saldo Final: %', v_resultado.saldo_final_retorno;
            RAISE NOTICE 'Total Entradas: %', v_resultado.total_entradas_retorno;
            RAISE NOTICE 'Total Saídas: %', v_resultado.total_saidas_retorno;
        END LOOP;
    ELSE
        RAISE NOTICE 'Nenhum caixa aberto!';
    END IF;
END $$;

\echo ''
\echo '========================================='
\echo '5. VERIFICAR CAIXA FECHADO'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    data_abertura,
    data_fechamento,
    total_vendas_pagas,
    total_entradas,
    total_saidas,
    saldo_final,
    observacoes
FROM caixas
ORDER BY id DESC
LIMIT 1;

\echo ''
\echo '========================================='
\echo 'TESTE DE FECHAMENTO CONCLUÍDO!'
\echo '========================================='
\echo ''
\echo 'Se apareceu:'
\echo '- Sucesso: t (true)'
\echo '- Número: CXnnnnn...'
\echo '- Saldo Final: [valor]'
\echo ''
\echo 'Então o fechamento funcionou!'
\echo ''
\echo 'Se apareceu NULL em algum valor,'
\echo 'execute o script de investigação:'
\echo '\i ''C:/Users/Frentex/source/posfaturix/database/investigar_inconsistencia.sql'''
