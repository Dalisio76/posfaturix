-- Script de exemplo para adicionar novos produtos

-- Adicionar uma nova família (se necessário)
INSERT INTO familias (nome, descricao) VALUES
('LANCHES', 'Lanches e salgados')
ON CONFLICT DO NOTHING;

-- Adicionar produtos
-- Substitua os valores conforme necessário
INSERT INTO produtos (codigo, nome, familia_id, preco, estoque) VALUES
('009', 'SUCO NATURAL', 1, 45.00, 30),
('010', 'CAFÉ EXPRESSO', 1, 35.00, 50)
ON CONFLICT (codigo) DO NOTHING;

-- Verificar produtos adicionados
SELECT * FROM produtos WHERE codigo IN ('009', '010');
