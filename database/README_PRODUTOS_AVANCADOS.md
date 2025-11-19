# Migração: Produtos Avançados

## Execução Rápida

Execute este comando para aplicar TODAS as funcionalidades avançadas:

```bash
psql -U postgres -d posfaturix -f database/produtos_avancado.sql
```

**Ou via Python:**
```bash
python -c "from db_helper import *; execute_sql_file('database/produtos_avancado.sql')"
```

## O que esta migração faz?

1. ✅ **Código Automático** - gera códigos numéricos sequenciais (1, 2, 3...)
2. ✅ **Preço de Compra** - campo para controle de margem
3. ✅ **Produto Contável** - define se produto tem estoque próprio ou não
4. ✅ **IVA** - campo Incluso/Isento
5. ✅ **Tabela produto_composicao** - produtos compostos por outros
6. ✅ **Funções SQL** - abate automático considerando composição
7. ✅ **Views** - v_produtos_completo, v_produtos_com_composicao, v_produtos_nao_contaveis
8. ✅ **Trigger** - gera código automaticamente ao inserir produto

## Funcionalidade Principal: Composição de Produtos

**Exemplo:**
```
Produto: CAIXA (Não-Contável)
Composição: 2x MEIA CAIXA

Ao vender 1 CAIXA:
  ❌ NÃO abate estoque de CAIXA
  ✅ Abate 2x MEIA CAIXA automaticamente
```

## Verificação

Após executar, verifique:

```sql
-- Ver produtos com novos campos
SELECT codigo, nome, preco, preco_compra, contavel, iva FROM produtos;

-- Ver composições
SELECT * FROM v_produtos_com_composicao;

-- Testar código automático
INSERT INTO produtos (nome, familia_id, preco, preco_compra)
VALUES ('TESTE', 1, 100, 80);

-- Ver código gerado
SELECT codigo, nome FROM produtos WHERE nome = 'TESTE';
```

## Documentação Completa

Veja o arquivo `GUIA_PRODUTOS_AVANCADOS.md` na raiz do projeto para:
- Instruções detalhadas de uso
- Exemplos práticos
- Consultas SQL úteis
- Troubleshooting

## Rollback

Para reverter:
```sql
DROP TABLE IF EXISTS produto_composicao CASCADE;
DROP SEQUENCE IF EXISTS produtos_codigo_seq CASCADE;
ALTER TABLE produtos DROP COLUMN preco_compra;
ALTER TABLE produtos DROP COLUMN contavel;
ALTER TABLE produtos DROP COLUMN iva;
```
