-- ===================================
-- Adicionar suporte a impressoras de rede
-- ===================================

-- Adicionar coluna caminho_rede na tabela impressoras
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'impressoras' AND column_name = 'caminho_rede'
    ) THEN
        ALTER TABLE impressoras ADD COLUMN caminho_rede VARCHAR(255);
    END IF;
END $$;

-- Comentário explicativo
COMMENT ON COLUMN impressoras.caminho_rede IS 'Caminho de rede para impressora compartilhada (ex: \\ComputadorX\ImpressoraCozinha)';

-- Recriar view de mapeamento para incluir caminho de rede
DROP VIEW IF EXISTS vw_mapeamento_impressao;
CREATE VIEW vw_mapeamento_impressao AS
SELECT
    td.id as tipo_documento_id,
    td.codigo as documento_codigo,
    td.nome as documento_nome,
    i.id as impressora_id,
    i.nome as impressora_nome,
    i.tipo as impressora_tipo,
    i.caminho_rede as impressora_caminho_rede,
    di.prioridade
FROM tipos_documento td
LEFT JOIN documento_impressora di ON di.tipo_documento_id = td.id
LEFT JOIN impressoras i ON i.id = di.impressora_id
WHERE td.ativo = true
ORDER BY td.nome, di.prioridade;

-- Recriar view de areas para incluir caminho de rede
DROP VIEW IF EXISTS vw_areas_impressoras;
CREATE VIEW vw_areas_impressoras AS
SELECT
    a.id as area_id,
    a.nome as area_nome,
    a.descricao as area_descricao,
    i.id as impressora_id,
    i.nome as impressora_nome,
    i.tipo as impressora_tipo,
    i.caminho_rede as impressora_caminho_rede
FROM areas a
LEFT JOIN impressoras i ON i.id = a.impressora_id
WHERE a.ativo = true
ORDER BY a.nome;

COMMIT;
