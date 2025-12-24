-- =====================================================
-- DADOS INICIAIS - POSFATURIX v2.6.0
-- =====================================================
-- Execute este script APOS restaurar database_inicial32.sql
-- =====================================================

-- PERFIS DE USUARIO
INSERT INTO perfis_usuario (id, nome, descricao) VALUES
(1, 'Super Administrador', 'Acesso total ao sistema'),
(2, 'Gerente', 'Acesso a relatorios e gestao'),
(3, 'Operador', 'Acesso apenas ao PDV'),
(4, 'Caixa', 'Acesso ao caixa e vendas')
ON CONFLICT (id) DO NOTHING;

-- Resetar sequence
SELECT setval('perfis_usuario_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM perfis_usuario), false);

-- FORMAS DE PAGAMENTO
INSERT INTO formas_pagamento (id, nome, ativo) VALUES
(1, 'Dinheiro', true),
(2, 'Cartao Credito', true),
(3, 'Cartao Debito', true),
(4, 'M-Pesa', true),
(5, 'E-Mola', true),
(6, 'Transferencia', true)
ON CONFLICT (id) DO NOTHING;

-- Resetar sequence
SELECT setval('formas_pagamento_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM formas_pagamento), false);

-- USUARIO ADMIN
INSERT INTO usuarios (id, nome, codigo, perfil_id, ativo) VALUES
(1, 'Admin', '0000', 1, true)
ON CONFLICT (id) DO NOTHING;

-- Resetar sequence
SELECT setval('usuarios_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM usuarios), false);

-- VERIFICAR
SELECT 'Perfis criados:' as info, count(*) as total FROM perfis_usuario;
SELECT 'Formas pagamento:' as info, count(*) as total FROM formas_pagamento;
SELECT 'Usuarios:' as info, count(*) as total FROM usuarios;

SELECT u.nome, u.codigo, p.nome as perfil
FROM usuarios u
JOIN perfis_usuario p ON p.id = u.perfil_id;
