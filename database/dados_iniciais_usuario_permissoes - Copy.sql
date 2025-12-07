-- =====================================================
-- DADOS INICIAIS: USUÁRIO E PERMISSÕES
-- =====================================================
-- Copie e cole este conteúdo no FINAL do arquivo estrutura_completa.sql
-- (antes da linha "-- PostgreSQL database dump complete")

-- =====================================================
-- 1. PERFIS DE USUÁRIO
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Super Administrador') THEN
        INSERT INTO public.perfis_usuario (nome, descricao)
        VALUES ('Super Administrador', 'Acesso total ao sistema');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Administrador') THEN
        INSERT INTO public.perfis_usuario (nome, descricao)
        VALUES ('Administrador', 'Administrador com acesso a relatórios e configurações');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Gerente') THEN
        INSERT INTO public.perfis_usuario (nome, descricao)
        VALUES ('Gerente', 'Gerente com acesso a relatórios');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Operador') THEN
        INSERT INTO public.perfis_usuario (nome, descricao)
        VALUES ('Operador', 'Operador de caixa básico');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Vendedor') THEN
        INSERT INTO public.perfis_usuario (nome, descricao)
        VALUES ('Vendedor', 'Vendedor sem acesso administrativo');
    END IF;
END $$;

-- =====================================================
-- 2. PERMISSÕES DO SISTEMA
-- =====================================================

DO $$
BEGIN
    -- VENDAS
    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'efectuar_pagamento') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('efectuar_pagamento', 'Efectuar Pagamento', 'VENDAS', 'Permitir processar pagamentos de vendas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'fechar_caixa') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('fechar_caixa', 'Fechar Caixa', 'VENDAS', 'Permitir fechar o caixa');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'cancelar_venda') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('cancelar_venda', 'Cancelar Venda', 'VENDAS', 'Permitir cancelar vendas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'imprimir_conta') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('imprimir_conta', 'Imprimir Conta', 'VENDAS', 'Permitir imprimir contas');
    END IF;

    -- STOCK
    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'entrada_stock') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('entrada_stock', 'Entrada de Stock', 'STOCK', 'Permitir registar entradas de stock');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'acerto_stock') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('acerto_stock', 'Acerto de Stock', 'STOCK', 'Permitir fazer acertos de stock');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'ver_stock') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('ver_stock', 'Ver Stock', 'STOCK', 'Permitir visualizar stock');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_faturas') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_faturas', 'Gestão de Faturas', 'STOCK', 'Permitir visualizar e editar faturas de entrada');
    END IF;

    -- CADASTROS
    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_produtos') THEN
        INSERT INTO public.public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_produtos', 'Gestão de Produtos', 'CADASTROS', 'Permitir criar e editar produtos');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_familias') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_familias', 'Gestão de Famílias', 'CADASTROS', 'Permitir criar e editar famílias');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_clientes') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_clientes', 'Gestão de Clientes', 'CADASTROS', 'Permitir criar e editar clientes');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_fornecedores') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_fornecedores', 'Gestão de Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_setores') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_setores', 'Gestão de Setores', 'CADASTROS', 'Permitir criar e editar setores');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_areas') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_areas', 'Gestão de Áreas', 'CADASTROS', 'Permitir criar e editar áreas');
    END IF;

    -- FINANCEIRO
    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_despesas') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_despesas', 'Gestão de Despesas', 'FINANCEIRO', 'Permitir criar e editar despesas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_dividas') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_dividas', 'Gestão de Dívidas', 'FINANCEIRO', 'Permitir registar e gerenciar dívidas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_pagamentos') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_pagamentos', 'Gestão de Formas de Pagamento', 'FINANCEIRO', 'Permitir configurar formas de pagamento');
    END IF;

    -- RELATÓRIOS
    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'visualizar_relatorios') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('visualizar_relatorios', 'Visualizar Relatórios', 'RELATORIOS', 'Permitir visualizar relatórios gerais');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'visualizar_margens') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('visualizar_margens', 'Visualizar Margens', 'RELATORIOS', 'Permitir visualizar margens e lucros');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'visualizar_stock') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('visualizar_stock', 'Visualizar Relatório de Stock', 'RELATORIOS', 'Permitir visualizar relatório de stock');
    END IF;

    -- ADMINISTRAÇÃO
    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'acesso_admin') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('acesso_admin', 'Acesso Administração', 'ADMIN', 'Permitir acesso ao módulo de administração');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_usuarios') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_usuarios', 'Gestão de Usuários', 'ADMIN', 'Permitir criar e editar usuários');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_perfis') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_perfis', 'Gestão de Perfis', 'ADMIN', 'Permitir criar e editar perfis');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_public.permissoes') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_public.permissoes', 'Gestão de Permissões', 'ADMIN', 'Permitir configurar permissões por perfil');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'configuracoes_sistema') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('configuracoes_sistema', 'Configurações do Sistema', 'ADMIN', 'Permitir alterar configurações gerais');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_empresa') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_mesas') THEN
        INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_mesas', 'Gestão de Mesas', 'ADMIN', 'Permitir criar e editar mesas');
    END IF;
END $$;

-- =====================================================
-- 3. VINCULAR PERMISSÕES AOS PERFIS
-- =====================================================

-- Super Administrador: TODAS as permissões
INSERT INTO perfil_public.permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM public.perfis_usuario WHERE nome = 'Super Administrador'),
    p.id
FROM public.permissoes p
WHERE p.ativo = true
  AND NOT EXISTS (
    SELECT 1 FROM perfil_public.permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador')
      AND pp.permissao_id = p.id
  );

-- Administrador: TODAS as permissões
INSERT INTO perfil_public.permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM public.perfis_usuario WHERE nome = 'Administrador'),
    p.id
FROM public.permissoes p
WHERE p.ativo = true
  AND NOT EXISTS (
    SELECT 1 FROM perfil_public.permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Administrador')
      AND pp.permissao_id = p.id
  );

-- =====================================================
-- 4. USUÁRIO ADMINISTRADOR PADRÃO
-- =====================================================
-- Nome: Admin
-- Código: 0000

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE codigo = '0000') THEN
        INSERT INTO public.usuarios (nome, codigo, perfil_id)
        VALUES ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'));
    ELSE
        UPDATE public.usuarios
        SET nome = 'Admin',
            ativo = true,
            perfil_id = (SELECT id FROM public.perfis_usuario WHERE nome = 'Super Administrador')
        WHERE codigo = '0000';
    END IF;
END $$;

-- =====================================================
-- FIM DOS DADOS INICIAIS
-- =====================================================

-- Mensagem de confirmação
DO $$
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'DADOS INICIAIS ADICIONADOS COM SUCESSO!';
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'Usuário: Admin';
    RAISE NOTICE 'Código: 0000';
    RAISE NOTICE 'Perfis: 5 criados';
    RAISE NOTICE 'Permissões: 27 criadas';
    RAISE NOTICE '====================================================';
END $$;
