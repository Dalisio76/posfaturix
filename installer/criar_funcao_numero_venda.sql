-- Criar função para obter próximo número de venda
-- Execute este script no PostgreSQL

CREATE OR REPLACE FUNCTION obter_proximo_numero_venda()
RETURNS INTEGER AS $$
DECLARE
    proximo INTEGER;
BEGIN
    SELECT COALESCE(MAX(numero_venda), 0) + 1 INTO proximo FROM vendas;
    RETURN proximo;
END;
$$ LANGUAGE plpgsql;

-- Testar
SELECT obter_proximo_numero_venda();
