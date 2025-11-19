# Guia: Produtos Avançados - Sistema Completo

## Visão Geral

Sistema completo de gestão de produtos com funcionalidades avançadas:
1. ✅ **Código Automático** - geração numérica sequencial (1, 2, 3...)
2. ✅ **Preço de Compra** - controle de margem de lucro
3. ✅ **Produto Contável/Não-Contável** - produtos com/sem estoque próprio
4. ✅ **IVA** - Incluso ou Isento
5. ✅ **Composição de Produtos (Menu)** - produtos compostos por outros
6. ✅ **Abate Automático** - ao vender produto composto, abate componentes

## Funcionalidades Implementadas

### 1. Código Automático
- Não precisa mais digitar código ao criar produto
- Sistema gera automaticamente: 1, 2, 3, 4, 5...
- Sequência nunca se repete
- Ao editar, código é exibido mas não pode ser alterado

### 2. Preço de Compra
- Campo obrigatório, padrão 0
- Usado para calcular margem de lucro
- View `v_produtos_completo` calcula margem automaticamente

### 3. Produto Contável
**Sim (Contável):**
- Produto tem estoque próprio
- Ao vender, abate estoque deste produto
- Exemplo: MEIA CAIXA, COCA-COLA, HAMBÚRGUER

**Não (Não-Contável):**
- Produto NÃO tem estoque próprio
- É composto por outros produtos
- Ao vender, abate estoque dos componentes
- Exemplo: CAIXA COMPLETA (= 2x MEIA CAIXA)

### 4. IVA
Duas opções:
- **Incluso**: IVA já está incluído no preço
- **Isento**: Produto isento de IVA

### 5. Composição de Produtos (Menu)
Sistema de produtos compostos:
- Produto não-contável DEVE ter composição
- Pode adicionar vários componentes
- Cada componente tem quantidade específica
- Ao vender, abate automaticamente dos componentes

**Exemplo Prático:**
```
Produto: CAIXA DE CERVEJA (Não-Contável)
Composição:
  - 2x MEIA CAIXA

Ao vender 1 CAIXA:
  ❌ NÃO abate estoque de "CAIXA" (não tem estoque próprio)
  ✅ Abate 2 unidades de "MEIA CAIXA"
```

**Outro Exemplo:**
```
Produto: COMBO LANCHE (Não-Contável)
Composição:
  - 1x HAMBÚRGUER
  - 1x BATATA FRITA
  - 1x REFRIGERANTE

Ao vender 1 COMBO:
  ✅ Abate 1 HAMBÚRGUER
  ✅ Abate 1 BATATA FRITA
  ✅ Abate 1 REFRIGERANTE
```

## Como Executar a Migração

### Passo 1: Executar o SQL

```bash
psql -U postgres -d posfaturix -f database/produtos_avancado.sql
```

**Ou via Python:**
```bash
python -c "from db_helper import *; execute_sql_file('database/produtos_avancado.sql')"
```

### Passo 2: Executar o App

```bash
flutter run
```

## Como Usar

### Criar Produto Contável (Normal)

1. Acesse **Admin > Produtos**
2. Clique em **+** (Adicionar)
3. Preencha:
   - **Nome**: Nome do produto
   - **Família**: Selecione a família
   - **Setor e Área**: (opcional)
   - **Preço de Compra**: Preço que você paga
   - **Preço de Venda**: Preço que você vende
   - **IVA**: Incluso ou Isento
   - **Estoque**: Quantidade inicial
   - **Produto Contável**: Deixe **SIM** ✅
4. Clique em **SALVAR**

**Resultado:**
- Código gerado automaticamente: **1**
- Produto tem estoque próprio
- Ao vender, abate estoque deste produto

### Criar Produto Não-Contável (Composto)

**Exemplo: CAIXA = 2x MEIA CAIXA**

#### Passo 1: Criar o componente (MEIA CAIXA)
1. Acesse **Admin > Produtos**
2. Clique em **+**
3. Preencha:
   - Nome: MEIA CAIXA
   - Preço Compra: 80.00
   - Preço Venda: 100.00
   - Estoque: 100
   - **Contável: SIM** ✅
4. Salvar (código gerado: **1**)

#### Passo 2: Criar o produto composto (CAIXA)
1. Clique em **+** novamente
2. Preencha:
   - Nome: CAIXA COMPLETA
   - Preço Compra: 150.00
   - Preço Venda: 190.00
   - **Contável: NÃO** ❌ (mude o switch para NÃO)
3. Aparece seção **"Composição do Produto (Menu)"**
4. Clique em **Adicionar**
5. Selecione:
   - Produto: **1 - MEIA CAIXA**
   - Quantidade: **2**
6. Clique em **ADICIONAR**
7. Componente aparece na lista
8. Clique em **SALVAR**

**Resultado:**
- Código gerado: **2**
- Produto NÃO tem estoque próprio
- Composição: 2x MEIA CAIXA
- Ao vender 1 CAIXA, abate 2 MEIAS CAIXAS

### Testar a Venda

1. Acesse **Vendas**
2. Adicione **1x CAIXA COMPLETA** ao carrinho
3. Finalize a venda
4. Vá em **Admin > Produtos**
5. Verifique:
   - **CAIXA COMPLETA**: Estoque continua 0 (não-contável)
   - **MEIA CAIXA**: Estoque diminuiu 2 unidades! ✅

## Estrutura do Banco de Dados

### Tabela produtos (atualizada)

```sql
ALTER TABLE produtos
ADD COLUMN preco_compra DECIMAL(10,2) DEFAULT 0 NOT NULL,
ADD COLUMN contavel BOOLEAN DEFAULT true NOT NULL,
ADD COLUMN iva VARCHAR(20) DEFAULT 'Incluso' NOT NULL;
```

### Tabela produto_composicao (nova)

```sql
CREATE TABLE produto_composicao (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER REFERENCES produtos(id),
    produto_componente_id INTEGER REFERENCES produtos(id),
    quantidade DECIMAL(10,2) NOT NULL,
    UNIQUE(produto_id, produto_componente_id)
);
```

### Trigger: Código Automático

```sql
CREATE TRIGGER before_insert_produto_codigo
    BEFORE INSERT ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION trigger_gerar_codigo_produto();
```

### Função: Abater Estoque com Composição

```sql
CREATE FUNCTION abater_estoque_produto(p_produto_id INT, p_quantidade INT)
RETURNS VOID AS $$
BEGIN
    -- Se produto é contável: abate estoque direto
    -- Se não-contável: abate estoque dos componentes
END;
$$;
```

## Views Úteis

### v_produtos_completo
```sql
SELECT
    p.*,
    -- Margem de lucro automática
    ROUND(((p.preco - p.preco_compra) / p.preco_compra * 100), 2) as margem_lucro_percentual,
    -- Tem composição?
    EXISTS(SELECT 1 FROM produto_composicao WHERE produto_id = p.id) as tem_composicao
FROM produtos p;
```

### v_produtos_com_composicao
```sql
SELECT
    p.nome as produto,
    comp.nome as componente,
    pc.quantidade
FROM produtos p
JOIN produto_composicao pc ON p.id = pc.produto_id
JOIN produtos comp ON pc.produto_componente_id = comp.id;
```

### v_produtos_nao_contaveis
```sql
SELECT
    p.nome,
    COUNT(pc.id) as total_componentes
FROM produtos p
LEFT JOIN produto_composicao pc ON p.id = pc.produto_id
WHERE p.contavel = false
GROUP BY p.id;
```

## Consultas Úteis

### Ver produtos com composição
```sql
SELECT * FROM v_produtos_com_composicao;
```

### Ver composição de um produto
```sql
SELECT * FROM get_composicao_produto(2);  -- produto_id = 2
```

### Verificar estoque disponível (considerando composição)
```sql
SELECT * FROM verificar_estoque_disponivel(2, 10);  -- produto_id=2, quantidade=10
```

### Calcular margem de lucro
```sql
SELECT
    codigo,
    nome,
    preco_compra,
    preco as preco_venda,
    margem_lucro_percentual || '%' as margem
FROM v_produtos_completo
ORDER BY margem_lucro_percentual DESC;
```

## Validações Automáticas

### 1. Produto Não-Contável DEVE ter Composição
```dart
if (!contavel.value && composicoes.isEmpty) {
  Get.snackbar('Atenção', 'Produto não-contável deve ter composição');
  return;
}
```

### 2. Estoque Desabilitado para Não-Contáveis
```dart
TextField(
  controller: estoqueController,
  enabled: contavel.value,  // Desabilitado se não-contável
)
```

### 3. Componentes Apenas Contáveis
```dart
controller.produtos.where((p) => p.contavel)  // Só produtos contáveis
```

### 4. Evitar Auto-Referência
```sql
CHECK (produto_id != produto_componente_id)
```

## Casos de Uso

### Caso 1: Restaurante com Embalagens

**Produtos Contáveis:**
- MEIA CAIXA DE CERVEJA (estoque: 100)
- GARRAFA 500ML (estoque: 200)

**Produtos Não-Contáveis:**
- CAIXA COMPLETA = 2x MEIA CAIXA
- PACK 6 GARRAFAS = 6x GARRAFA 500ML

**Venda:**
- Cliente compra 1 CAIXA COMPLETA
- Sistema abate 2 MEIAS CAIXAS

### Caso 2: Combos/Menus

**Produtos Contáveis:**
- HAMBÚRGUER (estoque: 50)
- BATATA FRITA (estoque: 80)
- REFRIGERANTE (estoque: 100)

**Produto Não-Contável:**
- COMBO LANCHE = 1x HAMBÚRGUER + 1x BATATA + 1x REFRIGERANTE

**Venda:**
- Cliente compra 1 COMBO LANCHE
- Sistema abate: 1 HAMBÚRGUER, 1 BATATA, 1 REFRIGERANTE

### Caso 3: Kits e Promoções

**Produtos Contáveis:**
- CERVEJA 2M (estoque: 200)
- AMENDOIM (estoque: 150)

**Produto Não-Contável:**
- KIT HAPPY HOUR = 2x CERVEJA 2M + 1x AMENDOIM

## Troubleshooting

### Erro: "column preco_compra does not exist"
**Solução**: Execute a migração SQL `produtos_avancado.sql`

### Erro: "function abater_estoque_produto does not exist"
**Solução**: Execute o script SQL completo

### Campo Estoque não desabilita
**Solução**: Verifique se o switch "Produto Contável" está funcionando

### Composição não aparece
**Solução**:
1. Certifique-se que "Produto Contável" está em **NÃO**
2. Verifique se tem produtos contáveis cadastrados

### Ao vender, não abate componentes
**Solução**:
1. Verifique se a migração SQL foi executada
2. Teste a função: `SELECT abater_estoque_produto(2, 1);`
3. Verifique se VendaRepository foi atualizado

## Arquivos Modificados/Criados

### SQL
- ✅ `database/produtos_avancado.sql` (NOVO)

### Models
- ✅ `lib/app/data/models/produto_model.dart` (atualizado)
- ✅ `lib/app/data/models/produto_composicao_model.dart` (NOVO)

### Repositories
- ✅ `lib/app/data/repositories/produto_repository.dart`
- ✅ `lib/app/data/repositories/produto_composicao_repository.dart` (NOVO)
- ✅ `lib/app/data/repositories/venda_repository.dart` (atualizado)

### Controllers
- ✅ `lib/app/modules/admin/controllers/admin_controller.dart`

### Views
- ✅ `lib/app/modules/admin/views/produtos_tab.dart`

## Rollback

Para reverter todas as alterações:

```sql
-- Remover tabela de composição
DROP TABLE IF EXISTS produto_composicao CASCADE;

-- Remover sequência
DROP SEQUENCE IF EXISTS produtos_codigo_seq;

-- Remover funções
DROP FUNCTION IF EXISTS get_proximo_codigo_produto();
DROP FUNCTION IF EXISTS trigger_gerar_codigo_produto();
DROP FUNCTION IF EXISTS get_composicao_produto(INTEGER);
DROP FUNCTION IF EXISTS verificar_estoque_disponivel(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS abater_estoque_produto(INTEGER, INTEGER);

-- Remover colunas
ALTER TABLE produtos DROP COLUMN IF EXISTS preco_compra;
ALTER TABLE produtos DROP COLUMN IF EXISTS contavel;
ALTER TABLE produtos DROP COLUMN IF EXISTS iva;
```

---

**✅ Sistema Completo Implementado!**

Agora você tem um sistema profissional de gestão de produtos com:
- Código automático
- Preços de compra e venda
- Produtos contáveis e não-contáveis
- Composição de produtos (menus/kits)
- Abate automático de componentes nas vendas
- Controle de IVA

**Pronto para uso em produção!** 🎉
