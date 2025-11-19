# Guia: Sistema de Família-Setores

## Visão Geral

Este guia descreve a implementação do relacionamento entre **Famílias** e **Setores**, permitindo que uma família de produtos pertença a múltiplos setores (Restaurante, Armazém, etc.).

## O que foi implementado?

### 1. Banco de Dados
- ✅ Tabela `familia_setores` para relacionamento muitos-para-muitos
- ✅ Índices para performance
- ✅ Views úteis: `v_familias_com_setores`, `v_produtos_com_setores`
- ✅ Funções auxiliares para consultas

### 2. Modelo de Dados (Dart)
- ✅ `FamiliaModel` atualizado com campos:
  - `setorIds`: Lista de IDs dos setores
  - `setorNomes`: Lista de nomes dos setores
  - `setoresTexto`: String formatada com os setores (ex: "RESTAURANTE, ARMAZEM")

### 3. Repositório
- ✅ `FamiliaRepository` atualizado com métodos:
  - `inserir(familia, setorIds)`: Cria família e associa setores
  - `atualizar(id, familia, setorIds)`: Atualiza família e seus setores
  - `associarSetores(familiaId, setorIds)`: Associa múltiplos setores
  - `desassociarSetor(familiaId, setorId)`: Remove associação
  - `buscarSetoresDaFamilia(familiaId)`: Lista setores de uma família

### 4. Interface do Usuário
- ✅ Dialog de cadastro/edição de família com:
  - Campo de nome (obrigatório)
  - Campo de descrição
  - **Checkboxes para selecionar múltiplos setores**
- ✅ Listagem de famílias mostrando seus setores
- ✅ Validação: pelo menos um setor deve ser selecionado

### 5. Controller
- ✅ `AdminController` atualizado para gerenciar setores nas famílias

## Como executar a migração?

### Passo 1: Executar o SQL de Migração

Execute o arquivo SQL no PostgreSQL:

```bash
psql -U seu_usuario -d nome_do_banco -f database/familia_setores_migration.sql
```

**Ou via Python:**
```bash
python -c "from db_helper import *; execute_sql_file('database/familia_setores_migration.sql')"
```

**Ou manualmente no pgAdmin/DBeaver:**
1. Abra o arquivo `database/familia_setores_migration.sql`
2. Execute o script completo

### Passo 2: Verificar a Migração

Após executar, verifique se tudo foi criado corretamente:

```sql
-- Verificar tabela
SELECT * FROM familia_setores;

-- Verificar view
SELECT * FROM v_familias_com_setores;

-- Verificar funções
SELECT * FROM get_familia_setores(1);
```

### Passo 3: Executar o App

```bash
flutter run
```

## Como usar a nova funcionalidade?

### Cadastrar uma Nova Família

1. Acesse **Admin > Famílias**
2. Clique no botão **+** (Adicionar)
3. Preencha:
   - **Nome**: Nome da família (ex: "BEBIDAS")
   - **Descrição**: Descrição opcional
   - **Setores**: Selecione um ou mais setores usando os checkboxes
4. Clique em **SALVAR**

### Editar uma Família Existente

1. Acesse **Admin > Famílias**
2. Clique no ícone de **edição** (lápis azul)
3. Modifique os dados e/ou selecione/desmarque setores
4. Clique em **SALVAR**

### Visualizar Setores de uma Família

Na listagem de famílias, você verá:
- Nome da família
- Descrição
- **Ícone de loja verde + texto "Setores: RESTAURANTE, ARMAZEM"**

## Estrutura do Banco de Dados

### Tabela: familia_setores
```sql
CREATE TABLE familia_setores (
    id SERIAL PRIMARY KEY,
    familia_id INTEGER REFERENCES familias(id) ON DELETE CASCADE,
    setor_id INTEGER REFERENCES setores(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(familia_id, setor_id)
);
```

### View: v_familias_com_setores
```sql
SELECT
    f.id,
    f.nome,
    f.descricao,
    f.ativo,
    f.created_at,
    ARRAY_AGG(s.id) as setor_ids,           -- {1,2,3}
    ARRAY_AGG(s.nome) as setor_nomes,       -- {RESTAURANTE,ARMAZEM}
    STRING_AGG(s.nome, ', ') as setores_texto  -- "RESTAURANTE, ARMAZEM"
FROM familias f
LEFT JOIN familia_setores fs ON f.id = fs.familia_id
LEFT JOIN setores s ON fs.setor_id = s.id
GROUP BY f.id;
```

## Benefícios Futuros

Com esta implementação, você poderá:

### 1. Stock por Setor
```sql
-- Exemplo de estrutura futura
CREATE TABLE produto_stock_setor (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER REFERENCES produtos(id),
    setor_id INTEGER REFERENCES setores(id),
    quantidade INTEGER DEFAULT 0,
    UNIQUE(produto_id, setor_id)
);
```

### 2. Filtrar Produtos por Setor
```sql
-- Buscar produtos disponíveis no setor RESTAURANTE
SELECT p.*
FROM produtos p
INNER JOIN familias f ON p.familia_id = f.id
INNER JOIN familia_setores fs ON f.id = fs.familia_id
INNER JOIN setores s ON fs.setor_id = s.id
WHERE s.nome = 'RESTAURANTE';
```

### 3. Relatórios por Setor
```sql
-- Vendas por setor através das famílias
SELECT
    s.nome as setor,
    COUNT(DISTINCT v.id) as total_vendas,
    SUM(v.total) as valor_total
FROM vendas v
INNER JOIN itens_venda iv ON v.id = iv.venda_id
INNER JOIN produtos p ON iv.produto_id = p.id
INNER JOIN familias f ON p.familia_id = f.id
INNER JOIN familia_setores fs ON f.id = fs.familia_id
INNER JOIN setores s ON fs.setor_id = s.id
GROUP BY s.nome;
```

### 4. Preços Diferentes por Setor (Futuro)
```sql
-- Estrutura para preços diferentes por setor
CREATE TABLE produto_preco_setor (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER REFERENCES produtos(id),
    setor_id INTEGER REFERENCES setores(id),
    preco DECIMAL(10,2) NOT NULL,
    UNIQUE(produto_id, setor_id)
);
```

## Migração de Dados Existentes

O script de migração oferece **2 opções**:

### Opção 1 (Padrão): Associar todas famílias ao RESTAURANTE
```sql
INSERT INTO familia_setores (familia_id, setor_id)
SELECT f.id, 1  -- 1 = RESTAURANTE
FROM familias f
WHERE f.ativo = true;
```

### Opção 2: Associar todas famílias a TODOS os setores
```sql
INSERT INTO familia_setores (familia_id, setor_id)
SELECT f.id, s.id
FROM familias f
CROSS JOIN setores s
WHERE f.ativo = true AND s.ativo = true;
```

**Nota:** A Opção 1 está ativa por padrão. Se preferir a Opção 2, comente a Opção 1 e descomente a Opção 2 no arquivo SQL.

## Consultas Úteis

### Listar famílias com seus setores
```sql
SELECT * FROM v_familias_com_setores;
```

### Produtos com seus setores
```sql
SELECT * FROM v_produtos_com_setores;
```

### Setores de uma família específica
```sql
SELECT * FROM get_familia_setores(1);  -- 1 = ID da família
```

### Verificar se família pertence a um setor
```sql
SELECT familia_pertence_setor(1, 2);  -- familia_id=1, setor_id=2
```

### Adicionar setor a uma família manualmente
```sql
INSERT INTO familia_setores (familia_id, setor_id)
VALUES (1, 2)  -- Família 1 + Setor 2
ON CONFLICT DO NOTHING;
```

### Remover setor de uma família
```sql
DELETE FROM familia_setores
WHERE familia_id = 1 AND setor_id = 2;
```

## Rollback (Reverter a Migração)

Se precisar reverter as mudanças:

```sql
-- Remover views
DROP VIEW IF EXISTS v_produtos_com_setores CASCADE;
DROP VIEW IF EXISTS v_familias_com_setores CASCADE;

-- Remover funções
DROP FUNCTION IF EXISTS get_familia_setores(INTEGER);
DROP FUNCTION IF EXISTS familia_pertence_setor(INTEGER, INTEGER);

-- Remover tabela
DROP TABLE IF EXISTS familia_setores CASCADE;
```

## Troubleshooting

### Erro: "relation familia_setores does not exist"
- **Solução**: Execute o script de migração `familia_setores_migration.sql`

### Erro: "view v_familias_com_setores does not exist"
- **Solução**: Execute o script de migração completo

### Erro ao salvar família: "null value in column setorIds"
- **Solução**: Certifique-se de selecionar pelo menos um setor ao criar/editar

### Checkboxes não aparecem no dialog
- **Solução**: Verifique se existem setores cadastrados em Admin > Setores

### Setores não aparecem na listagem de famílias
- **Solução**:
  1. Verifique se a migração foi executada
  2. Verifique se a família tem setores associados
  3. Execute: `SELECT * FROM v_familias_com_setores;`

## Arquivos Modificados

### SQL
- ✅ `database/familia_setores_migration.sql` (NOVO)

### Models
- ✅ `lib/app/data/models/familia_model.dart`

### Repositories
- ✅ `lib/app/data/repositories/familia_repository.dart`

### Controllers
- ✅ `lib/app/modules/admin/controllers/admin_controller.dart`

### Views
- ✅ `lib/app/modules/admin/views/familias_tab.dart`

## Próximos Passos Recomendados

1. ✅ Executar a migração SQL
2. ✅ Testar cadastro de famílias com múltiplos setores
3. ⏳ Implementar stock por setor (futura)
4. ⏳ Implementar filtros de produtos por setor (futura)
5. ⏳ Implementar relatórios por setor (futura)

## Suporte

Se encontrar problemas:
1. Verifique os logs do PostgreSQL
2. Execute as queries de verificação
3. Verifique se todos os arquivos foram atualizados corretamente
4. Teste no ambiente de desenvolvimento primeiro

---

**Implementado com sucesso! 🎉**

O sistema agora suporta famílias de produtos associadas a múltiplos setores, preparando o terreno para gestão de stock separado por setor.
