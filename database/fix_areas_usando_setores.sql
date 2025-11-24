-- ===================================
-- FIX: Usar SETORES como ÁREAS
-- Descrição: Renomear setores para funcionar como áreas (BAR, COZINHA, etc.)
-- As famílias já estão relacionadas com setores via familia_setores
-- Data: 2025
-- ===================================

-- Opção 1: Se você quer renomear os setores existentes
-- Descomente as linhas abaixo e ajuste os IDs conforme necessário

-- UPDATE setores SET nome = 'BAR', descricao = 'Área do Bar' WHERE id = 1;
-- UPDATE setores SET nome = 'COZINHA', descricao = 'Área da Cozinha' WHERE id = 2;
-- UPDATE setores SET nome = 'SALA', descricao = 'Área da Sala' WHERE id = 3;

-- ===================================
-- Verificar setores existentes
-- ===================================
SELECT id, nome, descricao FROM setores ORDER BY id;

-- ===================================
-- Verificar famílias e seus setores
-- ===================================
SELECT
    f.id,
    f.nome as familia,
    STRING_AGG(s.nome, ', ') as setores
FROM familias f
LEFT JOIN familia_setores fs ON f.id = fs.familia_id
LEFT JOIN setores s ON fs.setor_id = s.id
GROUP BY f.id, f.nome
ORDER BY f.nome;
