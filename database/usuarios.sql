-- ===================================
-- TABELAS: Sistema de Usuários e Perfis
-- ===================================

-- ===================================
-- 1. CRIAR TABELA PERFIS_USUARIO
-- ===================================
CREATE TABLE IF NOT EXISTS perfis_usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 2. CRIAR TABELA USUARIOS
-- ===================================
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    perfil_id INTEGER NOT NULL REFERENCES perfis_usuario(id) ON DELETE RESTRICT,
    codigo VARCHAR(8) NOT NULL,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(codigo)
);

-- ===================================
-- 3. ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_usuarios_perfil ON usuarios(perfil_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_codigo ON usuarios(codigo);
CREATE INDEX IF NOT EXISTS idx_usuarios_ativo ON usuarios(ativo);

-- ===================================
-- 4. VIEWS ÚTEIS
-- ===================================

-- View: Usuários com informações do perfil
CREATE OR REPLACE VIEW v_usuarios_completo AS
SELECT
    u.id,
    u.nome,
    u.perfil_id,
    p.nome as perfil_nome,
    u.codigo,
    u.ativo,
    u.created_at,
    u.updated_at
FROM usuarios u
INNER JOIN perfis_usuario p ON u.perfil_id = p.id
ORDER BY u.nome;

-- ===================================
-- 5. INSERIR PERFIS PADRÃO
-- ===================================
INSERT INTO perfis_usuario (nome, descricao) VALUES
    ('Administrador', 'Acesso total ao sistema'),
    ('Gerente', 'Acesso a relatórios e configurações'),
    ('Caixa', 'Acesso ao PDV e vendas'),
    ('Estoquista', 'Acesso ao controle de estoque')
ON CONFLICT (nome) DO NOTHING;

-- ===================================
-- 6. INSERIR USUÁRIO ADMINISTRADOR PADRÃO
-- ===================================
-- Código: 1234
INSERT INTO usuarios (nome, perfil_id, codigo)
VALUES ('Administrador', (SELECT id FROM perfis_usuario WHERE nome = 'Administrador'), '1234')
ON CONFLICT (codigo) DO NOTHING;

-- ===================================
-- 7. COMENTÁRIOS
-- ===================================
COMMENT ON TABLE perfis_usuario IS 'Perfis/categorias de usuários do sistema';
COMMENT ON TABLE usuarios IS 'Usuários do sistema';
COMMENT ON COLUMN usuarios.codigo IS 'Código numérico de 1 a 8 dígitos para login';
COMMENT ON COLUMN usuarios.perfil_id IS 'Perfil/categoria do usuário';

-- ===================================
-- 8. VERIFICAÇÃO
-- ===================================

-- Ver estrutura das tabelas
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('perfis_usuario', 'usuarios')
ORDER BY table_name, ordinal_position;

-- Ver dados inseridos
SELECT * FROM perfis_usuario;
SELECT * FROM v_usuarios_completo;

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. O código é único por usuário
-- 2. O código pode ter de 1 a 8 dígitos
-- 3. Usuário administrador padrão: código 1234
-- 4. DELETE RESTRICT impede deletar perfil se houver usuários
-- 5. View v_usuarios_completo facilita consultas
--
-- Para rollback:
-- DROP VIEW v_usuarios_completo;
-- DROP TABLE usuarios CASCADE;
-- DROP TABLE perfis_usuario CASCADE;
-- ===================================
