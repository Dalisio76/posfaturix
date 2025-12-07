-- =====================================================
-- DADOS INICIAIS MÍNIMOS: APENAS USUÁRIO ADMIN
-- =====================================================
-- Este script cria APENAS o usuário Admin/0000
-- Sem perfis, sem permissões (você configura manualmente)
-- =====================================================

-- DESABILITAR TRIGGERS TEMPORARIAMENTE
SET session_replication_role = 'replica';

-- =====================================================
-- 1. CRIAR PERFIL "Super Administrador" (se não existir)
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Super Administrador') THEN
        INSERT INTO public.perfis_usuario (nome, descricao)
        VALUES ('Super Administrador', 'Acesso total ao sistema');
        RAISE NOTICE 'Perfil "Super Administrador" criado';
    ELSE
        RAISE NOTICE 'Perfil "Super Administrador" já existe';
    END IF;
END $$;

-- =====================================================
-- 2. CRIAR USUÁRIO ADMIN/0000 (se não existir)
-- =====================================================

DO $$
DECLARE
    perfil_admin_id INTEGER;
BEGIN
    -- Buscar ID do perfil Super Administrador
    SELECT id INTO perfil_admin_id
    FROM public.perfis_usuario
    WHERE nome = 'Super Administrador'
    LIMIT 1;

    IF perfil_admin_id IS NULL THEN
        RAISE EXCEPTION 'Perfil "Super Administrador" não encontrado';
    END IF;

    -- Criar ou atualizar usuário Admin
    IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE codigo = '0000') THEN
        INSERT INTO public.usuarios (nome, codigo, perfil_id, ativo)
        VALUES ('Admin', '0000', perfil_admin_id, true);
        RAISE NOTICE 'Usuário "Admin" criado com código 0000';
    ELSE
        UPDATE public.usuarios
        SET nome = 'Admin',
            ativo = true,
            perfil_id = perfil_admin_id
        WHERE codigo = '0000';
        RAISE NOTICE 'Usuário "Admin" atualizado';
    END IF;
END $$;

-- REABILITAR TRIGGERS
SET session_replication_role = 'origin';

-- =====================================================
-- MENSAGEM FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'USUÁRIO ADMIN CRIADO COM SUCESSO!';
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'Nome: Admin';
    RAISE NOTICE 'Código: 0000';
    RAISE NOTICE 'Perfil: Super Administrador';
    RAISE NOTICE '';
    RAISE NOTICE 'IMPORTANTE:';
    RAISE NOTICE '- Configure as permissões manualmente na administração';
    RAISE NOTICE '- Este usuário foi criado sem permissões definidas';
    RAISE NOTICE '====================================================';
END $$;
