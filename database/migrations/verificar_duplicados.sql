-- =====================================================
-- VERIFICAR E CORRIGIR DUPLICADOS ANTES DE APLICAR CONSTRAINTS
-- =====================================================
-- EXECUTE ESTE SCRIPT PRIMEIRO para verificar se existem
-- duplicados que precisam ser corrigidos manualmente
-- =====================================================

-- =====================================================
-- 1. VERIFICAR DUPLICADOS EM PRODUTOS
-- =====================================================

-- Produtos com nome duplicado
SELECT 'PRODUTOS COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM produtos
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- Produtos com codigo de barras duplicado
SELECT 'PRODUTOS COM CODIGO DE BARRAS DUPLICADO:' as verificacao;
SELECT
    codigo_barras,
    COUNT(*) as quantidade,
    STRING_AGG(id::text || ' (' || nome || ')', ', ') as produtos
FROM produtos
WHERE ativo = true
AND codigo_barras IS NOT NULL
AND codigo_barras != ''
GROUP BY codigo_barras
HAVING COUNT(*) > 1;

-- Produtos com codigo duplicado
SELECT 'PRODUTOS COM CODIGO DUPLICADO:' as verificacao;
SELECT
    codigo,
    COUNT(*) as quantidade,
    STRING_AGG(id::text || ' (' || nome || ')', ', ') as produtos
FROM produtos
WHERE ativo = true
GROUP BY codigo
HAVING COUNT(*) > 1;

-- =====================================================
-- 2. VERIFICAR DUPLICADOS EM CLIENTES
-- =====================================================

-- Clientes com nome duplicado
SELECT 'CLIENTES COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM clientes
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- Clientes com contacto duplicado
SELECT 'CLIENTES COM CONTACTO DUPLICADO:' as verificacao;
SELECT
    contacto,
    COUNT(*) as quantidade,
    STRING_AGG(id::text || ' (' || nome || ')', ', ') as clientes
FROM clientes
WHERE ativo = true
AND contacto IS NOT NULL
AND contacto != ''
GROUP BY contacto
HAVING COUNT(*) > 1;

-- Clientes com NUIT duplicado
SELECT 'CLIENTES COM NUIT DUPLICADO:' as verificacao;
SELECT
    nuit,
    COUNT(*) as quantidade,
    STRING_AGG(id::text || ' (' || nome || ')', ', ') as clientes
FROM clientes
WHERE ativo = true
AND nuit IS NOT NULL
AND nuit != ''
GROUP BY nuit
HAVING COUNT(*) > 1;

-- =====================================================
-- 3. VERIFICAR DUPLICADOS EM OUTRAS TABELAS
-- =====================================================

-- Familias duplicadas
SELECT 'FAMILIAS COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM familias
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- Setores duplicados
SELECT 'SETORES COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM setores
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- Areas duplicadas
SELECT 'AREAS COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM areas
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- Formas de pagamento duplicadas
SELECT 'FORMAS PAGAMENTO COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM formas_pagamento
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- Usuarios duplicados (nome)
SELECT 'USUARIOS COM NOME DUPLICADO:' as verificacao;
SELECT
    UPPER(TRIM(nome)) as nome_normalizado,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM usuarios
WHERE ativo = true
GROUP BY UPPER(TRIM(nome))
HAVING COUNT(*) > 1;

-- =====================================================
-- RESUMO
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'VERIFICACAO DE DUPLICADOS CONCLUIDA';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Se houver duplicados listados acima, corrija-os antes';
    RAISE NOTICE 'de executar o script add_unique_constraints.sql';
    RAISE NOTICE '';
    RAISE NOTICE 'Para corrigir duplicados:';
    RAISE NOTICE '1. Renomeie um dos registros duplicados, OU';
    RAISE NOTICE '2. Desative (ativo=false) um dos duplicados, OU';
    RAISE NOTICE '3. Delete um dos duplicados';
    RAISE NOTICE '=====================================================';
END $$;
