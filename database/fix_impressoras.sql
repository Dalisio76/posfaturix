-- ===================================
-- SCRIPT DE CORREÇÃO/INSTALAÇÃO
-- Sistema de Impressoras
-- ===================================

-- 1. Criar tabela impressoras se não existir
CREATE TABLE IF NOT EXISTS impressoras (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    tipo VARCHAR(50) DEFAULT 'termica',
    descricao TEXT,
    largura_papel INTEGER DEFAULT 80,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Criar tabela tipos_documento se não existir
CREATE TABLE IF NOT EXISTS tipos_documento (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Criar tabela documento_impressora se não existir
CREATE TABLE IF NOT EXISTS documento_impressora (
    id SERIAL PRIMARY KEY,
    tipo_documento_id INTEGER NOT NULL REFERENCES tipos_documento(id) ON DELETE CASCADE,
    impressora_id INTEGER NOT NULL REFERENCES impressoras(id) ON DELETE CASCADE,
    prioridade INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_documento_impressora UNIQUE(tipo_documento_id, impressora_id)
);

-- 4. Adicionar coluna impressora_id em areas (se não existir)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'areas' AND column_name = 'impressora_id'
    ) THEN
        ALTER TABLE areas ADD COLUMN impressora_id INTEGER REFERENCES impressoras(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 5. Inserir tipos de documento padrão (se não existirem)
INSERT INTO tipos_documento (codigo, nome, descricao) VALUES
    ('RECIBO_VENDA', 'Recibo de Venda', 'Recibo impresso ao finalizar venda'),
    ('CONTA_MESA', 'Conta da Mesa', 'Conta detalhada da mesa'),
    ('PEDIDO_COZINHA', 'Pedido para Cozinha', 'Pedido de itens da cozinha'),
    ('PEDIDO_BAR', 'Pedido para Bar', 'Pedido de bebidas do bar'),
    ('COTACAO', 'Cotação', 'Cotação de produtos'),
    ('FECHO_CAIXA', 'Fecho de Caixa', 'Relatório de fechamento de caixa')
ON CONFLICT (codigo) DO NOTHING;

-- 6. Criar índices se não existirem
CREATE INDEX IF NOT EXISTS idx_impressoras_ativo ON impressoras(ativo);
CREATE INDEX IF NOT EXISTS idx_tipos_documento_codigo ON tipos_documento(codigo);
CREATE INDEX IF NOT EXISTS idx_documento_impressora_tipo ON documento_impressora(tipo_documento_id);
CREATE INDEX IF NOT EXISTS idx_areas_impressora ON areas(impressora_id);

-- 7. Criar ou substituir trigger de updated_at
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

-- 8. Criar ou substituir views
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

-- 9. Verificação final
SELECT 'Tabela impressoras criada' as status,
       COUNT(*) as registros
FROM impressoras
UNION ALL
SELECT 'Tabela tipos_documento criada' as status,
       COUNT(*) as registros
FROM tipos_documento
UNION ALL
SELECT 'Tabela documento_impressora criada' as status,
       COUNT(*) as registros
FROM documento_impressora;

-- Verificar se coluna foi adicionada em areas
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'areas' AND column_name = 'impressora_id'
        ) THEN 'Coluna impressora_id em areas: OK'
        ELSE 'Coluna impressora_id em areas: FALTA'
    END as status;

COMMIT;
