-- ===================================
-- TESTE DIRETO DA FUNÇÃO FECHAR CAIXA
-- ===================================

\echo '========================================='
\echo 'PASSO 1: Ver caixa aberto'
\echo '========================================='

SELECT id, numero, status, saldo_final
FROM caixas
WHERE status = 'ABERTO';

-- ⚠️ ANOTE O ID DO CAIXA ACIMA!

\echo ''
\echo '========================================='
\echo 'PASSO 2: Calcular totais do caixa'
\echo '========================================='

-- ⚠️ SUBSTITUA o número 1 pelo ID do seu caixa
SELECT calcular_totais_caixa(1);

\echo ''
\echo '========================================='
\echo 'PASSO 3: Ver dados APÓS calcular'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    total_vendas_pagas,
    total_cash,
    total_emola,
    total_mpesa,
    total_pos,
    total_entradas,
    total_saidas,
    saldo_final
FROM caixas
WHERE id = 1; -- ⚠️ SUBSTITUA pelo ID do seu caixa

\echo ''
\echo '========================================='
\echo 'PASSO 4: Testar função fechar_caixa'
\echo '========================================='

-- ⚠️ SUBSTITUA o número 1 pelo ID do seu caixa
SELECT * FROM fechar_caixa(1, 'Teste de fechamento');

\echo ''
\echo '========================================='
\echo 'PASSO 5: Ver resultado final'
\echo '========================================='

SELECT
    id,
    numero,
    status,
    saldo_final,
    total_entradas,
    total_saidas,
    data_fechamento
FROM caixas
WHERE id = 1; -- ⚠️ SUBSTITUA pelo ID do seu caixa

\echo ''
\echo '========================================='
\echo 'TESTE CONCLUÍDO!'
\echo '========================================='

-- ===================================
-- SE A FUNÇÃO RETORNOU VALORES NULL:
-- ===================================
-- Isso significa que há um problema na estrutura
-- da tabela ou na função SQL.
--
-- Execute o diagnóstico completo:
-- \i 'C:/Users/Frentex/source/posfaturix/database/diagnostico_completo.sql'
