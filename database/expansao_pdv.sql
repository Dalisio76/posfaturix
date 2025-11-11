-- ===================================
-- SCRIPT DE EXPANSÃO DO SISTEMA PDV
-- Execute este script no PostgreSQL
-- ===================================

-- ===================================
-- TABELA: empresa (dados da empresa)
-- ===================================
CREATE TABLE IF NOT EXISTS empresa (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nuit VARCHAR(50),
    endereco TEXT,
    cidade VARCHAR(100),
    email VARCHAR(100),
    contacto VARCHAR(50),
    logo_url TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados padrão da empresa
INSERT INTO empresa (nome, nuit, endereco, cidade, email, contacto) VALUES
('FRENTEX E SERVICOS', '123456789', 'Av. Julius Nyerere, Maputo', 'Maputo', 'contato@frentex.co.mz', '+258 84 123 4567')
ON CONFLICT DO NOTHING;

-- ===================================
-- TABELA: formas_pagamento
-- ===================================
CREATE TABLE IF NOT EXISTS formas_pagamento (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(200),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir formas de pagamento padrão
INSERT INTO formas_pagamento (nome, descricao) VALUES
('CASH', 'Pagamento em dinheiro'),
('EMOLA', 'Pagamento via eMola'),
('MPESA', 'Pagamento via M-Pesa'),
('POS', 'Pagamento via POS/Cartão')
ON CONFLICT (nome) DO NOTHING;

-- ===================================
-- TABELA: setores
-- ===================================
CREATE TABLE IF NOT EXISTS setores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dados de exemplo
INSERT INTO setores (nome, descricao) VALUES
('RESTAURANTE', 'Setor de preparação de alimentos'),
('ARMAZEM', 'Setor de bebidas'),
('ARMAZEM 2', 'Setor de atendimento e vendas')
ON CONFLICT DO NOTHING;

-- ===================================
-- TABELA: areas
-- ===================================
CREATE TABLE IF NOT EXISTS areas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dados de exemplo
INSERT INTO areas (nome, descricao) VALUES
('BAR', 'Área principal do restaurante'),
('COZINHA', 'Área externa com vista'),
('GERAL', 'Área reservada para clientes especiais')
ON CONFLICT DO NOTHING;

-- ===================================
-- ATUALIZAR TABELA VENDAS
-- Adicionar forma de pagamento
-- ===================================
ALTER TABLE vendas ADD COLUMN IF NOT EXISTS forma_pagamento_id INTEGER REFERENCES formas_pagamento(id);

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View: Vendas com forma de pagamento
CREATE OR REPLACE VIEW v_vendas_completo AS
SELECT
    v.*,
    fp.nome as forma_pagamento_nome
FROM vendas v
LEFT JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id;

-- View: Setores ativos
CREATE OR REPLACE VIEW v_setores_ativos AS
SELECT * FROM setores WHERE ativo = true ORDER BY nome;

-- View: Áreas ativas
CREATE OR REPLACE VIEW v_areas_ativas AS
SELECT * FROM areas WHERE ativo = true ORDER BY nome;

-- ===================================
-- ÍNDICES
-- ===================================
CREATE INDEX IF NOT EXISTS idx_vendas_forma_pagamento ON vendas(forma_pagamento_id);
CREATE INDEX IF NOT EXISTS idx_setores_ativo ON setores(ativo);
CREATE INDEX IF NOT EXISTS idx_areas_ativo ON areas(ativo);

-- ===================================
-- VERIFICAÇÃO
-- ===================================
-- Executar para verificar se tudo foi criado:
-- SELECT * FROM empresa;
-- SELECT * FROM formas_pagamento;
-- SELECT * FROM setores;
-- SELECT * FROM areas;
