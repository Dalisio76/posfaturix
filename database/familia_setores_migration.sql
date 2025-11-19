-- ===================================
-- MIGRAÇÃO: Relacionamento Família-Setores
-- Permite que uma família pertença a múltiplos setores
-- ===================================

-- ===================================
-- 1. CRIAR TABELA DE RELACIONAMENTO
-- ===================================
CREATE TABLE IF NOT EXISTS familia_setores (
    id SERIAL PRIMARY KEY,
    familia_id INTEGER NOT NULL REFERENCES familias(id) ON DELETE CASCADE,
    setor_id INTEGER NOT NULL REFERENCES setores(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(familia_id, setor_id)
);

-- ===================================
-- 2. ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_familia_setores_familia ON familia_setores(familia_id);
CREATE INDEX IF NOT EXISTS idx_familia_setores_setor ON familia_setores(setor_id);

-- ===================================
-- 3. MIGRAÇÃO DE DADOS EXISTENTES
-- Associa todas as famílias existentes aos setores existentes
-- (você pode ajustar isso conforme necessário)
-- ===================================

-- Comentário: Por padrão, todas as famílias existentes serão associadas
-- ao setor 'RESTAURANTE' (id = 1). Ajuste conforme necessário.

-- Opção 1: Associar todas as famílias ao setor RESTAURANTE apenas
INSERT INTO familia_setores (familia_id, setor_id)
SELECT f.id, 1 -- 1 = RESTAURANTE
FROM familias f
WHERE f.ativo = true
ON CONFLICT (familia_id, setor_id) DO NOTHING;

-- Opção 2: Associar todas as famílias a TODOS os setores (descomente se preferir)
-- INSERT INTO familia_setores (familia_id, setor_id)
-- SELECT f.id, s.id
-- FROM familias f
-- CROSS JOIN setores s
-- WHERE f.ativo = true AND s.ativo = true
-- ON CONFLICT (familia_id, setor_id) DO NOTHING;

-- ===================================
-- 4. VIEWS ÚTEIS
-- ===================================

-- View: Famílias com seus setores (formato agregado)
CREATE OR REPLACE VIEW v_familias_com_setores AS
SELECT
    f.id,
    f.nome,
    f.descricao,
    f.ativo,
    f.created_at,
    ARRAY_AGG(s.id ORDER BY s.nome) FILTER (WHERE s.id IS NOT NULL) as setor_ids,
    ARRAY_AGG(s.nome ORDER BY s.nome) FILTER (WHERE s.nome IS NOT NULL) as setor_nomes,
    STRING_AGG(s.nome, ', ' ORDER BY s.nome) as setores_texto
FROM familias f
LEFT JOIN familia_setores fs ON f.id = fs.familia_id
LEFT JOIN setores s ON fs.setor_id = s.id AND s.ativo = true
WHERE f.ativo = true
GROUP BY f.id, f.nome, f.descricao, f.ativo, f.created_at
ORDER BY f.nome;

-- View: Produtos com família e setores
CREATE OR REPLACE VIEW v_produtos_com_setores AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.familia_id,
    p.preco,
    p.estoque,
    p.ativo,
    f.nome as familia_nome,
    STRING_AGG(DISTINCT s.nome, ', ' ORDER BY s.nome) as setores
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN familia_setores fs ON f.id = fs.familia_id
LEFT JOIN setores s ON fs.setor_id = s.id AND s.ativo = true
WHERE p.ativo = true
GROUP BY p.id, p.codigo, p.nome, p.familia_id, p.preco, p.estoque, p.ativo, f.nome
ORDER BY p.nome;

-- ===================================
-- 5. FUNÇÕES ÚTEIS
-- ===================================

-- Função: Obter setores de uma família
CREATE OR REPLACE FUNCTION get_familia_setores(p_familia_id INTEGER)
RETURNS TABLE (
    setor_id INTEGER,
    setor_nome VARCHAR(100),
    setor_descricao TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.nome, s.descricao
    FROM setores s
    INNER JOIN familia_setores fs ON s.id = fs.setor_id
    WHERE fs.familia_id = p_familia_id
    AND s.ativo = true
    ORDER BY s.nome;
END;
$$ LANGUAGE plpgsql;

-- Função: Verificar se família pertence a um setor
CREATE OR REPLACE FUNCTION familia_pertence_setor(p_familia_id INTEGER, p_setor_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM familia_setores
        WHERE familia_id = p_familia_id
        AND setor_id = p_setor_id
    );
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 6. VERIFICAÇÃO
-- ===================================

-- Consultar famílias com seus setores
-- SELECT * FROM v_familias_com_setores;

-- Consultar produtos com setores
-- SELECT * FROM v_produtos_com_setores;

-- Testar função de setores de uma família
-- SELECT * FROM get_familia_setores(1);

-- Testar se família pertence a setor
-- SELECT familia_pertence_setor(1, 1);

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. Execute este script após ter setores cadastrados
-- 2. Ajuste a migração de dados (seção 3) conforme necessário
-- 3. As views facilitam consultas complexas
-- 4. As funções podem ser usadas em queries futuras
-- 5. Para rollback, execute: DROP TABLE familia_setores CASCADE;
