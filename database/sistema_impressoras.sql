-- ===================================
-- SISTEMA DE GESTÃO DE IMPRESSORAS
-- Descrição: Gerencia impressoras e mapeamento de documentos
-- Data: 2025
-- ===================================

-- ===================================
-- 1. TABELA: impressoras
-- Armazena as impressoras cadastradas no sistema
-- ===================================
CREATE TABLE IF NOT EXISTS impressoras (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    tipo VARCHAR(50) DEFAULT 'termica', -- termica, matricial, laser, etc
    descricao TEXT,
    largura_papel INTEGER DEFAULT 80, -- largura do papel em mm (58, 80, etc)
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 2. TABELA: tipos_documento
-- Define os tipos de documentos que podem ser impressos
-- ===================================
CREATE TABLE IF NOT EXISTS tipos_documento (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 3. TABELA: documento_impressora
-- Mapeia qual impressora usar para cada tipo de documento
-- ===================================
CREATE TABLE IF NOT EXISTS documento_impressora (
    id SERIAL PRIMARY KEY,
    tipo_documento_id INTEGER NOT NULL REFERENCES tipos_documento(id) ON DELETE CASCADE,
    impressora_id INTEGER NOT NULL REFERENCES impressoras(id) ON DELETE CASCADE,
    prioridade INTEGER DEFAULT 1, -- se houver múltiplas impressoras para o mesmo documento
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tipo_documento_id, impressora_id)
);

-- ===================================
-- 4. Modificar tabela areas para incluir impressora
-- Adiciona coluna de impressora padrão para cada área
-- ===================================
ALTER TABLE areas ADD COLUMN IF NOT EXISTS impressora_id INTEGER REFERENCES impressoras(id) ON DELETE SET NULL;

-- ===================================
-- DADOS INICIAIS
-- ===================================

-- Inserir tipos de documento padrão
INSERT INTO tipos_documento (codigo, nome, descricao) VALUES
    ('RECIBO_VENDA', 'Recibo de Venda', 'Recibo impresso ao finalizar venda'),
    ('CONTA_MESA', 'Conta da Mesa', 'Conta detalhada da mesa'),
    ('PEDIDO_COZINHA', 'Pedido para Cozinha', 'Pedido de itens da cozinha'),
    ('PEDIDO_BAR', 'Pedido para Bar', 'Pedido de bebidas do bar'),
    ('COTACAO', 'Cotação', 'Cotação de produtos'),
    ('FECHO_CAIXA', 'Fecho de Caixa', 'Relatório de fechamento de caixa')
ON CONFLICT (codigo) DO NOTHING;

-- ===================================
-- ÍNDICES
-- ===================================
CREATE INDEX IF NOT EXISTS idx_impressoras_ativo ON impressoras(ativo);
CREATE INDEX IF NOT EXISTS idx_tipos_documento_codigo ON tipos_documento(codigo);
CREATE INDEX IF NOT EXISTS idx_documento_impressora_tipo ON documento_impressora(tipo_documento_id);
CREATE INDEX IF NOT EXISTS idx_areas_impressora ON areas(impressora_id);

-- ===================================
-- TRIGGERS
-- ===================================

-- Trigger para atualizar updated_at na tabela impressoras
CREATE OR REPLACE FUNCTION atualizar_updated_at_impressoras()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_impressoras ON impressoras;
CREATE TRIGGER trigger_atualizar_impressoras
    BEFORE UPDATE ON impressoras
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_updated_at_impressoras();

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View para listar mapeamentos de documentos e impressoras
CREATE OR REPLACE VIEW vw_mapeamento_impressao AS
SELECT
    td.id as tipo_documento_id,
    td.codigo as documento_codigo,
    td.nome as documento_nome,
    i.id as impressora_id,
    i.nome as impressora_nome,
    i.tipo as impressora_tipo,
    di.prioridade
FROM tipos_documento td
LEFT JOIN documento_impressora di ON di.tipo_documento_id = td.id
LEFT JOIN impressoras i ON i.id = di.impressora_id
WHERE td.ativo = true
ORDER BY td.nome, di.prioridade;

-- View para listar áreas com suas impressoras
CREATE OR REPLACE VIEW vw_areas_impressoras AS
SELECT
    a.id as area_id,
    a.nome as area_nome,
    a.descricao as area_descricao,
    i.id as impressora_id,
    i.nome as impressora_nome,
    i.tipo as impressora_tipo
FROM areas a
LEFT JOIN impressoras i ON i.id = a.impressora_id
WHERE a.ativo = true
ORDER BY a.nome;

COMMENT ON TABLE impressoras IS 'Cadastro de impressoras do sistema';
COMMENT ON TABLE tipos_documento IS 'Tipos de documentos que podem ser impressos';
COMMENT ON TABLE documento_impressora IS 'Mapeamento de documentos para impressoras';
COMMENT ON COLUMN areas.impressora_id IS 'Impressora padrão para esta área';
