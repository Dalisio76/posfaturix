-- =====================================================
-- CONSTRAINTS DE UNICIDADE - SEGURANCA NA BASE DE DADOS
-- =====================================================
-- Execute este script no PostgreSQL para garantir que
-- nao sejam criados registros duplicados
-- =====================================================

-- =====================================================
-- TABELA: PRODUTOS
-- =====================================================

-- 1. Indice unico para nome de produto (case insensitive, apenas ativos)
-- Nao permite dois produtos ativos com o mesmo nome
DROP INDEX IF EXISTS idx_produtos_nome_unique;
CREATE UNIQUE INDEX idx_produtos_nome_unique
ON produtos (UPPER(TRIM(nome)))
WHERE ativo = true;

-- 2. Indice unico para codigo de barras (apenas ativos e nao nulos)
-- Nao permite dois produtos ativos com o mesmo codigo de barras
DROP INDEX IF EXISTS idx_produtos_codigo_barras_unique;
CREATE UNIQUE INDEX idx_produtos_codigo_barras_unique
ON produtos (codigo_barras)
WHERE ativo = true AND codigo_barras IS NOT NULL AND codigo_barras != '';

-- 3. Indice unico para codigo do produto (apenas ativos)
DROP INDEX IF EXISTS idx_produtos_codigo_unique;
CREATE UNIQUE INDEX idx_produtos_codigo_unique
ON produtos (codigo)
WHERE ativo = true;

-- =====================================================
-- TABELA: CLIENTES
-- =====================================================

-- 1. Indice unico para nome de cliente (case insensitive, apenas ativos)
-- Nao permite dois clientes ativos com o mesmo nome
DROP INDEX IF EXISTS idx_clientes_nome_unique;
CREATE UNIQUE INDEX idx_clientes_nome_unique
ON clientes (UPPER(TRIM(nome)))
WHERE ativo = true;

-- 2. Indice unico para contacto (telefone principal, apenas ativos e nao nulos)
DROP INDEX IF EXISTS idx_clientes_contacto_unique;
CREATE UNIQUE INDEX idx_clientes_contacto_unique
ON clientes (contacto)
WHERE ativo = true AND contacto IS NOT NULL AND contacto != '';

-- 3. Indice unico para NUIT (apenas ativos e nao nulos)
DROP INDEX IF EXISTS idx_clientes_nuit_unique;
CREATE UNIQUE INDEX idx_clientes_nuit_unique
ON clientes (nuit)
WHERE ativo = true AND nuit IS NOT NULL AND nuit != '';

-- =====================================================
-- TABELA: FAMILIAS
-- =====================================================

-- Indice unico para nome de familia (case insensitive, apenas ativas)
DROP INDEX IF EXISTS idx_familias_nome_unique;
CREATE UNIQUE INDEX idx_familias_nome_unique
ON familias (UPPER(TRIM(nome)))
WHERE ativo = true;

-- =====================================================
-- TABELA: FORMAS_PAGAMENTO
-- =====================================================

-- Indice unico para nome de forma de pagamento (case insensitive, apenas ativas)
DROP INDEX IF EXISTS idx_formas_pagamento_nome_unique;
CREATE UNIQUE INDEX idx_formas_pagamento_nome_unique
ON formas_pagamento (UPPER(TRIM(nome)))
WHERE ativo = true;

-- =====================================================
-- TABELA: SETORES
-- =====================================================

-- Indice unico para nome de setor (case insensitive, apenas ativos)
DROP INDEX IF EXISTS idx_setores_nome_unique;
CREATE UNIQUE INDEX idx_setores_nome_unique
ON setores (UPPER(TRIM(nome)))
WHERE ativo = true;

-- =====================================================
-- TABELA: AREAS
-- =====================================================

-- Indice unico para nome de area (case insensitive, apenas ativas)
DROP INDEX IF EXISTS idx_areas_nome_unique;
CREATE UNIQUE INDEX idx_areas_nome_unique
ON areas (UPPER(TRIM(nome)))
WHERE ativo = true;

-- =====================================================
-- TABELA: USUARIOS
-- =====================================================

-- Indice unico para nome de usuario (case insensitive, apenas ativos)
DROP INDEX IF EXISTS idx_usuarios_nome_unique;
CREATE UNIQUE INDEX idx_usuarios_nome_unique
ON usuarios (UPPER(TRIM(nome)))
WHERE ativo = true;

-- =====================================================
-- VERIFICACAO
-- =====================================================

-- Listar todos os indices unicos criados
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE '%_unique%'
ORDER BY tablename, indexname;

-- =====================================================
-- MENSAGEM DE SUCESSO
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'CONSTRAINTS DE UNICIDADE APLICADAS COM SUCESSO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Produtos: nome, codigo, codigo_barras';
    RAISE NOTICE 'Clientes: nome, contacto, nuit';
    RAISE NOTICE 'Familias: nome';
    RAISE NOTICE 'Formas Pagamento: nome';
    RAISE NOTICE 'Setores: nome';
    RAISE NOTICE 'Areas: nome';
    RAISE NOTICE 'Usuarios: nome';
    RAISE NOTICE '=====================================================';
END $$;
