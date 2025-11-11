-- ===================================
-- SCHEMA - CLIENTES, DÍVIDAS E DESPESAS
-- Sistema completo de gestão de clientes e dívidas
-- ===================================

-- ===================================
-- TABELA: clientes
-- ===================================
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    contacto VARCHAR(50),
    contacto2 VARCHAR(50),
    email VARCHAR(100),
    endereco TEXT,
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    nuit VARCHAR(50),
    observacoes TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_clientes_nome ON clientes(nome);
CREATE INDEX idx_clientes_contacto ON clientes(contacto);
CREATE INDEX idx_clientes_ativo ON clientes(ativo);

-- Dados de exemplo
INSERT INTO clientes (nome, contacto, email, endereco, cidade) VALUES
('João Silva', '+258 84 111 2222', 'joao@email.com', 'Av. 25 de Setembro, 123', 'Maputo'),
('Maria Santos', '+258 82 333 4444', 'maria@email.com', 'Rua da Resistência, 456', 'Matola'),
('António Macamo', '+258 86 555 6666', 'antonio@email.com', 'Av. Julius Nyerere, 789', 'Maputo');

-- ===================================
-- TABELA: dividas
-- ===================================
CREATE TABLE dividas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    venda_id INTEGER UNIQUE REFERENCES vendas(id) ON DELETE CASCADE,
    valor_total DECIMAL(10,2) NOT NULL,
    valor_pago DECIMAL(10,2) DEFAULT 0,
    valor_restante DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDENTE', -- PENDENTE, PAGO, PARCIAL
    observacoes TEXT,
    data_divida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_vencimento TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_dividas_cliente ON dividas(cliente_id);
CREATE INDEX idx_dividas_status ON dividas(status);
CREATE INDEX idx_dividas_data ON dividas(data_divida);

-- ===================================
-- TABELA: pagamentos_divida
-- ===================================
CREATE TABLE pagamentos_divida (
    id SERIAL PRIMARY KEY,
    divida_id INTEGER NOT NULL REFERENCES dividas(id) ON DELETE CASCADE,
    valor DECIMAL(10,2) NOT NULL,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    usuario VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_pagamentos_divida ON pagamentos_divida(divida_id);
CREATE INDEX idx_pagamentos_data ON pagamentos_divida(data_pagamento);

-- ===================================
-- TABELA: despesas
-- ===================================
CREATE TABLE despesas (
    id SERIAL PRIMARY KEY,
    descricao TEXT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(100),
    data_despesa TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    observacoes TEXT,
    usuario VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_despesas_data ON despesas(data_despesa);
CREATE INDEX idx_despesas_categoria ON despesas(categoria);

-- Dados de exemplo
INSERT INTO despesas (descricao, valor, categoria) VALUES
('Compra de gás', 500.00, 'OPERACIONAL'),
('Conta de luz', 1200.00, 'UTILIDADES'),
('Salário funcionário', 8000.00, 'PESSOAL');

-- ===================================
-- ATUALIZAR TABELA VENDAS
-- Adicionar cliente_id e tipo_venda
-- ===================================
ALTER TABLE vendas ADD COLUMN cliente_id INTEGER REFERENCES clientes(id);
ALTER TABLE vendas ADD COLUMN tipo_venda VARCHAR(20) DEFAULT 'NORMAL'; -- NORMAL, DIVIDA

CREATE INDEX idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX idx_vendas_tipo ON vendas(tipo_venda);

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View: Clientes com total de dívidas
CREATE VIEW v_clientes_dividas AS
SELECT
    c.id,
    c.nome,
    c.contacto,
    c.email,
    COUNT(d.id) as total_dividas,
    SUM(d.valor_restante) as total_devendo,
    MAX(d.data_divida) as ultima_divida
FROM clientes c
LEFT JOIN dividas d ON c.id = d.cliente_id AND d.status != 'PAGO'
GROUP BY c.id, c.nome, c.contacto, c.email;

-- View: Dívidas completas (com nome do cliente)
CREATE VIEW v_dividas_completo AS
SELECT
    d.*,
    c.nome as cliente_nome,
    c.contacto as cliente_contacto,
    v.numero as venda_numero,
    v.data_venda
FROM dividas d
INNER JOIN clientes c ON d.cliente_id = c.id
LEFT JOIN vendas v ON d.venda_id = v.id;

-- View: Resumo de despesas
CREATE VIEW v_despesas_resumo AS
SELECT
    categoria,
    COUNT(*) as total_despesas,
    SUM(valor) as total_valor,
    DATE(data_despesa) as data
FROM despesas
GROUP BY categoria, DATE(data_despesa)
ORDER BY data DESC;

-- View: Devedores (clientes com dívidas pendentes)
CREATE VIEW v_devedores AS
SELECT
    c.id,
    c.nome,
    c.contacto,
    c.email,
    COUNT(DISTINCT d.id) as qtd_dividas,
    SUM(d.valor_restante) as total_devendo,
    MIN(d.data_divida) as divida_mais_antiga,
    MAX(d.data_divida) as divida_mais_recente
FROM clientes c
INNER JOIN dividas d ON c.id = d.cliente_id
WHERE d.status != 'PAGO'
GROUP BY c.id, c.nome, c.contacto, c.email
HAVING SUM(d.valor_restante) > 0
ORDER BY total_devendo DESC;

-- ===================================
-- TRIGGER: Atualizar valor_restante automaticamente
-- ===================================
CREATE OR REPLACE FUNCTION atualizar_valor_restante()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar valor_restante
    NEW.valor_restante := NEW.valor_total - NEW.valor_pago;

    -- Atualizar status
    IF NEW.valor_pago = 0 THEN
        NEW.status := 'PENDENTE';
    ELSIF NEW.valor_pago >= NEW.valor_total THEN
        NEW.status := 'PAGO';
    ELSE
        NEW.status := 'PARCIAL';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_valor_restante
BEFORE INSERT OR UPDATE ON dividas
FOR EACH ROW
EXECUTE FUNCTION atualizar_valor_restante();

-- ===================================
-- FUNCTION: Registrar pagamento de dívida
-- ===================================
CREATE OR REPLACE FUNCTION registrar_pagamento_divida(
    p_divida_id INTEGER,
    p_valor DECIMAL(10,2),
    p_forma_pagamento_id INTEGER,
    p_observacoes TEXT DEFAULT NULL,
    p_usuario VARCHAR(100) DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_valor_restante DECIMAL(10,2);
BEGIN
    -- Buscar valor restante
    SELECT valor_restante INTO v_valor_restante
    FROM dividas
    WHERE id = p_divida_id;

    -- Validar se dívida existe
    IF v_valor_restante IS NULL THEN
        RAISE EXCEPTION 'Dívida não encontrada';
    END IF;

    -- Validar se valor não excede restante
    IF p_valor > v_valor_restante THEN
        RAISE EXCEPTION 'Valor excede o restante da dívida';
    END IF;

    -- Inserir pagamento
    INSERT INTO pagamentos_divida (divida_id, valor, forma_pagamento_id, observacoes, usuario)
    VALUES (p_divida_id, p_valor, p_forma_pagamento_id, p_observacoes, p_usuario);

    -- Atualizar valor_pago na dívida
    UPDATE dividas
    SET valor_pago = valor_pago + p_valor
    WHERE id = p_divida_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- COMENTÁRIOS NAS TABELAS
-- ===================================
COMMENT ON TABLE clientes IS 'Cadastro de clientes';
COMMENT ON TABLE dividas IS 'Registro de dívidas de clientes';
COMMENT ON TABLE pagamentos_divida IS 'Histórico de pagamentos de dívidas';
COMMENT ON TABLE despesas IS 'Registro de despesas do estabelecimento';

COMMENT ON COLUMN dividas.status IS 'PENDENTE: Não pagou nada, PARCIAL: Pagou parte, PAGO: Quitado';
COMMENT ON COLUMN vendas.tipo_venda IS 'NORMAL: Venda comum, DIVIDA: Venda a crédito';
