# Migração: Produtos com Setor e Área

## Execução Rápida

Execute este comando para aplicar a migração:

```bash
psql -U postgres -d posfaturix -f database/adicionar_setor_area_produtos.sql
```

**Ou via Python:**
```bash
python -c "from db_helper import *; execute_sql_file('database/adicionar_setor_area_produtos.sql')"
```

## O que esta migração faz?

1. ✅ Adiciona colunas `setor_id` e `area_id` na tabela `produtos`
2. ✅ Cria índices para performance
3. ✅ Atualiza view `v_produtos_completo` com setor e área
4. ✅ Cria views úteis: `v_produtos_por_setor`, `v_produtos_por_area`, `v_produtos_detalhado`
5. ✅ Cria funções para filtrar produtos por setor/área
6. ✅ Define valores padrão para produtos existentes

## Verificação

Após executar, verifique:

```sql
-- Ver produtos com setor e área
SELECT * FROM v_produtos_completo;

-- Ver resumo por setor
SELECT * FROM v_produtos_por_setor;

-- Ver resumo por área
SELECT * FROM v_produtos_por_area;
```

## Funcionalidade Principal

**Memorização Automática:** Ao criar um produto, o sistema memoriza automaticamente a família, setor e área selecionados. No próximo produto, esses campos virão pré-selecionados, agilizando o cadastro em massa.

## Documentação Completa

Veja o arquivo `GUIA_PRODUTOS_SETOR_AREA.md` na raiz do projeto para instruções detalhadas.

## Rollback

Para reverter:
```sql
ALTER TABLE produtos DROP COLUMN IF EXISTS setor_id;
ALTER TABLE produtos DROP COLUMN IF EXISTS area_id;
```
