-- Script para remover acentos de produtos e familias
-- Execute este script para sanitizar os dados existentes

BEGIN;

-- Ver quantos produtos têm acentos
SELECT COUNT(*) as total_produtos_com_acentos
FROM produtos
WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]';

-- Ver quantas famílias têm acentos
SELECT COUNT(*) as total_familias_com_acentos
FROM familias
WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]';

-- Criar função para remover acentos em PostgreSQL
CREATE OR REPLACE FUNCTION remover_acentos(texto TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN translate(texto,
    'àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª',
    'aaaaaaeeeeiiiiooooouuuucAAAAAAEEEEIIIIOOOOOUUUUCoa'
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Atualizar produtos removendo acentos
UPDATE produtos
SET nome = remover_acentos(nome),
    descricao = remover_acentos(COALESCE(descricao, ''))
WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]'
   OR descricao ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]';

-- Atualizar famílias removendo acentos
UPDATE familias
SET nome = remover_acentos(nome),
    descricao = remover_acentos(COALESCE(descricao, ''))
WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]'
   OR descricao ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]';

-- Ver resultados
SELECT 'Produtos atualizados' as tabela, COUNT(*) as total
FROM produtos
WHERE nome = remover_acentos(nome)
UNION ALL
SELECT 'Familias atualizadas' as tabela, COUNT(*) as total
FROM familias
WHERE nome = remover_acentos(nome);

-- Se quiser DELETAR (cuidado!) ao invés de sanitizar, descomente:
-- DELETE FROM produtos
-- WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]';
--
-- DELETE FROM familias
-- WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]';

COMMIT;

-- Verificação final
SELECT 'Verificacao final - produtos com acentos restantes:' as status;
SELECT id, nome FROM produtos
WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]'
LIMIT 10;

SELECT 'Verificacao final - familias com acentos restantes:' as status;
SELECT id, nome FROM familias
WHERE nome ~ '[àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇºª]'
LIMIT 10;
