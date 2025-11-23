-- ===================================
-- TABELA: Acertos de Stock (Versão Simples)
-- Execute este script se tiver problemas com o script completo
-- ===================================

-- Criar tabela acertos_stock (versão simples, sem colunas computadas)
CREATE TABLE IF NOT EXISTS acertos_stock (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    estoque_anterior INTEGER NOT NULL,
    estoque_novo INTEGER NOT NULL,
    motivo VARCHAR(100) NOT NULL,
    observacao TEXT,
    setor_id INTEGER REFERENCES setores(id),
    area_id INTEGER REFERENCES areas(id),
    usuario VARCHAR(100),
    data TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criar índices
CREATE INDEX IF NOT EXISTS idx_acertos_produto ON acertos_stock(produto_id);
CREATE INDEX IF NOT EXISTS idx_acertos_data ON acertos_stock(data);
CREATE INDEX IF NOT EXISTS idx_acertos_setor ON acertos_stock(setor_id);
CREATE INDEX IF NOT EXISTS idx_acertos_area ON acertos_stock(area_id);

-- Verificar se a tabela foi criada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'acertos_stock'
ORDER BY ordinal_position;
