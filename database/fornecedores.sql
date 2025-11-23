-- ===================================
-- TABELA: Fornecedores
-- Gestão de fornecedores
-- ===================================

-- Criar tabela fornecedores
CREATE TABLE IF NOT EXISTS fornecedores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nif VARCHAR(20),
    email VARCHAR(100),
    telefone VARCHAR(20),
    morada TEXT,
    cidade VARCHAR(100),
    codigo_postal VARCHAR(20),
    pais VARCHAR(100) DEFAULT 'Portugal',
    contacto VARCHAR(200),
    observacoes TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criar índices
CREATE INDEX IF NOT EXISTS idx_fornecedores_nome ON fornecedores(nome);
CREATE INDEX IF NOT EXISTS idx_fornecedores_nif ON fornecedores(nif);
CREATE INDEX IF NOT EXISTS idx_fornecedores_ativo ON fornecedores(ativo);

-- Comentários
COMMENT ON TABLE fornecedores IS 'Cadastro de fornecedores';
COMMENT ON COLUMN fornecedores.nome IS 'Nome do fornecedor';
COMMENT ON COLUMN fornecedores.nif IS 'Número de Identificação Fiscal';
COMMENT ON COLUMN fornecedores.email IS 'Email de contacto';
COMMENT ON COLUMN fornecedores.telefone IS 'Telefone de contacto';
COMMENT ON COLUMN fornecedores.morada IS 'Morada completa';
COMMENT ON COLUMN fornecedores.cidade IS 'Cidade';
COMMENT ON COLUMN fornecedores.codigo_postal IS 'Código postal';
COMMENT ON COLUMN fornecedores.pais IS 'País';
COMMENT ON COLUMN fornecedores.contacto IS 'Nome da pessoa de contacto';
COMMENT ON COLUMN fornecedores.observacoes IS 'Observações gerais';
COMMENT ON COLUMN fornecedores.ativo IS 'Indica se o fornecedor está ativo';

-- Dados de exemplo (opcional)
INSERT INTO fornecedores (nome, nif, email, telefone, cidade, pais) VALUES
('Fornecedor Exemplo Lda', '123456789', 'contato@exemplo.pt', '912345678', 'Lisboa', 'Portugal')
ON CONFLICT DO NOTHING;

-- Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'fornecedores'
ORDER BY ordinal_position;
