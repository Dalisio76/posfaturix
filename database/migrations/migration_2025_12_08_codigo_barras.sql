-- =====================================================
-- MIGRATION: Adicionar coluna codigo_barras em produtos
-- Data: 2025-12-08
-- Versão: 2.5.1
-- =====================================================
-- Execute este script no computador que já tem a base instalada
-- para adicionar a coluna codigo_barras na tabela produtos
-- =====================================================

-- 1. Adicionar coluna codigo_barras (se não existir)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'produtos'
        AND column_name = 'codigo_barras'
    ) THEN
        ALTER TABLE public.produtos ADD COLUMN codigo_barras VARCHAR(50);
        RAISE NOTICE 'Coluna codigo_barras adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna codigo_barras já existe.';
    END IF;
END $$;

-- 2. Criar índice para busca por código de barras (se não existir)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename = 'produtos'
        AND indexname = 'idx_produtos_codigo_barras'
    ) THEN
        CREATE INDEX idx_produtos_codigo_barras ON public.produtos(codigo_barras);
        RAISE NOTICE 'Índice idx_produtos_codigo_barras criado com sucesso!';
    ELSE
        RAISE NOTICE 'Índice idx_produtos_codigo_barras já existe.';
    END IF;
END $$;

-- 3. Comentário na coluna
COMMENT ON COLUMN public.produtos.codigo_barras IS 'Código de barras do produto (EAN, UPC, etc)';

-- =====================================================
-- CONFIRMAÇÃO
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'MIGRATION EXECUTADA COM SUCESSO!';
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'Coluna: produtos.codigo_barras (VARCHAR 50)';
    RAISE NOTICE 'Índice: idx_produtos_codigo_barras';
    RAISE NOTICE '====================================================';
END $$;
