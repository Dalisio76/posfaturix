-- ===================================
-- CORRIGIR CONSTRAINTS DA TABELA USUARIOS
-- ===================================
-- Permitir múltiplos usuários com mesmo código
-- Tornar o NOME único ao invés do CÓDIGO
-- ===================================

-- 1. Remover constraint UNIQUE do código
ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_codigo_key;

-- 2. Remover índice do código (se existir)
DROP INDEX IF EXISTS idx_usuarios_codigo;

-- 3. Adicionar constraint UNIQUE no nome
ALTER TABLE usuarios ADD CONSTRAINT usuarios_nome_key UNIQUE(nome);

-- 4. Recriar índice no código (mas não único)
CREATE INDEX IF NOT EXISTS idx_usuarios_codigo ON usuarios(codigo);

-- 5. Adicionar índice no nome
CREATE INDEX IF NOT EXISTS idx_usuarios_nome ON usuarios(nome);

-- ===================================
-- ATUALIZAR COMENTÁRIOS
-- ===================================
COMMENT ON COLUMN usuarios.codigo IS 'Código numérico de 1 a 8 dígitos para login (pode ser repetido entre usuários)';
COMMENT ON COLUMN usuarios.nome IS 'Nome do usuário (deve ser único)';

-- ===================================
-- VERIFICAÇÃO
-- ===================================
SELECT
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint
WHERE conrelid = 'usuarios'::regclass;

-- ===================================
-- NOTAS
-- ===================================
-- Agora múltiplos usuários podem ter o mesmo código
-- O nome do usuário deve ser único
-- Isso permite ter vários "caixas" usando o mesmo código, por exemplo
-- ===================================
