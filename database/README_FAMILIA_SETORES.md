# Migração: Família-Setores

## Execução Rápida

Execute este comando para aplicar a migração:

```bash
psql -U postgres -d posfaturix -f database/familia_setores_migration.sql
```

**Ou via Python:**
```bash
python -c "from db_helper import *; execute_sql_file('database/familia_setores_migration.sql')"
```

## O que esta migração faz?

1. ✅ Cria tabela `familia_setores` (relacionamento muitos-para-muitos)
2. ✅ Cria índices para performance
3. ✅ Cria views úteis: `v_familias_com_setores`, `v_produtos_com_setores`
4. ✅ Cria funções auxiliares para consultas
5. ✅ Migra dados existentes (associa famílias ao setor RESTAURANTE por padrão)

## Verificação

Após executar, verifique:

```sql
-- Ver famílias com seus setores
SELECT * FROM v_familias_com_setores;

-- Ver tabela de relacionamento
SELECT * FROM familia_setores;
```

## Documentação Completa

Veja o arquivo `GUIA_FAMILIA_SETORES.md` na raiz do projeto para instruções detalhadas.

## Rollback

Para reverter:
```sql
DROP TABLE IF EXISTS familia_setores CASCADE;
```
