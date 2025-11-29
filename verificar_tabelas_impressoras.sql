-- Verificar se as tabelas foram criadas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('impressoras', 'tipos_documento', 'documento_impressora');

-- Verificar se a coluna impressora_id foi adicionada em areas
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'areas'
AND column_name = 'impressora_id';

-- Verificar tipos de documento criados
SELECT * FROM tipos_documento;

-- Verificar impressoras cadastradas
SELECT * FROM impressoras;
