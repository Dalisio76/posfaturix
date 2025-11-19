-- ===================================
-- MIGRAÇÃO: Adicionar Setor e Área aos Produtos
-- Permite associar cada produto a um setor e área específicos
-- ===================================

-- ===================================
-- 1. ADICIONAR COLUNAS À TABELA PRODUTOS
-- ===================================

-- Adicionar coluna setor_id
ALTER TABLE produtos
ADD COLUMN IF NOT EXISTS setor_id INTEGER REFERENCES setores(id);

-- Adicionar coluna area_id
ALTER TABLE produtos
ADD COLUMN IF NOT EXISTS area_id INTEGER REFERENCES areas(id);

-- ===================================
-- 2. CRIAR ÍNDICES PARA PERFORMANCE
-- ===================================

CREATE INDEX IF NOT EXISTS idx_produtos_setor ON produtos(setor_id);
CREATE INDEX IF NOT EXISTS idx_produtos_area ON produtos(area_id);

-- ===================================
-- 3. ATUALIZAR PRODUTOS EXISTENTES
-- Define valores padrão para produtos já cadastrados
-- ===================================

-- Opção 1: Definir setor RESTAURANTE (id=1) para todos os produtos existentes
UPDATE produtos
SET setor_id = 1  -- 1 = RESTAURANTE
WHERE setor_id IS NULL;

-- Opção 2: Definir área BAR (id=1) para todos os produtos existentes
UPDATE produtos
SET area_id = 1  -- 1 = BAR (ajuste conforme necessário)
WHERE area_id IS NULL;

-- ===================================
-- 4. ATUALIZAR VIEW DE PRODUTOS
-- Incluir informações de setor e área
-- ===================================

-- Recriar view v_produtos_completo com setor e área
DROP VIEW IF EXISTS v_produtos_completo CASCADE;

CREATE OR REPLACE VIEW v_produtos_completo AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.familia_id,
    p.preco,
    p.estoque,
    p.ativo,
    p.created_at,
    p.updated_at,
    p.setor_id,
    p.area_id,
    f.nome as familia_nome,
    s.nome as setor_nome,
    a.nome as area_nome
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id;

-- ===================================
-- 5. CRIAR VIEWS ÚTEIS
-- ===================================

-- View: Produtos por setor
CREATE OR REPLACE VIEW v_produtos_por_setor AS
SELECT
    s.id as setor_id,
    s.nome as setor_nome,
    COUNT(p.id) as total_produtos,
    SUM(p.estoque) as total_estoque,
    SUM(p.preco * p.estoque) as valor_total_estoque
FROM setores s
LEFT JOIN produtos p ON s.id = p.setor_id AND p.ativo = true
GROUP BY s.id, s.nome
ORDER BY s.nome;

-- View: Produtos por área
CREATE OR REPLACE VIEW v_produtos_por_area AS
SELECT
    a.id as area_id,
    a.nome as area_nome,
    COUNT(p.id) as total_produtos,
    SUM(p.estoque) as total_estoque,
    SUM(p.preco * p.estoque) as valor_total_estoque
FROM areas a
LEFT JOIN produtos p ON a.id = p.area_id AND p.ativo = true
GROUP BY a.id, a.nome
ORDER BY a.nome;

-- View: Produtos com todas as informações
CREATE OR REPLACE VIEW v_produtos_detalhado AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.preco,
    p.estoque,
    p.ativo,
    f.nome as familia,
    s.nome as setor,
    a.nome as area,
    p.created_at,
    p.updated_at
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id
WHERE p.ativo = true
ORDER BY p.nome;

-- ===================================
-- 6. FUNÇÕES ÚTEIS
-- ===================================

-- Função: Buscar produtos por setor
CREATE OR REPLACE FUNCTION get_produtos_por_setor(p_setor_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    codigo VARCHAR(50),
    nome VARCHAR(200),
    preco DECIMAL(10,2),
    estoque INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.codigo, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.setor_id = p_setor_id
    AND p.ativo = true
    ORDER BY p.nome;
END;
$$ LANGUAGE plpgsql;

-- Função: Buscar produtos por área
CREATE OR REPLACE FUNCTION get_produtos_por_area(p_area_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    codigo VARCHAR(50),
    nome VARCHAR(200),
    preco DECIMAL(10,2),
    estoque INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.codigo, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.area_id = p_area_id
    AND p.ativo = true
    ORDER BY p.nome;
END;
$$ LANGUAGE plpgsql;

-- Função: Buscar produtos por setor e área
CREATE OR REPLACE FUNCTION get_produtos_por_setor_e_area(p_setor_id INTEGER, p_area_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    codigo VARCHAR(50),
    nome VARCHAR(200),
    preco DECIMAL(10,2),
    estoque INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.codigo, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.setor_id = p_setor_id
    AND p.area_id = p_area_id
    AND p.ativo = true
    ORDER BY p.nome;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 7. VERIFICAÇÃO
-- ===================================

-- Ver estrutura da tabela produtos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;

-- Ver produtos com setor e área
SELECT * FROM v_produtos_completo
LIMIT 10;

-- Ver resumo por setor
SELECT * FROM v_produtos_por_setor;

-- Ver resumo por área
SELECT * FROM v_produtos_por_area;

-- Ver produtos detalhados
SELECT * FROM v_produtos_detalhado
LIMIT 10;

-- Testar função de busca por setor
-- SELECT * FROM get_produtos_por_setor(1);

-- Testar função de busca por área
-- SELECT * FROM get_produtos_por_area(1);

-- Testar função de busca por setor e área
-- SELECT * FROM get_produtos_por_setor_e_area(1, 1);

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. Execute este script após ter setores e áreas cadastrados
-- 2. Ajuste os IDs padrão (seção 3) conforme seus dados
-- 3. As colunas são opcionais (nullable) para manter compatibilidade
-- 4. As views facilitam consultas complexas
-- 5. As funções podem ser usadas para filtros específicos
--
-- Para consultar IDs dos setores e áreas:
-- SELECT id, nome FROM setores;
-- SELECT id, nome FROM areas;
--
-- Para rollback:
-- ALTER TABLE produtos DROP COLUMN IF EXISTS setor_id;
-- ALTER TABLE produtos DROP COLUMN IF EXISTS area_id;
-- ===================================
