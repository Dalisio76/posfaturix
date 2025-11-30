-- =====================================================
-- POSFATURIX - BASE DE DADOS INICIAL LIMPA
-- =====================================================
-- Este script cria a base de dados completa do zero
-- com usuário super administrador padrão
--
-- USUÁRIO PADRÃO:
--   Nome: Admin
--   Código: 0000
--   Perfil: Super Administrador
-- =====================================================

-- =====================================================
-- 1. CRIAR DATABASE (executar como postgres)
-- =====================================================
-- DROP DATABASE IF EXISTS pdv_system; -- CUIDADO: Apaga tudo!
-- CREATE DATABASE pdv_system
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'Portuguese_Brazil.1252'
--     LC_CTYPE = 'Portuguese_Brazil.1252'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1;

-- =====================================================
-- 2. CONECTAR AO DATABASE
-- =====================================================
\c pdv_system;

-- =====================================================
-- 3. EMPRESAS
-- =====================================================
CREATE TABLE IF NOT EXISTS empresas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nif VARCHAR(50),
    morada TEXT,
    telefone VARCHAR(50),
    email VARCHAR(100),
    logo_path TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir empresa padrão
INSERT INTO empresas (nome, nif, morada, telefone, email) VALUES
('RESTAURANTE EXEMPLO', '000000000', 'Endereço da Empresa', '000-000-000', 'contato@restaurante.com')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 4. PERFIS DE USUÁRIO
-- =====================================================
CREATE TABLE IF NOT EXISTS perfis_usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO perfis_usuario (nome, descricao) VALUES
    ('Super Administrador', 'Acesso total irrestrito ao sistema'),
    ('Administrador', 'Acesso administrativo completo'),
    ('Gerente', 'Acesso a relatórios e configurações'),
    ('Caixa', 'Acesso ao PDV e vendas'),
    ('Estoquista', 'Acesso ao controle de estoque'),
    ('Garçom', 'Acesso apenas a mesas e pedidos')
ON CONFLICT (nome) DO NOTHING;

-- =====================================================
-- 5. USUÁRIOS
-- =====================================================
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

CREATE INDEX IF NOT EXISTS idx_usuarios_perfil ON usuarios(perfil_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_codigo ON usuarios(codigo);
CREATE INDEX IF NOT EXISTS idx_usuarios_ativo ON usuarios(ativo);

-- USUÁRIO SUPER ADMINISTRADOR PADRÃO
-- Código: 0000
INSERT INTO usuarios (nome, perfil_id, codigo)
VALUES ('Admin', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'), '0000')
ON CONFLICT (codigo) DO UPDATE SET nome = 'Admin', ativo = true;

-- =====================================================
-- 6. PERMISSÕES
-- =====================================================
CREATE TABLE IF NOT EXISTS permissoes (
    id SERIAL PRIMARY KEY,
    perfil_id INTEGER NOT NULL REFERENCES perfis_usuario(id) ON DELETE CASCADE,
    recurso VARCHAR(100) NOT NULL,
    pode_criar BOOLEAN DEFAULT false,
    pode_ler BOOLEAN DEFAULT false,
    pode_editar BOOLEAN DEFAULT false,
    pode_deletar BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(perfil_id, recurso)
);

CREATE INDEX IF NOT EXISTS idx_permissoes_perfil ON permissoes(perfil_id);

-- Permissões do Super Administrador (TODAS)
INSERT INTO permissoes (perfil_id, recurso, pode_criar, pode_ler, pode_editar, pode_deletar)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'),
    recurso,
    true, true, true, true
FROM (VALUES
    ('vendas'),
    ('produtos'),
    ('familias'),
    ('setores'),
    ('areas'),
    ('clientes'),
    ('dividas'),
    ('despesas'),
    ('fornecedores'),
    ('caixa'),
    ('usuarios'),
    ('permissoes'),
    ('configuracoes'),
    ('relatorios'),
    ('mesas'),
    ('impressoras')
) AS recursos(recurso)
ON CONFLICT (perfil_id, recurso) DO UPDATE
    SET pode_criar = true, pode_ler = true, pode_editar = true, pode_deletar = true;

-- =====================================================
-- 7. SETORES
-- =====================================================
CREATE TABLE IF NOT EXISTS setores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    cor VARCHAR(50) DEFAULT '#2196F3',
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO setores (nome, descricao, cor) VALUES
    ('Bebidas', 'Setor de bebidas', '#2196F3'),
    ('Comidas', 'Setor de comidas', '#4CAF50'),
    ('Sobremesas', 'Setor de sobremesas', '#FF9800')
ON CONFLICT (nome) DO NOTHING;

-- =====================================================
-- 8. ÁREAS (Bar, Cozinha, etc.)
-- =====================================================
CREATE TABLE IF NOT EXISTS areas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    impressora_padrao VARCHAR(255),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO areas (nome, descricao) VALUES
    ('Geral', 'Área geral do restaurante'),
    ('Bar', 'Área do bar'),
    ('Cozinha', 'Área da cozinha')
ON CONFLICT (nome) DO NOTHING;

-- =====================================================
-- 9. FAMÍLIAS (Categorias de Produtos)
-- =====================================================
CREATE TABLE IF NOT EXISTS familias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    setor_id INTEGER REFERENCES setores(id) ON DELETE SET NULL,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(nome, setor_id)
);

CREATE INDEX IF NOT EXISTS idx_familias_setor ON familias(setor_id);

INSERT INTO familias (nome, setor_id) VALUES
    ('Refrigerantes', (SELECT id FROM setores WHERE nome = 'Bebidas')),
    ('Cervejas', (SELECT id FROM setores WHERE nome = 'Bebidas')),
    ('Pratos Principais', (SELECT id FROM setores WHERE nome = 'Comidas')),
    ('Sobremesas', (SELECT id FROM setores WHERE nome = 'Sobremesas'))
ON CONFLICT DO NOTHING;

-- =====================================================
-- 10. PRODUTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    codigo_barras VARCHAR(50) UNIQUE,
    nome VARCHAR(200) NOT NULL,
    familia_id INTEGER REFERENCES familias(id) ON DELETE SET NULL,
    setor_id INTEGER REFERENCES setores(id) ON DELETE SET NULL,
    area_id INTEGER REFERENCES areas(id) ON DELETE SET NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_produtos_familia ON produtos(familia_id);
CREATE INDEX IF NOT EXISTS idx_produtos_setor ON produtos(setor_id);
CREATE INDEX IF NOT EXISTS idx_produtos_area ON produtos(area_id);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON produtos(ativo);
CREATE INDEX IF NOT EXISTS idx_produtos_codigo_barras ON produtos(codigo_barras);

-- Produtos de exemplo
INSERT INTO produtos (codigo, nome, familia_id, setor_id, area_id, preco, estoque) VALUES
    ('001', 'Coca-Cola 350ml',
     (SELECT id FROM familias WHERE nome = 'Refrigerantes'),
     (SELECT id FROM setores WHERE nome = 'Bebidas'),
     (SELECT id FROM areas WHERE nome = 'Bar'),
     2.50, 100),
    ('002', 'Cerveja Heineken',
     (SELECT id FROM familias WHERE nome = 'Cervejas'),
     (SELECT id FROM setores WHERE nome = 'Bebidas'),
     (SELECT id FROM areas WHERE nome = 'Bar'),
     5.00, 50),
    ('003', 'Bife com Batatas',
     (SELECT id FROM familias WHERE nome = 'Pratos Principais'),
     (SELECT id FROM setores WHERE nome = 'Comidas'),
     (SELECT id FROM areas WHERE nome = 'Cozinha'),
     25.00, 30)
ON CONFLICT (codigo) DO NOTHING;

-- =====================================================
-- 11. CLIENTES
-- =====================================================
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nif VARCHAR(50),
    morada TEXT,
    telefone VARCHAR(50),
    email VARCHAR(100),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_clientes_nome ON clientes(nome);
CREATE INDEX IF NOT EXISTS idx_clientes_ativo ON clientes(ativo);

-- =====================================================
-- 12. VENDAS
-- =====================================================
CREATE TABLE IF NOT EXISTS vendas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    total DECIMAL(10,2) NOT NULL,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    terminal VARCHAR(50),
    observacoes TEXT
);

CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas(data_venda);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario ON vendas(usuario_id);

-- =====================================================
-- 13. ITENS DE VENDA
-- =====================================================
CREATE TABLE IF NOT EXISTS itens_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_itens_venda ON itens_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_produto ON itens_venda(produto_id);

-- =====================================================
-- 14. FORMAS DE PAGAMENTO
-- =====================================================
CREATE TABLE IF NOT EXISTS formas_pagamento (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO formas_pagamento (nome) VALUES
    ('Dinheiro'),
    ('Cartão de Débito'),
    ('Cartão de Crédito'),
    ('MB Way'),
    ('Transferência'),
    ('Crédito (Dívida)')
ON CONFLICT (nome) DO NOTHING;

-- =====================================================
-- 15. PAGAMENTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS pagamentos (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    valor DECIMAL(10,2) NOT NULL,
    data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pagamentos_venda ON pagamentos(venda_id);

-- =====================================================
-- 16. MESAS
-- =====================================================
CREATE TABLE IF NOT EXISTS mesas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(20) NOT NULL UNIQUE,
    nome VARCHAR(100),
    capacidade INTEGER DEFAULT 4,
    ativa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO mesas (numero, nome, capacidade) VALUES
    ('1', 'Mesa 1', 4),
    ('2', 'Mesa 2', 4),
    ('3', 'Mesa 3', 6),
    ('4', 'Mesa 4', 2),
    ('5', 'Mesa 5', 4)
ON CONFLICT (numero) DO NOTHING;

-- =====================================================
-- 17. PEDIDOS (para mesas)
-- =====================================================
CREATE TABLE IF NOT EXISTS pedidos (
    id SERIAL PRIMARY KEY,
    mesa_id INTEGER REFERENCES mesas(id) ON DELETE SET NULL,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'aberto',
    total DECIMAL(10,2) DEFAULT 0,
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fechamento TIMESTAMP,
    observacoes TEXT
);

CREATE INDEX IF NOT EXISTS idx_pedidos_mesa ON pedidos(mesa_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_status ON pedidos(status);

-- =====================================================
-- 18. ITENS DE PEDIDO
-- =====================================================
CREATE TABLE IF NOT EXISTS itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pendente',
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    impresso BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_itens_pedido ON itens_pedido(pedido_id);

-- =====================================================
-- 19. CAIXA
-- =====================================================
CREATE TABLE IF NOT EXISTS caixa (
    id SERIAL PRIMARY KEY,
    usuario_abertura_id INTEGER REFERENCES usuarios(id),
    usuario_fechamento_id INTEGER REFERENCES usuarios(id),
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fechamento TIMESTAMP,
    valor_inicial DECIMAL(10,2) DEFAULT 0,
    valor_final DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'aberto',
    observacoes TEXT
);

CREATE INDEX IF NOT EXISTS idx_caixa_status ON caixa(status);
CREATE INDEX IF NOT EXISTS idx_caixa_data_abertura ON caixa(data_abertura);

-- =====================================================
-- 20. DESPESAS
-- =====================================================
CREATE TABLE IF NOT EXISTS despesas (
    id SERIAL PRIMARY KEY,
    caixa_id INTEGER REFERENCES caixa(id) ON DELETE CASCADE,
    descricao VARCHAR(255) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(100),
    data_despesa TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_id INTEGER REFERENCES usuarios(id)
);

CREATE INDEX IF NOT EXISTS idx_despesas_caixa ON despesas(caixa_id);

-- =====================================================
-- 21. DÍVIDAS
-- =====================================================
CREATE TABLE IF NOT EXISTS dividas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE SET NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    valor_pago DECIMAL(10,2) DEFAULT 0,
    valor_restante DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pendente',
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_quitacao TIMESTAMP,
    observacoes TEXT
);

CREATE INDEX IF NOT EXISTS idx_dividas_cliente ON dividas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_dividas_status ON dividas(status);

-- =====================================================
-- 22. PAGAMENTOS DE DÍVIDAS
-- =====================================================
CREATE TABLE IF NOT EXISTS pagamentos_divida (
    id SERIAL PRIMARY KEY,
    divida_id INTEGER REFERENCES dividas(id) ON DELETE CASCADE,
    caixa_id INTEGER REFERENCES caixa(id) ON DELETE SET NULL,
    valor DECIMAL(10,2) NOT NULL,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT
);

CREATE INDEX IF NOT EXISTS idx_pagamentos_divida ON pagamentos_divida(divida_id);

-- =====================================================
-- 23. CONFIGURAÇÕES DO SISTEMA
-- =====================================================
CREATE TABLE IF NOT EXISTS configuracoes_sistema (
    id SERIAL PRIMARY KEY,
    chave VARCHAR(100) NOT NULL UNIQUE,
    valor TEXT,
    tipo VARCHAR(50) DEFAULT 'string',
    descricao TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO configuracoes_sistema (chave, valor, tipo, descricao) VALUES
    ('impressora_padrao', 'balcao', 'string', 'Nome da impressora padrão'),
    ('perguntar_antes_de_imprimir', 'true', 'boolean', 'Perguntar antes de imprimir recibo'),
    ('timeout_ativo', 'true', 'boolean', 'Ativar timeout de inatividade'),
    ('timeout_segundos', '30', 'integer', 'Segundos de inatividade antes de logout'),
    ('mostrar_botao_pedidos', 'true', 'boolean', 'Mostrar botão de pedidos/mesas'),
    ('empresa_id', '1', 'integer', 'ID da empresa ativa'),
    ('proximo_numero_venda', '1', 'integer', 'Próximo número de venda')
ON CONFLICT (chave) DO NOTHING;

-- =====================================================
-- 24. VIEW: Usuários Completo
-- =====================================================
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

-- =====================================================
-- 25. VIEW: Produtos Completo
-- =====================================================
CREATE OR REPLACE VIEW v_produtos_completo AS
SELECT
    p.id,
    p.codigo,
    p.codigo_barras,
    p.nome,
    p.preco,
    p.estoque,
    p.ativo,
    f.nome as familia_nome,
    s.nome as setor_nome,
    a.nome as area_nome
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id
ORDER BY p.nome;

-- =====================================================
-- 26. COMENTÁRIOS
-- =====================================================
COMMENT ON DATABASE pdv_system IS 'Sistema POS Faturix - Base de dados completa';
COMMENT ON TABLE usuarios IS 'Usuários do sistema';
COMMENT ON TABLE produtos IS 'Catálogo de produtos';
COMMENT ON TABLE vendas IS 'Registro de vendas';
COMMENT ON TABLE mesas IS 'Mesas do restaurante';
COMMENT ON TABLE pedidos IS 'Pedidos de mesas';
COMMENT ON TABLE caixa IS 'Controle de abertura/fechamento de caixa';

-- =====================================================
-- 27. VERIFICAÇÃO FINAL
-- =====================================================
SELECT 'Base de dados criada com sucesso!' as mensagem;
SELECT 'Usuário Super Administrador: Código 0000' as usuario_padrao;

-- Mostrar estatísticas
SELECT
    'Perfis: ' || COUNT(*) as qtd FROM perfis_usuario
UNION ALL
SELECT 'Usuários: ' || COUNT(*) FROM usuarios
UNION ALL
SELECT 'Setores: ' || COUNT(*) FROM setores
UNION ALL
SELECT 'Áreas: ' || COUNT(*) FROM areas
UNION ALL
SELECT 'Famílias: ' || COUNT(*) FROM familias
UNION ALL
SELECT 'Produtos: ' || COUNT(*) FROM produtos
UNION ALL
SELECT 'Mesas: ' || COUNT(*) FROM mesas
UNION ALL
SELECT 'Formas Pagamento: ' || COUNT(*) FROM formas_pagamento;

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
