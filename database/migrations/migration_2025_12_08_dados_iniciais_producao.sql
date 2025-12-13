-- =====================================================
-- MIGRATION: Dados Iniciais para Produção
-- Data: 2025-12-08
-- Versão: 2.5.1
-- =====================================================
-- Execute este script no computador que já tem a base instalada
-- para adicionar permissões, tipos de documento, e corrigir dados
-- =====================================================

-- DESABILITAR TRIGGERS TEMPORARIAMENTE
SET session_replication_role = 'replica';

-- =====================================================
-- 1. ADICIONAR COLUNA codigo_barras (se não existir)
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'produtos'
        AND column_name = 'codigo_barras'
    ) THEN
        ALTER TABLE public.produtos ADD COLUMN codigo_barras VARCHAR(50);
        RAISE NOTICE 'Coluna codigo_barras adicionada!';
    ELSE
        RAISE NOTICE 'Coluna codigo_barras já existe.';
    END IF;
END $$;

-- Criar índice para código de barras
CREATE INDEX IF NOT EXISTS idx_produtos_codigo_barras ON public.produtos(codigo_barras);

-- =====================================================
-- 2. CRIAR PERFIS DE USUÁRIO (se não existirem)
-- =====================================================

INSERT INTO public.perfis_usuario (nome, descricao)
SELECT 'Super Administrador', 'Acesso total ao sistema'
WHERE NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Super Administrador');

INSERT INTO public.perfis_usuario (nome, descricao)
SELECT 'Administrador', 'Administrador com acesso a relatórios e configurações'
WHERE NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Administrador');

INSERT INTO public.perfis_usuario (nome, descricao)
SELECT 'Gerente', 'Gerente com acesso a relatórios'
WHERE NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Gerente');

INSERT INTO public.perfis_usuario (nome, descricao)
SELECT 'Operador', 'Operador de caixa básico'
WHERE NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Operador');

INSERT INTO public.perfis_usuario (nome, descricao)
SELECT 'Vendedor', 'Vendedor sem acesso administrativo'
WHERE NOT EXISTS (SELECT 1 FROM public.perfis_usuario WHERE nome = 'Vendedor');

-- =====================================================
-- 3. CRIAR TODAS AS PERMISSÕES
-- =====================================================

-- VENDAS
INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'efectuar_pagamento', 'Efectuar Pagamento', 'VENDAS', 'Permitir processar pagamentos de vendas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'efectuar_pagamento');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'fechar_caixa', 'Fechar Caixa', 'VENDAS', 'Permitir fechar o caixa'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'fechar_caixa');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'cancelar_venda', 'Cancelar Venda', 'VENDAS', 'Permitir cancelar vendas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'cancelar_venda');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'imprimir_conta', 'Imprimir Conta', 'VENDAS', 'Permitir imprimir contas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'imprimir_conta');

-- STOCK
INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'entrada_stock', 'Entrada de Stock', 'STOCK', 'Permitir registar entradas de stock'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'entrada_stock');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'acerto_stock', 'Acerto de Stock', 'STOCK', 'Permitir fazer acertos de stock'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'acerto_stock');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'ver_stock', 'Ver Stock', 'STOCK', 'Permitir visualizar stock'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'ver_stock');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_faturas', 'Gestão de Faturas', 'STOCK', 'Permitir visualizar e editar faturas de entrada'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_faturas');

-- CADASTROS
INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_produtos', 'Gestão de Produtos', 'CADASTROS', 'Permitir criar e editar produtos'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_produtos');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_familias', 'Gestão de Famílias', 'CADASTROS', 'Permitir criar e editar famílias'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_familias');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_clientes', 'Gestão de Clientes', 'CADASTROS', 'Permitir criar e editar clientes'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_clientes');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_fornecedores', 'Gestão de Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_fornecedores');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_setores', 'Gestão de Setores', 'CADASTROS', 'Permitir criar e editar setores'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_setores');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_areas', 'Gestão de Áreas', 'CADASTROS', 'Permitir criar e editar áreas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_areas');

-- FINANCEIRO
INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_despesas', 'Gestão de Despesas', 'FINANCEIRO', 'Permitir criar e editar despesas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_despesas');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_dividas', 'Gestão de Dívidas', 'FINANCEIRO', 'Permitir registar e gerenciar dívidas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_dividas');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_pagamentos', 'Gestão de Formas de Pagamento', 'FINANCEIRO', 'Permitir configurar formas de pagamento'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_pagamentos');

-- RELATÓRIOS
INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'visualizar_relatorios', 'Visualizar Relatórios', 'RELATORIOS', 'Permitir visualizar relatórios gerais'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'visualizar_relatorios');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'visualizar_margens', 'Visualizar Margens', 'RELATORIOS', 'Permitir visualizar margens e lucros'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'visualizar_margens');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'visualizar_stock', 'Visualizar Relatório de Stock', 'RELATORIOS', 'Permitir visualizar relatório de stock'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'visualizar_stock');

-- ADMINISTRAÇÃO
INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'acesso_admin', 'Acesso Administração', 'ADMIN', 'Permitir acesso ao módulo de administração'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'acesso_admin');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_usuarios', 'Gestão de Usuários', 'ADMIN', 'Permitir criar e editar usuários'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_usuarios');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_perfis', 'Gestão de Perfis', 'ADMIN', 'Permitir criar e editar perfis'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_perfis');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_permissoes', 'Gestão de Permissões', 'ADMIN', 'Permitir configurar permissões por perfil'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_permissoes');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'configuracoes_sistema', 'Configurações do Sistema', 'ADMIN', 'Permitir alterar configurações gerais'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'configuracoes_sistema');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_empresa');

INSERT INTO public.permissoes (codigo, nome, categoria, descricao)
SELECT 'gestao_mesas', 'Gestão de Mesas', 'ADMIN', 'Permitir criar e editar mesas'
WHERE NOT EXISTS (SELECT 1 FROM public.permissoes WHERE codigo = 'gestao_mesas');

-- =====================================================
-- 4. TIPOS DE DOCUMENTO
-- =====================================================
-- Estrutura real: id, codigo, nome, descricao, ativo, created_at
-- NÃO tem: prefixo, requer_cliente

INSERT INTO public.tipos_documento (codigo, nome, descricao)
SELECT 'FR', 'Fatura Recibo', 'Fatura com recibo integrado'
WHERE NOT EXISTS (SELECT 1 FROM public.tipos_documento WHERE codigo = 'FR');

INSERT INTO public.tipos_documento (codigo, nome, descricao)
SELECT 'FT', 'Fatura', 'Fatura comercial'
WHERE NOT EXISTS (SELECT 1 FROM public.tipos_documento WHERE codigo = 'FT');

INSERT INTO public.tipos_documento (codigo, nome, descricao)
SELECT 'VD', 'Venda a Dinheiro', 'Venda a dinheiro simplificada'
WHERE NOT EXISTS (SELECT 1 FROM public.tipos_documento WHERE codigo = 'VD');

INSERT INTO public.tipos_documento (codigo, nome, descricao)
SELECT 'NC', 'Nota de Crédito', 'Nota de crédito para devoluções'
WHERE NOT EXISTS (SELECT 1 FROM public.tipos_documento WHERE codigo = 'NC');

INSERT INTO public.tipos_documento (codigo, nome, descricao)
SELECT 'ND', 'Nota de Débito', 'Nota de débito'
WHERE NOT EXISTS (SELECT 1 FROM public.tipos_documento WHERE codigo = 'ND');

INSERT INTO public.tipos_documento (codigo, nome, descricao)
SELECT 'RC', 'Recibo', 'Recibo de pagamento'
WHERE NOT EXISTS (SELECT 1 FROM public.tipos_documento WHERE codigo = 'RC');

-- =====================================================
-- 5. VINCULAR PERMISSÕES AO SUPER ADMINISTRADOR
-- =====================================================

INSERT INTO public.perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM public.perfis_usuario WHERE nome = 'Super Administrador'),
    p.id
FROM public.permissoes p
WHERE p.ativo = true
AND NOT EXISTS (
    SELECT 1 FROM public.perfil_permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM public.perfis_usuario WHERE nome = 'Super Administrador')
    AND pp.permissao_id = p.id
);

-- =====================================================
-- 6. VINCULAR PERMISSÕES AO ADMINISTRADOR
-- =====================================================

INSERT INTO public.perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM public.perfis_usuario WHERE nome = 'Administrador'),
    p.id
FROM public.permissoes p
WHERE p.ativo = true
AND NOT EXISTS (
    SELECT 1 FROM public.perfil_permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM public.perfis_usuario WHERE nome = 'Administrador')
    AND pp.permissao_id = p.id
);

-- =====================================================
-- 7. CRIAR/ATUALIZAR USUÁRIO ADMIN
-- =====================================================

DO $$
DECLARE
    perfil_admin_id INTEGER;
BEGIN
    SELECT id INTO perfil_admin_id
    FROM public.perfis_usuario
    WHERE nome = 'Super Administrador'
    LIMIT 1;

    IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE codigo = '0000') THEN
        INSERT INTO public.usuarios (nome, codigo, perfil_id, ativo)
        VALUES ('Admin', '0000', perfil_admin_id, true);
        RAISE NOTICE 'Usuário Admin criado!';
    ELSE
        UPDATE public.usuarios
        SET perfil_id = perfil_admin_id, ativo = true
        WHERE codigo = '0000';
        RAISE NOTICE 'Usuário Admin atualizado!';
    END IF;
END $$;

-- REABILITAR TRIGGERS
SET session_replication_role = 'origin';

-- =====================================================
-- CONFIRMAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    qtd_perfis INTEGER;
    qtd_permissoes INTEGER;
    qtd_tipos_doc INTEGER;
BEGIN
    SELECT COUNT(*) INTO qtd_perfis FROM public.perfis_usuario WHERE ativo = true;
    SELECT COUNT(*) INTO qtd_permissoes FROM public.permissoes WHERE ativo = true;
    SELECT COUNT(*) INTO qtd_tipos_doc FROM public.tipos_documento WHERE ativo = true;

    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'MIGRATION EXECUTADA COM SUCESSO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Perfis de usuário: %', qtd_perfis;
    RAISE NOTICE 'Permissões: %', qtd_permissoes;
    RAISE NOTICE 'Tipos de documento: %', qtd_tipos_doc;
    RAISE NOTICE 'Usuário Admin: 0000';
    RAISE NOTICE '=====================================================';
END $$;
