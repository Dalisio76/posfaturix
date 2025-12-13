-- =====================================================
-- MIGRATION: Converter MAIÚSCULAS para Capitalizado
-- Data: 2025-12-08
-- =====================================================
-- Converte todos os nomes de MAIÚSCULAS para formato
-- capitalizado (primeira letra maiúscula de cada palavra)
-- =====================================================

-- Função auxiliar para capitalizar texto
CREATE OR REPLACE FUNCTION capitalizar_texto(texto TEXT)
RETURNS TEXT AS $$
BEGIN
    IF texto IS NULL OR texto = '' THEN
        RETURN texto;
    END IF;
    RETURN INITCAP(LOWER(texto));
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- EXECUTAR TODAS AS CONVERSÕES
-- =====================================================

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'INICIANDO CONVERSÃO DE MAIÚSCULAS...';
    RAISE NOTICE '=====================================================';

    -- 1. PRODUTOS
    UPDATE public.produtos
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Produtos atualizados: %', v_count;

    -- 2. FAMÍLIAS
    UPDATE public.familias
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Famílias atualizadas: %', v_count;

    -- 3. SETORES
    UPDATE public.setores
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Setores atualizados: %', v_count;

    -- 4. ÁREAS
    UPDATE public.areas
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Áreas atualizadas: %', v_count;

    -- 5. CLIENTES
    UPDATE public.clientes
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Clientes atualizados: %', v_count;

    -- 6. FORNECEDORES
    UPDATE public.fornecedores
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Fornecedores atualizados: %', v_count;

    -- 7. USUÁRIOS
    UPDATE public.usuarios
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Usuários atualizados: %', v_count;

    -- 8. IMPRESSORAS
    UPDATE public.impressoras
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Impressoras atualizadas: %', v_count;

    -- 9. MESAS
    UPDATE public.mesas
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Mesas atualizadas: %', v_count;

    -- 10. FORMAS DE PAGAMENTO
    UPDATE public.formas_pagamento
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Formas de pagamento atualizadas: %', v_count;

    -- 11. PERFIS DE USUÁRIO
    UPDATE public.perfis_usuario
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Perfis de usuário atualizados: %', v_count;

    -- 12. PERMISSÕES
    UPDATE public.permissoes
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Permissões atualizadas: %', v_count;

    -- 13. TIPOS DE DOCUMENTO
    UPDATE public.tipos_documento
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Tipos de documento atualizados: %', v_count;

    -- 14. LOCAIS DE MESA
    UPDATE public.locais_mesa
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Locais de mesa atualizados: %', v_count;

    -- 15. TERMINAIS
    UPDATE public.terminais
    SET nome = capitalizar_texto(nome)
    WHERE nome = UPPER(nome) AND nome IS NOT NULL AND LENGTH(nome) > 0;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Terminais atualizados: %', v_count;

    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'CONVERSÃO CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Todos os nomes em MAIÚSCULAS foram convertidos';
    RAISE NOTICE 'para formato capitalizado (Ex: "COCA COLA" -> "Coca Cola")';
    RAISE NOTICE '=====================================================';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Erro durante conversão: %', SQLERRM;
    RAISE;
END $$;
