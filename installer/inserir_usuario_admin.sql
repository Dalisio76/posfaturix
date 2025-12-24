-- =====================================================
-- INSERIR USUARIO ADMIN - POSFATURIX
-- =====================================================
-- Execute este script apos restaurar a base de dados
-- =====================================================

-- Inserir perfil Super Administrador se nao existir
INSERT INTO perfis_usuario (nome, descricao)
VALUES ('Super Administrador', 'Acesso total ao sistema')
ON CONFLICT (nome) DO NOTHING;

-- Inserir usuario Admin com codigo 0000
INSERT INTO usuarios (nome, codigo, perfil_id, ativo)
VALUES (
    'Admin',
    '0000',
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador' LIMIT 1),
    true
)
ON CONFLICT (codigo) DO UPDATE SET
    nome = 'Admin',
    ativo = true,
    perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador' LIMIT 1);

-- Verificar
SELECT u.id, u.nome, u.codigo, p.nome as perfil
FROM usuarios u
LEFT JOIN perfis_usuario p ON p.id = u.perfil_id
WHERE u.codigo = '0000';
