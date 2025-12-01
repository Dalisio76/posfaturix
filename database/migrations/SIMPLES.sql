-- =====================================================
-- MIGRAÇÃO SUPER SIMPLES - USE ESTE SE AINDA DER ERRO
-- =====================================================
-- Copie TUDO e cole no pgAdmin Query Tool
-- Pressione F5
-- =====================================================

-- Limpar transação (se houve erro anterior)
ROLLBACK;

-- Começar transação nova
BEGIN;

-- Adicionar colunas (cada uma ignora se já existe)
DO $$ BEGIN
    ALTER TABLE vendas ADD COLUMN status VARCHAR(20) DEFAULT 'finalizada';
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE vendas ADD COLUMN cliente_id INTEGER;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE vendas ADD COLUMN usuario_id INTEGER;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE vendas ADD COLUMN observacoes TEXT;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- Atualizar vendas existentes
UPDATE vendas SET status = 'finalizada' WHERE status IS NULL OR status = '';

-- Adicionar constraint (ignora se já existe)
DO $$ BEGIN
    ALTER TABLE vendas ADD CONSTRAINT chk_vendas_status
        CHECK (status IN ('finalizada', 'cancelada'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Criar índices (ignora se já existem)
CREATE INDEX IF NOT EXISTS idx_vendas_status ON vendas(status);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario ON vendas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas(data_venda);

-- Confirmar tudo
COMMIT;

-- Mostrar resultado
SELECT 'SUCESSO! Migração aplicada.' AS resultado;

-- Verificar colunas criadas
SELECT
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_name = 'vendas'
  AND column_name IN ('status', 'cliente_id', 'usuario_id', 'observacoes')
ORDER BY column_name;
