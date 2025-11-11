-- Consultar dados do sistema

-- Total de produtos
SELECT 'Total de Produtos:' as Info, COUNT(*) as Total FROM produtos;

-- Total de famílias
SELECT 'Total de Famílias:' as Info, COUNT(*) as Total FROM familias;

-- Produtos por família
SELECT
    f.nome as Familia,
    COUNT(p.id) as Total_Produtos,
    SUM(p.estoque) as Total_Estoque
FROM familias f
LEFT JOIN produtos p ON f.id = p.familia_id
GROUP BY f.nome
ORDER BY f.nome;

-- Listar todos os produtos
SELECT
    p.codigo as Codigo,
    p.nome as Produto,
    f.nome as Familia,
    p.preco as Preco,
    p.estoque as Estoque
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
ORDER BY f.nome, p.nome;
