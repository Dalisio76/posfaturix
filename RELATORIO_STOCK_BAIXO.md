# Relatório de Stock Baixo - Implementação Completa

## Arquivos Criados

### 1. Migration SQL
**Arquivo:** `database/migrations/add_estoque_minimo.sql`

Adiciona o campo `estoque_minimo` à tabela produtos:
- Campo INTEGER DEFAULT 0
- Índice otimizado para consultas de stock baixo
- Comentário explicativo na coluna

**Como executar:**
```sql
-- Execute este SQL no PostgreSQL
\i database/migrations/add_estoque_minimo.sql
```

### 2. Controller
**Arquivo:** `lib/app/modules/admin/controllers/stock_baixo_controller.dart`

**Características:**
- Classe `ProdutoStockBaixo` com todos os dados necessários
- Enum `NivelAlerta` (Todos, Crítico, Baixo, Alerta)
- Cálculo automático de percentual e nível de alerta
- Filtros reativos: Família, Setor, Nível
- Query otimizada com JOIN e ordenação por criticidade

**Níveis de Alerta:**
- CRÍTICO: estoque < 30% do mínimo (vermelho)
- BAIXO: estoque entre 30-60% do mínimo (laranja)
- ALERTA: estoque entre 60-100% do mínimo (amarelo)

**Métodos principais:**
```dart
carregarDados()              // Carrega famílias, setores e produtos
carregarProdutosStockBaixo() // Busca produtos com estoque < estoque_minimo
aplicarFiltros()             // Aplica filtros selecionados
calcularTotais()             // Calcula totais por nível
limparFiltros()              // Reseta todos os filtros
```

### 3. View (Tab)
**Arquivo:** `lib/app/modules/admin/views/stock_baixo_tab.dart`

**Estilo Windows Compacto:**
- Padding: 8x4 e 8x6
- Fonts: 10-13px
- isDense: true
- visualDensity: VisualDensity.compact
- headingRowHeight: 24px
- dataRowHeight: 20-22px

**Layout:**

1. **Cabeçalho** (cinza claro)
   - Título: "RELATORIO DE STOCK BAIXO"

2. **Seção de Filtros** (cinza mais claro)
   - Dropdown Família (todas)
   - Dropdown Setor (todos)
   - Dropdown Nível (todos, crítico, baixo, alerta)
   - Botão ATUALIZAR (verde)
   - Botão LIMPAR (laranja)

3. **Totais por Nível** (azul claro)
   - Chips coloridos mostrando:
     - CRÍTICO: X produtos (vermelho)
     - BAIXO: X produtos (laranja)
     - ALERTA: X produtos (amarelo)
     - TOTAL: X produtos (azul)

4. **Tabela de Dados**
   Colunas:
   - STATUS: Badge colorido (CRÍTICO/BAIXO/ALERTA)
   - CÓDIGO: Código do produto
   - PRODUTO: Nome do produto
   - FAMÍLIA: Nome da família
   - SETOR: Nome do setor (ou '-')
   - STOCK ATUAL: Quantidade atual (negrito)
   - STOCK MIN: Quantidade mínima
   - % DO MIN: Percentual do mínimo (colorido)
   - ÚLTIMA ENTRADA: Data da última entrada (dd/MM/yyyy)

5. **Rodapé**
   - Legenda dos níveis
   - Botão VOLTAR (vermelho)

**Cores por Nível:**
- Crítico: `Colors.red[700]`
- Baixo: `Colors.orange[700]`
- Alerta: `Colors.yellow[800]`

**Funcionalidades:**
- Linhas alternadas (branco/cinza claro)
- Linha selecionada em azul
- Scroll horizontal e vertical
- Reatividade com Obx()
- Loading indicator
- Mensagem quando vazio

## Como Integrar no Projeto

### 1. Executar a Migration
```bash
# No PostgreSQL
psql -U seu_usuario -d sua_database -f database/migrations/add_estoque_minimo.sql
```

### 2. Adicionar Tab no Admin
No arquivo de navegação do admin (ex: `admin_page.dart` ou `admin_page_novo.dart`):

```dart
import 'views/stock_baixo_tab.dart';

// Adicionar na lista de tabs:
Tab(text: 'STOCK BAIXO'),

// Adicionar na TabBarView:
const StockBaixoTab(),
```

### 3. Configurar Estoque Mínimo nos Produtos
Os produtos precisam ter o campo `estoque_minimo` preenchido.

No formulário de produto, adicionar:
```dart
TextFormField(
  decoration: InputDecoration(labelText: 'Estoque Mínimo'),
  keyboardType: TextInputType.number,
  // ... restante da configuração
)
```

## Query SQL Utilizada

```sql
SELECT
  p.id,
  p.codigo,
  p.nome,
  p.estoque,
  p.estoque_minimo,
  p.familia_id,
  p.setor_id,
  f.nome as familia_nome,
  s.nome as setor_nome,
  (
    SELECT MAX(fe.data_entrada)
    FROM faturas_entrada_itens fei
    INNER JOIN faturas_entrada fe ON fe.id = fei.fatura_id
    WHERE fei.produto_id = p.id
  ) as ultima_entrada
FROM produtos p
LEFT JOIN familias f ON f.id = p.familia_id
LEFT JOIN setores s ON s.id = p.setor_id
WHERE p.ativo = true
  AND p.estoque_minimo > 0
  AND p.estoque < p.estoque_minimo
ORDER BY
  CASE
    WHEN p.estoque < (p.estoque_minimo * 0.3) THEN 1
    WHEN p.estoque < (p.estoque_minimo * 0.6) THEN 2
    ELSE 3
  END,
  p.nome
```

**Otimizações:**
- LEFT JOIN para incluir produtos sem setor
- Subquery para última entrada (pode ser NULL)
- Ordenação por criticidade (mais críticos primeiro)
- Índice criado na migration para melhor performance

## Exemplo de Uso

1. Usuário acessa a aba "STOCK BAIXO" no painel admin
2. Sistema carrega automaticamente todos os produtos com estoque < estoque_minimo
3. Usuário pode filtrar por:
   - Família específica
   - Setor específico
   - Nível de alerta (ver só críticos, por exemplo)
4. Totais são atualizados automaticamente
5. Tabela mostra informações completas com cores indicativas
6. Usuário pode clicar em ATUALIZAR para recarregar dados
7. Usuário pode clicar em LIMPAR para resetar filtros

## Dependências

Certifique-se de que o projeto tem estas dependências no `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.5
  intl: ^0.18.0
  # ... outras dependências
```

## Notas Importantes

1. **Estoque Mínimo Zero:** Produtos com `estoque_minimo = 0` são ignorados
2. **Produtos Inativos:** Produtos inativos não aparecem no relatório
3. **Performance:** O índice criado otimiza a query para grandes volumes
4. **Última Entrada:** Pode ser NULL se o produto nunca teve entrada registrada
5. **Reatividade:** Todo o relatório é reativo (Obx/RxList)

## Screenshots Esperadas

### Layout Compacto
- Filtros ocupam ~60px de altura
- Totais ocupam ~40px
- Tabela usa todo o espaço restante
- Fonte pequena (10-11px) para máxima densidade

### Cores
- Headers: Cinza médio
- Linhas pares: Branco
- Linhas ímpares: Cinza 50
- Seleção: Azul 200
- Status crítico: Vermelho
- Status baixo: Laranja
- Status alerta: Amarelo

## Próximos Passos

1. **Adicionar Impressão:** Criar serviço de impressão similar ao `StockPrinterService`
2. **Exportar para Excel:** Permitir exportação dos dados
3. **Alertas Automáticos:** Enviar notificações quando produtos entrarem em nível crítico
4. **Dashboard:** Adicionar widget no dashboard principal mostrando resumo
5. **Histórico:** Registrar quando produtos entram/saem do estado de stock baixo
