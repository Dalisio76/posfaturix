# Guia: Produtos com Setor e Área

## Visão Geral

Esta funcionalidade permite associar cada produto a um **Setor** e **Área** específicos, além da família. O sistema também memoriza as últimas seleções para agilizar o cadastro de múltiplos produtos.

## O que foi implementado?

### 1. Banco de Dados
- ✅ Adicionadas colunas `setor_id` e `area_id` na tabela `produtos`
- ✅ Índices para performance
- ✅ Views atualizadas: `v_produtos_completo`, `v_produtos_detalhado`
- ✅ Views novas: `v_produtos_por_setor`, `v_produtos_por_area`
- ✅ Funções auxiliares para filtrar produtos por setor/área

### 2. Modelo de Dados (Dart)
- ✅ `ProdutoModel` atualizado com campos:
  - `setorId`: ID do setor
  - `areaId`: ID da área
  - `setorNome`: Nome do setor (join)
  - `areaNome`: Nome da área (join)

### 3. Repositório
- ✅ `ProdutoRepository` atualizado para:
  - Usar view `v_produtos_completo` (já inclui setor e área)
  - Métodos novos: `listarPorSetor()`, `listarPorArea()`
  - Inserir e atualizar produtos com setor e área

### 4. Interface do Usuário
- ✅ Dialog de cadastro/edição com:
  - Dropdown para selecionar **Setor**
  - Dropdown para selecionar **Área**
  - **Memorização automática** das últimas seleções
- ✅ Listagem mostrando setor e área de cada produto com ícones

### 5. Controller
- ✅ Variáveis para memorizar últimas seleções:
  - `ultimaFamiliaSelecionada`
  - `ultimoSetorSelecionado`
  - `ultimaAreaSelecionada`
- ✅ Lógica para salvar seleções ao adicionar produto

## Como executar a migração?

### Passo 1: Executar o SQL de Migração

```bash
psql -U postgres -d posfaturix -f database/adicionar_setor_area_produtos.sql
```

**Ou via Python:**
```bash
python -c "from db_helper import *; execute_sql_file('database/adicionar_setor_area_produtos.sql')"
```

### Passo 2: Executar o App

```bash
flutter run
```

## Como usar a funcionalidade?

### Cadastrar um Novo Produto

1. Acesse **Admin > Produtos**
2. Clique no botão **+** (Adicionar)
3. Preencha:
   - **Código**: Código único do produto
   - **Nome**: Nome do produto
   - **Família**: Selecione a família (obrigatório)
   - **Setor**: Selecione o setor (opcional)
   - **Área**: Selecione a área (opcional)
   - **Preço**: Preço de venda
   - **Estoque**: Quantidade inicial
4. Clique em **SALVAR**

### Funcionalidade de Memorização

Ao criar um produto, o sistema **memoriza automaticamente**:
- Família selecionada
- Setor selecionado
- Área selecionada

Quando você criar o **próximo produto**, esses campos virão **pré-selecionados** com os valores do produto anterior, agilizando o cadastro em massa.

**Exemplo:**
1. Crio produto "COCA-COLA 500ML":
   - Família: BEBIDAS
   - Setor: RESTAURANTE
   - Área: BAR
2. Clico em adicionar novo produto
3. Os campos já vêm selecionados:
   - Família: **BEBIDAS** ✅
   - Setor: **RESTAURANTE** ✅
   - Área: **BAR** ✅
4. Só preciso preencher código, nome e preço!

### Visualizar Produtos

Na listagem de produtos, você verá:
- Nome do produto
- Família
- **Ícone azul de loja + "Setor: RESTAURANTE"**
- **Ícone laranja de localização + "Área: BAR"**
- Estoque
- Preço

## Estrutura do Banco de Dados

### Tabela produtos (atualizada)
```sql
ALTER TABLE produtos
ADD COLUMN setor_id INTEGER REFERENCES setores(id);
ADD COLUMN area_id INTEGER REFERENCES areas(id);

CREATE INDEX idx_produtos_setor ON produtos(setor_id);
CREATE INDEX idx_produtos_area ON produtos(area_id);
```

### View: v_produtos_completo
```sql
CREATE VIEW v_produtos_completo AS
SELECT
    p.*,
    f.nome as familia_nome,
    s.nome as setor_nome,
    a.nome as area_nome
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id;
```

### View: v_produtos_por_setor
```sql
CREATE VIEW v_produtos_por_setor AS
SELECT
    s.nome as setor_nome,
    COUNT(p.id) as total_produtos,
    SUM(p.estoque) as total_estoque,
    SUM(p.preco * p.estoque) as valor_total_estoque
FROM setores s
LEFT JOIN produtos p ON s.id = p.setor_id
GROUP BY s.nome;
```

## Consultas Úteis

### Listar todos os produtos com setor e área
```sql
SELECT * FROM v_produtos_completo;
```

### Produtos de um setor específico
```sql
SELECT * FROM v_produtos_completo
WHERE setor_nome = 'RESTAURANTE';
```

### Produtos de uma área específica
```sql
SELECT * FROM v_produtos_completo
WHERE area_nome = 'BAR';
```

### Resumo de produtos por setor
```sql
SELECT * FROM v_produtos_por_setor;
```

### Resumo de produtos por área
```sql
SELECT * FROM v_produtos_por_area;
```

### Produtos do setor RESTAURANTE e área BAR
```sql
SELECT * FROM get_produtos_por_setor_e_area(1, 1);  -- setor_id=1, area_id=1
```

### Atualizar setor/área de produtos existentes
```sql
-- Definir setor RESTAURANTE para produtos da família BEBIDAS
UPDATE produtos
SET setor_id = 1  -- 1 = RESTAURANTE
WHERE familia_id = (SELECT id FROM familias WHERE nome = 'BEBIDAS');

-- Definir área BAR para produtos do setor RESTAURANTE
UPDATE produtos
SET area_id = 1  -- 1 = BAR
WHERE setor_id = 1;
```

## Benefícios

### 1. Organização
- Produtos organizados por setor (RESTAURANTE, ARMAZÉM, etc.)
- Produtos organizados por área (BAR, COZINHA, GERAL)

### 2. Filtros e Relatórios
- Filtrar produtos por setor
- Filtrar produtos por área
- Relatórios de vendas por setor/área

### 3. Gestão de Stock
- Controle de estoque separado por setor
- Transferências entre setores (futura implementação)

### 4. Agilidade no Cadastro
- **Memorização automática** acelera cadastro em massa
- Cadastrar 100 produtos da mesma família/setor/área sem reselecionar

## Exemplos de Uso

### Cadastro Rápido de Bebidas

1. Primeiro produto: "COCA-COLA 500ML"
   - Seleciono: Família=BEBIDAS, Setor=RESTAURANTE, Área=BAR
2. Segundo produto: "SPRITE 500ML"
   - Campos já vêm com: Família=BEBIDAS, Setor=RESTAURANTE, Área=BAR
   - Só altero: Código e Nome
3. Terceiro produto: "FANTA 500ML"
   - Campos já vêm com: Família=BEBIDAS, Setor=RESTAURANTE, Área=BAR
   - Só altero: Código e Nome

**Resultado:** Cadastrei 3 produtos em menos tempo!

### Transferir Produtos para Outro Setor

```sql
-- Transferir bebidas do RESTAURANTE para o ARMAZÉM
UPDATE produtos
SET setor_id = 2  -- 2 = ARMAZÉM
WHERE familia_id IN (
  SELECT id FROM familias WHERE nome IN ('BEBIDAS', 'REFRIGERANTES')
)
AND setor_id = 1;  -- 1 = RESTAURANTE
```

## Rollback (Reverter)

Se precisar reverter:

```sql
-- Remover views
DROP VIEW IF EXISTS v_produtos_por_area CASCADE;
DROP VIEW IF EXISTS v_produtos_por_setor CASCADE;
DROP VIEW IF EXISTS v_produtos_detalhado CASCADE;
DROP VIEW IF EXISTS v_produtos_completo CASCADE;

-- Remover funções
DROP FUNCTION IF EXISTS get_produtos_por_setor(INTEGER);
DROP FUNCTION IF EXISTS get_produtos_por_area(INTEGER);
DROP FUNCTION IF EXISTS get_produtos_por_setor_e_area(INTEGER, INTEGER);

-- Remover colunas
ALTER TABLE produtos DROP COLUMN IF EXISTS setor_id;
ALTER TABLE produtos DROP COLUMN IF EXISTS area_id;
```

## Troubleshooting

### Erro: "column setor_id does not exist"
- **Solução**: Execute o script de migração `adicionar_setor_area_produtos.sql`

### Erro: "relation v_produtos_completo does not exist"
- **Solução**: Execute o script de migração completo

### Dropdowns de Setor/Área vazios
- **Solução**: Verifique se existem setores e áreas cadastrados em Admin > Setores e Admin > Áreas

### Últimas seleções não são memorizadas
- **Solução**:
  1. Certifique-se de que está **criando** (não editando) produtos
  2. Verifique se os produtos estão sendo salvos com sucesso

## Arquivos Modificados

### SQL
- ✅ `database/adicionar_setor_area_produtos.sql` (NOVO)

### Models
- ✅ `lib/app/data/models/produto_model.dart`

### Repositories
- ✅ `lib/app/data/repositories/produto_repository.dart`

### Controllers
- ✅ `lib/app/modules/admin/controllers/admin_controller.dart`

### Views
- ✅ `lib/app/modules/admin/views/produtos_tab.dart`

## Próximos Passos Recomendados

1. ✅ Executar a migração SQL
2. ✅ Testar cadastro de produtos com setor e área
3. ✅ Testar memorização das últimas seleções
4. ⏳ Implementar filtros de produtos por setor/área na tela de vendas
5. ⏳ Implementar transferências de produtos entre setores
6. ⏳ Implementar relatórios de vendas por setor/área

---

**Implementado com sucesso! 🎉**

Agora você pode criar produtos associados a setores e áreas, com memorização automática para agilizar o cadastro em massa.
