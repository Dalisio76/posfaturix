-- ===================================
-- VERIFICAR VIEWS EXISTENTES
-- ===================================

-- Ver todas as views relacionadas a caixa
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
AND table_name LIKE '%caixa%'
ORDER BY table_name;

-- ===================================
-- VIEWS QUE DEVERIAM EXISTIR:
-- ===================================
-- 1. v_caixa_atual
-- 2. v_resumo_caixa
-- 3. v_despesas_caixa
-- 4. v_pagamentos_divida_caixa
-- 5. v_produtos_vendidos_caixa
-- 6. v_resumo_produtos_caixa

-- ===================================
-- TESTAR CADA VIEW
-- ===================================

-- Teste 1: v_caixa_atual
SELECT 'v_caixa_atual' as view_name, COUNT(*) as registros
FROM v_caixa_atual;

-- Teste 2: v_resumo_caixa
SELECT 'v_resumo_caixa' as view_name, COUNT(*) as registros
FROM v_resumo_caixa;

-- Teste 3: v_despesas_caixa (PODE FALHAR SE NÃO EXISTIR)
-- SELECT 'v_despesas_caixa' as view_name, COUNT(*) as registros
-- FROM v_despesas_caixa;

-- Teste 4: v_pagamentos_divida_caixa (PODE FALHAR SE NÃO EXISTIR)
-- SELECT 'v_pagamentos_divida_caixa' as view_name, COUNT(*) as registros
-- FROM v_pagamentos_divida_caixa;

-- Teste 5: v_produtos_vendidos_caixa (PODE FALHAR SE NÃO EXISTIR)
-- SELECT 'v_produtos_vendidos_caixa' as view_name, COUNT(*) as registros
-- FROM v_produtos_vendidos_caixa;

-- Teste 6: v_resumo_produtos_caixa (PODE FALHAR SE NÃO EXISTIR)
-- SELECT 'v_resumo_produtos_caixa' as view_name, COUNT(*) as registros
-- FROM v_resumo_produtos_caixa;
