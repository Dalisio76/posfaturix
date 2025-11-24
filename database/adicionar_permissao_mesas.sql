-- ===================================
-- ADICIONAR PERMISSÃO: gestao_mesas
-- ===================================

INSERT INTO permissoes (codigo, nome, descricao, categoria, ativo) VALUES
('gestao_mesas', 'Gestão de Mesas', 'Permite configurar locais e mesas do restaurante', 'ADMIN', true)
ON CONFLICT (codigo) DO NOTHING;

-- Adicionar permissão ao perfil Super Administrador
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    p.id as perfil_id,
    perm.id as permissao_id
FROM perfis_usuario p
CROSS JOIN permissoes perm
WHERE p.nome = 'Super Administrador'
  AND perm.codigo = 'gestao_mesas'
  AND NOT EXISTS (
    SELECT 1 FROM perfil_permissoes pp
    WHERE pp.perfil_id = p.id AND pp.permissao_id = perm.id
  );
