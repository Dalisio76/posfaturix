-- ===================================
-- Sistema de Gestão de Terminais
-- ===================================
-- Este script cria a estrutura para gerenciar múltiplos terminais em rede

-- 1. Criar tabela de terminais
CREATE TABLE IF NOT EXISTS terminais (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    ip_address VARCHAR(45), -- Suporta IPv4 e IPv6
    descricao TEXT,
    tipo VARCHAR(50) DEFAULT 'caixa', -- caixa, bar, cozinha, admin
    ativo BOOLEAN DEFAULT true,
    ultima_conexao TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Inserir terminais padrão
INSERT INTO terminais (nome, tipo, descricao) VALUES
    ('Servidor', 'servidor', 'Computador principal com PostgreSQL'),
    ('Caixa 1', 'caixa', 'Terminal de caixa principal'),
    ('Caixa 2', 'caixa', 'Terminal de caixa secundário'),
    ('Bar', 'bar', 'Terminal do bar'),
    ('Cozinha', 'cozinha', 'Terminal da cozinha')
ON CONFLICT (nome) DO NOTHING;

-- 3. Adicionar coluna terminal_id em tabelas importantes (se ainda não existir)

-- Vendas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vendas' AND column_name = 'terminal_id'
    ) THEN
        ALTER TABLE vendas ADD COLUMN terminal_id INTEGER REFERENCES terminais(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Usuarios (para saber qual terminal o usuário está usando)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'usuarios' AND column_name = 'terminal_id_atual'
    ) THEN
        ALTER TABLE usuarios ADD COLUMN terminal_id_atual INTEGER REFERENCES terminais(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 4. Criar tabela de logs de conexão
CREATE TABLE IF NOT EXISTS terminal_logs (
    id SERIAL PRIMARY KEY,
    terminal_id INTEGER REFERENCES terminais(id) ON DELETE CASCADE,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    ip_address VARCHAR(45),
    acao VARCHAR(50), -- 'login', 'logout', 'heartbeat'
    detalhes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Criar índices
CREATE INDEX IF NOT EXISTS idx_terminais_ativo ON terminais(ativo);
CREATE INDEX IF NOT EXISTS idx_terminais_tipo ON terminais(tipo);
CREATE INDEX IF NOT EXISTS idx_vendas_terminal ON vendas(terminal_id);
CREATE INDEX IF NOT EXISTS idx_terminal_logs_terminal ON terminal_logs(terminal_id);
CREATE INDEX IF NOT EXISTS idx_terminal_logs_created ON terminal_logs(created_at);

-- 6. Criar função para atualizar updated_at
CREATE OR REPLACE FUNCTION atualizar_updated_at_terminais()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_terminais ON terminais;
CREATE TRIGGER trigger_atualizar_terminais
    BEFORE UPDATE ON terminais
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_updated_at_terminais();

-- 7. Criar função para registrar conexão do terminal
CREATE OR REPLACE FUNCTION registrar_conexao_terminal(
    p_terminal_id INTEGER,
    p_usuario_id INTEGER DEFAULT NULL,
    p_ip_address VARCHAR(45) DEFAULT NULL,
    p_acao VARCHAR(50) DEFAULT 'heartbeat'
)
RETURNS VOID AS $$
BEGIN
    -- Atualizar última conexão
    UPDATE terminais
    SET ultima_conexao = CURRENT_TIMESTAMP,
        ip_address = COALESCE(p_ip_address, ip_address)
    WHERE id = p_terminal_id;

    -- Inserir log
    INSERT INTO terminal_logs (terminal_id, usuario_id, ip_address, acao)
    VALUES (p_terminal_id, p_usuario_id, p_ip_address, p_acao);
END;
$$ LANGUAGE plpgsql;

-- 8. Criar view de terminais ativos
CREATE OR REPLACE VIEW vw_terminais_ativos AS
SELECT
    t.id,
    t.nome,
    t.ip_address,
    t.tipo,
    t.descricao,
    t.ultima_conexao,
    CASE
        WHEN t.ultima_conexao IS NULL THEN 'Nunca Conectado'
        WHEN t.ultima_conexao > (CURRENT_TIMESTAMP - INTERVAL '5 minutes') THEN 'Online'
        WHEN t.ultima_conexao > (CURRENT_TIMESTAMP - INTERVAL '1 hour') THEN 'Inativo'
        ELSE 'Offline'
    END AS status_conexao,
    u.nome as usuario_atual,
    u.id as usuario_id
FROM terminais t
LEFT JOIN usuarios u ON u.terminal_id_atual = t.id
WHERE t.ativo = true
ORDER BY t.nome;

-- 9. Criar view de vendas por terminal
CREATE OR REPLACE VIEW vw_vendas_por_terminal AS
SELECT
    t.id as terminal_id,
    t.nome as terminal_nome,
    COUNT(v.id) as total_vendas,
    SUM(v.total) as valor_total,
    DATE(v.data_venda) as data
FROM terminais t
LEFT JOIN vendas v ON v.terminal_id = t.id
GROUP BY t.id, t.nome, DATE(v.data_venda)
ORDER BY data DESC, terminal_nome;

-- 10. Criar função para limpar logs antigos (manter últimos 30 dias)
CREATE OR REPLACE FUNCTION limpar_logs_terminais()
RETURNS INTEGER AS $$
DECLARE
    linhas_deletadas INTEGER;
BEGIN
    DELETE FROM terminal_logs
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '30 days');

    GET DIAGNOSTICS linhas_deletadas = ROW_COUNT;
    RETURN linhas_deletadas;
END;
$$ LANGUAGE plpgsql;

-- 11. Verificação final
SELECT 'Tabela terminais criada' as status, COUNT(*) as registros FROM terminais
UNION ALL
SELECT 'Tabela terminal_logs criada' as status, COUNT(*) as registros FROM terminal_logs;

-- 12. Mostrar terminais cadastrados
SELECT
    id,
    nome,
    tipo,
    ip_address,
    CASE
        WHEN ultima_conexao IS NULL THEN 'Nunca'
        ELSE TO_CHAR(ultima_conexao, 'DD/MM/YYYY HH24:MI')
    END as ultima_conexao,
    CASE WHEN ativo THEN 'Sim' ELSE 'Não' END as ativo
FROM terminais
ORDER BY id;

COMMIT;
