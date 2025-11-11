-- ===================================
-- SCHEMA PDV SYSTEM
-- ===================================

-- TABELA: familias (categorias de produtos)
CREATE TABLE familias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: produtos
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nome VARCHAR(200) NOT NULL,
    familia_id INTEGER REFERENCES familias(id) ON DELETE SET NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: vendas
CREATE TABLE vendas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    terminal VARCHAR(50)
);

-- TABELA: itens_venda
CREATE TABLE itens_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);

-- ÍNDICES para performance
CREATE INDEX idx_produtos_familia ON produtos(familia_id);
CREATE INDEX idx_produtos_ativo ON produtos(ativo);
CREATE INDEX idx_vendas_data ON vendas(data_venda);
CREATE INDEX idx_itens_venda ON itens_venda(venda_id);

-- ===================================
-- DADOS DE TESTE
-- ===================================

INSERT INTO familias (nome, descricao) VALUES
('BEBIDAS', 'Bebidas em geral'),
('COMIDAS', 'Pratos e lanches'),
('SOBREMESAS', 'Doces e sobremesas');

INSERT INTO produtos (codigo, nome, familia_id, preco, estoque) VALUES
('001', 'COCA-COLA 500ML', 1, 50.00, 100),
('002', 'CERVEJA 2M', 1, 80.00, 50),
('003', 'AGUA MINERAL', 1, 30.00, 200),
('004', 'HAMBURGUER', 2, 150.00, 30),
('005', 'PIZZA MARGHERITA', 2, 200.00, 20),
('006', 'FRANGO ASSADO', 2, 180.00, 25),
('007', 'PUDIM', 3, 60.00, 25),
('008', 'SORVETE', 3, 70.00, 40);

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View: Produtos com nome da família
CREATE VIEW v_produtos_completo AS
SELECT
    p.*,
    f.nome as familia_nome
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id;

-- View: Resumo de vendas
CREATE VIEW v_vendas_resumo AS
SELECT
    v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    COUNT(iv.id) as total_itens
FROM vendas v
LEFT JOIN itens_venda iv ON v.id = iv.venda_id
GROUP BY v.id, v.numero, v.total, v.data_venda, v.terminal;
