-- =====================================================
-- SCRIPT: Limpar todas as operações do sistema
-- Data: 2025-12-09
-- =====================================================
-- Remove TODOS os registros operacionais
-- MANTÉM: produtos, famílias, setores, áreas, mesas,
--         usuários, impressoras, clientes, fornecedores
-- =====================================================

-- Desabilitar triggers temporariamente
SET session_replication_role = 'replica';

-- =====================================================
-- 1. LIMPAR VENDAS E RELACIONADOS
-- =====================================================
DELETE FROM public.itens_venda;
DELETE FROM public.pagamentos_venda;
DELETE FROM public.vendas;

-- =====================================================
-- 2. LIMPAR PEDIDOS
-- =====================================================
DELETE FROM public.cancelamentos_item_pedido;
DELETE FROM public.itens_pedido;
DELETE FROM public.pedidos;

-- =====================================================
-- 3. LIMPAR DÍVIDAS
-- =====================================================
DELETE FROM public.pagamentos_divida;
DELETE FROM public.dividas;

-- =====================================================
-- 4. LIMPAR CAIXA
-- =====================================================
DELETE FROM public.conferencias_caixa;
DELETE FROM public.controle_fecho_caixa;
DELETE FROM public.caixas;

-- =====================================================
-- 5. LIMPAR DESPESAS
-- =====================================================
DELETE FROM public.despesas;

-- =====================================================
-- 6. LIMPAR MOVIMENTAÇÕES DE STOCK
-- =====================================================
DELETE FROM public.acertos_stock;

-- =====================================================
-- 7. LIMPAR FATURAS DE ENTRADA (COMPRAS)
-- =====================================================
DELETE FROM public.itens_fatura_entrada;
DELETE FROM public.faturas_entrada;

-- =====================================================
-- 8. LIMPAR AUDITORIA E LOGS
-- =====================================================
DELETE FROM public.auditoria;
DELETE FROM public.logs_acesso;
DELETE FROM public.terminal_logs;

-- =====================================================
-- 9. RESETAR ESTOQUE DOS PRODUTOS PARA ZERO
-- =====================================================
UPDATE public.produtos SET estoque = 0;

-- =====================================================
-- 10. RESETAR SEQUÊNCIAS
-- =====================================================
ALTER SEQUENCE IF EXISTS public.vendas_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.itens_venda_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.pagamentos_venda_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.pedidos_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.itens_pedido_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.dividas_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.pagamentos_divida_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.caixas_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.conferencias_caixa_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.despesas_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.acertos_stock_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.faturas_entrada_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.itens_fatura_entrada_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.auditoria_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.cancelamentos_item_pedido_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.controle_fecho_caixa_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.logs_acesso_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS public.terminal_logs_id_seq RESTART WITH 1;

-- Reabilitar triggers
SET session_replication_role = 'origin';

-- Mensagem final
DO $$
BEGIN
    RAISE NOTICE 'OPERACOES LIMPAS COM SUCESSO!';
    RAISE NOTICE 'Removidos: vendas, pedidos, dividas, caixa, despesas, stock, faturas entrada, auditoria, logs';
    RAISE NOTICE 'Estoques zerados e sequencias resetadas';
END $$;
