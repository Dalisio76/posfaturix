-- ===================================
-- TABELA DE CONFIGURAÇÕES DO SISTEMA
-- Descrição: Armazena configurações globais do sistema
-- Data: 2025
-- ===================================

-- ===================================
-- TABELA: configuracoes
-- ===================================
CREATE TABLE IF NOT EXISTS configuracoes (
    id SERIAL PRIMARY KEY,
    chave VARCHAR(100) UNIQUE NOT NULL,
    valor TEXT,
    tipo VARCHAR(20) NOT NULL DEFAULT 'string', -- string, boolean, integer, decimal
    descricao TEXT,
    categoria VARCHAR(50), -- vendas, seguranca, sistema, etc
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- ÍNDICES
-- ===================================
CREATE INDEX IF NOT EXISTS idx_configuracoes_chave ON configuracoes(chave);
CREATE INDEX IF NOT EXISTS idx_configuracoes_categoria ON configuracoes(categoria);

-- ===================================
-- INSERIR CONFIGURAÇÕES PADRÃO
-- ===================================

-- Configuração: Timeout de inatividade em vendas
INSERT INTO configuracoes (chave, valor, tipo, descricao, categoria)
VALUES (
    'vendas_timeout_ativo',
    'true',
    'boolean',
    'Ativa timeout de inatividade na tela de vendas (volta para login após período sem atividade)',
    'seguranca'
) ON CONFLICT (chave) DO NOTHING;

INSERT INTO configuracoes (chave, valor, tipo, descricao, categoria)
VALUES (
    'vendas_timeout_segundos',
    '30',
    'integer',
    'Tempo em segundos de inatividade antes de voltar para login',
    'seguranca'
) ON CONFLICT (chave) DO NOTHING;

-- Configuração: Mostrar botão de pedidos/mesas
INSERT INTO configuracoes (chave, valor, tipo, descricao, categoria)
VALUES (
    'vendas_mostrar_pedidos',
    'true',
    'boolean',
    'Mostrar botão de pedidos/mesas na tela de vendas (desativar para supermercados sem mesas)',
    'vendas'
) ON CONFLICT (chave) DO NOTHING;

-- Configuração: Tema do sistema
INSERT INTO configuracoes (chave, valor, tipo, descricao, categoria)
VALUES (
    'sistema_tema',
    'light',
    'string',
    'Tema do sistema: light ou dark',
    'sistema'
) ON CONFLICT (chave) DO NOTHING;

-- ===================================
-- TRIGGER: Atualizar data_atualizacao
-- ===================================
CREATE OR REPLACE FUNCTION atualizar_data_configuracao()
RETURNS TRIGGER AS $$
BEGIN
    NEW.data_atualizacao = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_data_configuracao ON configuracoes;
CREATE TRIGGER trigger_atualizar_data_configuracao
    BEFORE UPDATE ON configuracoes
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_data_configuracao();

-- ===================================
-- COMENTÁRIOS
-- ===================================
COMMENT ON TABLE configuracoes IS 'Armazena configurações globais do sistema';
COMMENT ON COLUMN configuracoes.chave IS 'Chave única da configuração';
COMMENT ON COLUMN configuracoes.valor IS 'Valor da configuração (armazenado como texto)';
COMMENT ON COLUMN configuracoes.tipo IS 'Tipo do valor: string, boolean, integer, decimal';
COMMENT ON COLUMN configuracoes.descricao IS 'Descrição da configuração';
COMMENT ON COLUMN configuracoes.categoria IS 'Categoria da configuração: vendas, seguranca, sistema, etc';
