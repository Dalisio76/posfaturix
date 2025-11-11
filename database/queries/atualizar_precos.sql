-- Script de exemplo para atualizar preços

-- Atualizar preço de um produto específico
UPDATE produtos
SET preco = 55.00,
    updated_at = CURRENT_TIMESTAMP
WHERE codigo = '001';

-- Aumentar preços em 10% para uma família específica
UPDATE produtos
SET preco = preco * 1.10,
    updated_at = CURRENT_TIMESTAMP
WHERE familia_id = (SELECT id FROM familias WHERE nome = 'BEBIDAS');

-- Ver preços atualizados
SELECT codigo, nome, preco FROM produtos WHERE familia_id = (SELECT id FROM familias WHERE nome = 'BEBIDAS');
