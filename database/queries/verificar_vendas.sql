-- Verificar vendas realizadas

-- Últimas vendas
SELECT
    id,
    numero,
    total,
    data_venda,
    terminal
FROM vendas
ORDER BY id DESC
LIMIT 5;

-- Detalhes da última venda (substitua X pelo ID da venda)
SELECT
    v.numero as Venda,
    v.total as Total,
    v.data_venda,
    p.nome as Produto,
    iv.quantidade,
    iv.preco_unitario,
    iv.subtotal
FROM vendas v
JOIN itens_venda iv ON v.id = iv.venda_id
JOIN produtos p ON iv.produto_id = p.id
WHERE v.id = (SELECT MAX(id) FROM vendas)
ORDER BY iv.id;

-- Verificar estoque atualizado
SELECT
    codigo,
    nome,
    estoque,
    preco
FROM produtos
ORDER BY codigo;
