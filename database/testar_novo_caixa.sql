-- ===================================
-- TESTAR ABERTURA E FECHAMENTO DE NOVO CAIXA
-- ===================================

\echo '========================================='
\echo '1. VERIFICAR CAIXAS EXISTENTES'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    data_abertura,
    data_fechamento
FROM caixas
ORDER BY id DESC
LIMIT 5;

\echo ''
\echo '========================================='
\echo '2. FECHAR CAIXA ABERTO (se houver)'
\echo '========================================='

-- Verificar se há caixa aberto
DO $$
DECLARE
    v_caixa_id INTEGER;
    v_numero VARCHAR(50);
BEGIN
    SELECT id, numero INTO v_caixa_id, v_numero
    FROM caixas
    WHERE status = 'ABERTO'
    LIMIT 1;

    IF v_caixa_id IS NOT NULL THEN
        RAISE NOTICE 'Fechando caixa aberto: % (ID: %)', v_numero, v_caixa_id;
        PERFORM calcular_totais_caixa(v_caixa_id);
        UPDATE caixas SET status = 'FECHADO', data_fechamento = NOW() WHERE id = v_caixa_id;
        RAISE NOTICE 'Caixa fechado manualmente!';
    ELSE
        RAISE NOTICE 'Nenhum caixa aberto encontrado.';
    END IF;
END $$;

\echo ''
\echo '========================================='
\echo '3. ABRIR NOVO CAIXA'
\echo '========================================='

SELECT abrir_caixa('TERMINAL-01', 'Teste') as novo_caixa_id;

\echo ''
\echo '========================================='
\echo '4. VERIFICAR NOVO CAIXA'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    data_abertura,
    total_vendas_pagas,
    total_entradas,
    saldo_final
FROM caixas
WHERE status = 'ABERTO';

\echo ''
\echo '========================================='
\echo '5. FAZER ALGUMAS VENDAS DE TESTE (OPCIONAL)'
\echo '========================================='

\echo 'Agora você pode:'
\echo '1. Ir no aplicativo Flutter e fazer algumas vendas'
\echo '2. OU executar INSERT direto aqui no SQL para simular vendas'
\echo ''
\echo 'Depois de fazer vendas, volte e execute o script:'
\echo '\i ''C:/Users/Frentex/source/posfaturix/database/fechar_caixa_teste.sql'''

\echo ''
\echo '========================================='
\echo 'CAIXA ABERTO E PRONTO PARA TESTES!'
\echo '========================================='
