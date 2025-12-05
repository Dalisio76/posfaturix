-- ===================================
-- FIX: PERMISSÕES FALTANTES NO SISTEMA
-- ===================================
-- Este script adiciona permissões que estavam faltando
-- e garante que o perfil Administrador tenha todas as permissões

-- ===================================
-- 1. ADICIONAR PERMISSÕES FALTANTES
-- ===================================

-- Permissões de gestão
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('gestao_mesas', 'Gestão de Mesas', 'ADMIN', 'Permitir criar e editar mesas'),
    ('gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa'),
    ('gestao_fornecedores', 'Gestão de Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores'),
    ('gestao_clientes', 'Gestão de Clientes', 'CADASTROS', 'Permitir criar e editar clientes'),
    ('gestao_produtos', 'Gestão de Produtos', 'CADASTROS', 'Permitir criar e editar produtos'),
    ('gestao_faturas', 'Gestão de Faturas', 'STOCK', 'Permitir visualizar e editar faturas de entrada'),
    ('gestao_despesas', 'Gestão de Despesas', 'FINANCEIRO', 'Permitir criar e editar despesas'),
    ('gestao_pagamentos', 'Gestão de Formas de Pagamento', 'FINANCEIRO', 'Permitir configurar formas de pagamento'),
    ('gestao_setores', 'Gestão de Setores', 'CADASTROS', 'Permitir criar e editar setores'),
    ('gestao_areas', 'Gestão de Áreas', 'CADASTROS', 'Permitir criar e editar áreas')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de visualização de relatórios
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('visualizar_relatorios', 'Visualizar Relatórios', 'RELATORIOS', 'Permitir visualizar relatórios gerais'),
    ('visualizar_margens', 'Visualizar Margens', 'RELATORIOS', 'Permitir visualizar margens e lucros'),
    ('visualizar_stock', 'Visualizar Relatório de Stock', 'RELATORIOS', 'Permitir visualizar relatório de stock')
ON CONFLICT (codigo) DO NOTHING;

-- ===================================
-- 2. ATUALIZAR PERMISSÕES DO ADMINISTRADOR
-- ===================================
-- Garantir que o perfil "Administrador" tenha TODAS as permissões
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Administrador'),
    id
FROM permissoes
WHERE ativo = true
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 3. ATUALIZAR PERMISSÕES DO SUPER ADMINISTRADOR
-- ===================================
-- Garantir que o perfil "Super Administrador" tenha TODAS as permissões
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'),
    id
FROM permissoes
WHERE ativo = true
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 4. VERIFICAÇÃO
-- ===================================

-- Ver total de permissões por perfil
SELECT
    p.nome as perfil,
    COUNT(pp.id) as total_permissoes,
    (SELECT COUNT(*) FROM permissoes WHERE ativo = true) as total_sistema
FROM perfis_usuario p
LEFT JOIN perfil_permissoes pp ON pp.perfil_id = p.id
WHERE p.nome IN ('Administrador', 'Super Administrador')
GROUP BY p.id, p.nome
ORDER BY p.nome;

-- Ver permissões do Administrador
SELECT
    perm.categoria,
    perm.codigo,
    perm.nome
FROM perfil_permissoes pp
INNER JOIN permissoes perm ON perm.id = pp.permissao_id
WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Administrador')
ORDER BY perm.categoria, perm.nome;

-- ===================================
-- RESULTADO ESPERADO:
-- Ambos os perfis devem ter o mesmo número
-- de permissões que o total do sistema
-- ===================================
