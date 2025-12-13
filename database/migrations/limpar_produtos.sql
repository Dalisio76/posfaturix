-- =====================================================
-- SCRIPT: Limpar todos os produtos
-- Data: 2025-12-08
-- =====================================================
-- ATENÇÃO: Este script remove TODOS os produtos!
-- Execute com cuidado.
-- =====================================================

-- Desabilitar triggers temporariamente
SET session_replication_role = 'replica';

-- Limpar tabelas relacionadas primeiro (ordem importante)
DELETE FROM public.produto_composicao;
DELETE FROM public.itens_venda;
DELETE FROM public.produtos;

-- Resetar sequência de IDs
ALTER SEQUENCE public.produtos_id_seq RESTART WITH 1;

-- Reabilitar triggers
SET session_replication_role = 'origin';

DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'TODOS OS PRODUTOS FORAM REMOVIDOS!';
    RAISE NOTICE '=====================================================';
END $$;
