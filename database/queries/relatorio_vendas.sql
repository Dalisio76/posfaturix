-- Relatórios de vendas

-- Total vendido hoje
SELECT
    COUNT(*) as Total_Vendas,
    SUM(total) as Valor_Total
FROM vendas
WHERE DATE(data_venda) = CURRENT_DATE;

-- Últimas 10 vendas
SELECT
    id,
    numero,
    total,
    data_venda,
    terminal
FROM vendas
ORDER BY data_venda DESC
LIMIT 10;

-- Produtos mais vendidos
SELECT
    p.nome as Produto,
    SUM(iv.quantidade) as Quantidade_Vendida,
    SUM(iv.subtotal) as Valor_Total
FROM itens_venda iv
JOIN produtos p ON iv.produto_id = p.id
GROUP BY p.nome
ORDER BY Quantidade_Vendida DESC;

-- Vendas por família
SELECT
    f.nome as Familia,
    COUNT(DISTINCT iv.venda_id) as Numero_Vendas,
    SUM(iv.quantidade) as Quantidade_Total,
    SUM(iv.subtotal) as Valor_Total
FROM itens_venda iv
JOIN produtos p ON iv.produto_id = p.id
JOIN familias f ON p.familia_id = f.id
GROUP BY f.nome
ORDER BY Valor_Total DESC;
