-- ===================================
-- SISTEMA DE MESAS E PEDIDOS
-- Descrição: Sistema completo para gerenciar mesas e pedidos
-- Data: 2025
-- ===================================

-- ===================================
-- 1. TABELA: locais_mesa
-- Armazena os locais onde as mesas estão (BALCAO, SALA, ESPLANADA)
-- ===================================
CREATE TABLE IF NOT EXISTS locais_mesa (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT,
    ordem INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 2. TABELA: mesas
-- Armazena as mesas do restaurante
-- ===================================
CREATE TABLE IF NOT EXISTS mesas (
    id SERIAL PRIMARY KEY,
    numero INTEGER NOT NULL UNIQUE,
    local_id INTEGER NOT NULL REFERENCES locais_mesa(id) ON DELETE RESTRICT,
    capacidade INTEGER DEFAULT 4,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 3. TABELA: pedidos
-- Armazena os pedidos nas mesas
-- ===================================
CREATE TABLE IF NOT EXISTS pedidos (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    mesa_id INTEGER NOT NULL REFERENCES mesas(id) ON DELETE RESTRICT,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'aberto', -- aberto, fechado, cancelado
    total DECIMAL(10,2) DEFAULT 0,
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fechamento TIMESTAMP,
    observacoes TEXT,
    CONSTRAINT check_status CHECK (status IN ('aberto', 'fechado', 'cancelado'))
);

-- ===================================
-- 4. TABELA: itens_pedido
-- Armazena os itens de cada pedido
-- ===================================
CREATE TABLE IF NOT EXISTS itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE RESTRICT,
    produto_nome VARCHAR(200) NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 5. ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_mesas_local ON mesas(local_id);
CREATE INDEX IF NOT EXISTS idx_mesas_numero ON mesas(numero);
CREATE INDEX IF NOT EXISTS idx_pedidos_mesa ON pedidos(mesa_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_status ON pedidos(status);
CREATE INDEX IF NOT EXISTS idx_itens_pedido_pedido ON itens_pedido(pedido_id);

-- ===================================
-- 6. INSERIR LOCAIS PADRÃO
-- ===================================
INSERT INTO locais_mesa (nome, descricao, ordem) VALUES
('BALCAO', 'Mesas do balcão', 1),
('SALA', 'Mesas da sala principal', 2),
('ESPLANADA', 'Mesas da esplanada', 3)
ON CONFLICT (nome) DO NOTHING;

-- ===================================
-- 7. VIEWS AUXILIARES
-- ===================================

-- View: Mesas com informações completas
CREATE OR REPLACE VIEW v_mesas_completo AS
SELECT
    m.id,
    m.numero,
    m.local_id,
    l.nome as local_nome,
    m.capacidade,
    m.ativo,
    -- Pedido aberto (se houver)
    p.id as pedido_id,
    p.numero as pedido_numero,
    p.usuario_id,
    u.nome as usuario_nome,
    p.total as pedido_total,
    p.data_abertura,
    -- Status da mesa
    CASE
        WHEN p.id IS NOT NULL THEN 'ocupada'
        WHEN m.ativo = false THEN 'inativa'
        ELSE 'livre'
    END as status
FROM mesas m
LEFT JOIN locais_mesa l ON m.local_id = l.id
LEFT JOIN pedidos p ON m.id = p.mesa_id AND p.status = 'aberto'
LEFT JOIN usuarios u ON p.usuario_id = u.id
ORDER BY m.numero;

-- View: Pedidos abertos com detalhes
CREATE OR REPLACE VIEW v_pedidos_abertos AS
SELECT
    p.id,
    p.numero,
    p.mesa_id,
    m.numero as mesa_numero,
    l.nome as local_nome,
    p.usuario_id,
    u.nome as usuario_nome,
    p.total,
    p.data_abertura,
    p.observacoes,
    COUNT(ip.id) as total_itens
FROM pedidos p
INNER JOIN mesas m ON p.mesa_id = m.id
INNER JOIN locais_mesa l ON m.local_id = l.id
INNER JOIN usuarios u ON p.usuario_id = u.id
LEFT JOIN itens_pedido ip ON p.id = ip.pedido_id
WHERE p.status = 'aberto'
GROUP BY p.id, p.numero, p.mesa_id, m.numero, l.nome, p.usuario_id, u.nome, p.total, p.data_abertura, p.observacoes
ORDER BY p.data_abertura DESC;

-- View: Resumo de mesas por local
CREATE OR REPLACE VIEW v_mesas_por_local AS
SELECT
    l.id as local_id,
    l.nome as local_nome,
    COUNT(m.id) as total_mesas,
    COUNT(CASE WHEN m.ativo THEN 1 END) as mesas_ativas,
    COUNT(p.id) as mesas_ocupadas,
    COUNT(CASE WHEN m.ativo AND p.id IS NULL THEN 1 END) as mesas_livres
FROM locais_mesa l
LEFT JOIN mesas m ON l.id = m.local_id
LEFT JOIN pedidos p ON m.id = p.mesa_id AND p.status = 'aberto'
GROUP BY l.id, l.nome
ORDER BY l.ordem;

-- ===================================
-- 8. FUNÇÃO: Calcular total do pedido
-- ===================================
CREATE OR REPLACE FUNCTION calcular_total_pedido(p_pedido_id INTEGER)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_total DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_total
    FROM itens_pedido
    WHERE pedido_id = p_pedido_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 9. TRIGGER: Atualizar total do pedido
-- ===================================
CREATE OR REPLACE FUNCTION atualizar_total_pedido()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pedidos
    SET total = calcular_total_pedido(
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.pedido_id
            ELSE NEW.pedido_id
        END
    )
    WHERE id = CASE
        WHEN TG_OP = 'DELETE' THEN OLD.pedido_id
        ELSE NEW.pedido_id
    END;

    RETURN CASE
        WHEN TG_OP = 'DELETE' THEN OLD
        ELSE NEW
    END;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_total_pedido ON itens_pedido;
CREATE TRIGGER trigger_atualizar_total_pedido
AFTER INSERT OR UPDATE OR DELETE ON itens_pedido
FOR EACH ROW
EXECUTE FUNCTION atualizar_total_pedido();

-- ===================================
-- 10. COMENTÁRIOS
-- ===================================
COMMENT ON TABLE locais_mesa IS 'Locais onde as mesas estão localizadas (BALCAO, SALA, ESPLANADA)';
COMMENT ON TABLE mesas IS 'Mesas do restaurante';
COMMENT ON TABLE pedidos IS 'Pedidos realizados nas mesas';
COMMENT ON TABLE itens_pedido IS 'Itens de cada pedido';

COMMENT ON COLUMN pedidos.status IS 'Status: aberto, fechado, cancelado';
COMMENT ON COLUMN pedidos.usuario_id IS 'Usuário responsável pelo pedido';

-- ===================================
-- FIM DO SCRIPT
-- ===================================
