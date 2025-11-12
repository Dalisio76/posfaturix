# 📦 Sistema de Fecho de Caixa - POSFaturix

Sistema completo de controle de abertura e fechamento de caixa implementado com sucesso!

## ✅ O que foi implementado

### 1. **Banco de Dados (PostgreSQL)**
- ✅ Tabela `caixas` com todos os campos necessários
- ✅ Functions SQL:
  - `abrir_caixa()` - Abre um novo caixa
  - `calcular_totais_caixa()` - Calcula todos os totais do caixa
  - `fechar_caixa()` - Fecha o caixa e retorna resumo
- ✅ Views:
  - `v_caixa_atual` - Retorna o caixa aberto
  - `v_resumo_caixa` - Resumo completo de todos os caixas
- ✅ Sistema corrigido baseado na estrutura REAL do banco de dados
  - Usa `pagamentos_venda` corretamente (múltiplos pagamentos por venda)
  - Separa vendas pagas de vendas a crédito
  - Inclui pagamentos de dívidas por forma de pagamento

### 2. **Models Flutter**
- ✅ `CaixaModel` - Modelo completo do caixa com todos os campos

### 3. **Repository**
- ✅ `CaixaRepository` - Métodos para:
  - Buscar caixa atual
  - Abrir caixa
  - Calcular totais
  - Fechar caixa
  - Listar histórico de caixas

### 4. **Controller**
- ✅ `CaixaController` - Gerenciamento de estado com GetX
  - Verificação de caixa atual
  - Abertura de caixa
  - Atualização de totais
  - Fechamento de caixa

### 5. **Interface do Usuário**
- ✅ Botão "FECHO CAIXA" na tela de vendas (roxo, entre Despesas e Pedido)
- ✅ Tela completa de Fecho de Caixa com:
  - Informações do caixa (número, datas, terminal)
  - Vendas pagas
  - Formas de pagamento (CASH, EMOLA, MPESA, POS)
  - Vendas a crédito
  - Pagamentos de dívidas
  - Despesas
  - Resumo financeiro com saldo final
  - Botão para imprimir relatório
  - Botão para fechar caixa

### 6. **Impressão**
- ✅ `CaixaPrinterService` - Serviço de impressão
  - Impressão em papel 80mm
  - Relatório completo do fecho de caixa
  - Integração com impressora Windows

---

## 🚀 Como usar

### **Passo 1: Executar o SQL**

1. Abra o **SQL Shell (psql)** ou **pgAdmin**
2. Conecte-se ao banco de dados `pdv_system`
3. Execute o arquivo SQL:

```bash
\i database/fecho_caixa.sql
```

Ou copie e cole o conteúdo do arquivo `database/fecho_caixa.sql` no pgAdmin.

### **Passo 2: Executar o aplicativo**

```bash
flutter run
```

### **Passo 3: Usar o sistema**

1. **Abrir a tela de vendas**
2. **Clicar no botão "FECHO CAIXA"** (botão roxo)
3. Se não houver caixa aberto:
   - Clicar em "ABRIR CAIXA"
4. Ver o relatório em tempo real:
   - Vendas realizadas
   - Formas de pagamento
   - Despesas
   - Saldo atual
5. **Atualizar totais**: Clicar no ícone de atualização
6. **Imprimir relatório**: Clicar em "IMPRIMIR RELATÓRIO"
7. **Fechar caixa**: Clicar em "FECHAR CAIXA"
   - Adicionar observações (opcional)
   - Confirmar o fechamento

---

## 📊 Estrutura de Dados

### **Campos do Caixa**

```
VENDAS PAGAS
├── total_vendas_pagas: Soma de vendas normais
└── qtd_vendas_pagas: Quantidade de vendas

FORMAS DE PAGAMENTO (vendas + pagamentos de dívidas)
├── total_cash / qtd_transacoes_cash
├── total_emola / qtd_transacoes_emola
├── total_mpesa / qtd_transacoes_mpesa
└── total_pos / qtd_transacoes_pos

VENDAS A CRÉDITO (não entra no saldo)
├── total_vendas_credito
└── qtd_vendas_credito

PAGAMENTOS DE DÍVIDAS
├── total_dividas_pagas
└── qtd_dividas_pagas

DESPESAS
├── total_despesas
└── qtd_despesas

SALDO FINAL
├── total_entradas = vendas_pagas + dividas_pagas
├── total_saidas = despesas
└── saldo_final = total_entradas - total_saidas
```

### **Validação Automática**

O sistema valida automaticamente se a soma das formas de pagamento bate com o total de entradas:

```sql
VALIDAÇÃO: total_cash + total_emola + total_mpesa + total_pos = total_entradas
```

---

## 🔄 Fluxo de Funcionamento

### **1. Abertura do Caixa**

```sql
SELECT abrir_caixa('TERMINAL-01', 'João Silva');
```

- Verifica se já existe caixa aberto
- Gera número único do caixa (ex: CX20250112-153045)
- Insere novo registro na tabela `caixas`

### **2. Durante o Dia**

- Vendas são registradas normalmente
- Despesas são registradas
- Pagamentos de dívidas são registrados
- O caixa acumula todas as transações

### **3. Atualização de Totais**

```sql
SELECT calcular_totais_caixa(1); -- ID do caixa
```

- Calcula vendas pagas
- Calcula vendas a crédito
- Soma pagamentos por forma
- Soma pagamentos de dívidas
- Soma despesas
- Calcula saldo final

### **4. Fechamento do Caixa**

```sql
SELECT * FROM fechar_caixa(1, 'Fechamento normal do dia');
```

- Calcula todos os totais
- Atualiza status para 'FECHADO'
- Define data de fechamento
- Retorna resumo do fechamento

---

## 📝 Observações Importantes

### **Diferença entre Vendas Pagas e Vendas a Crédito**

- **Vendas Pagas** (`tipo_venda = 'NORMAL'`):
  - Dinheiro entra no caixa IMEDIATAMENTE
  - Conta no saldo final

- **Vendas a Crédito** (`tipo_venda = 'DIVIDA'`):
  - Dinheiro NÃO entra no caixa (ainda)
  - NÃO conta no saldo final
  - Aparece apenas como informação

### **Pagamentos de Dívidas Antigas**

- Quando um cliente paga uma dívida antiga, o valor ENTRA no caixa atual
- Soma no `total_dividas_pagas`
- Conta no saldo final

### **Formas de Pagamento**

- O sistema separa as transações por forma:
  - CASH, EMOLA, MPESA, POS
- Inclui TANTO vendas quanto pagamentos de dívidas
- A soma de todas as formas DEVE ser igual ao total de entradas

---

## 🧪 Testando o Sistema

### **Teste 1: Abrir Caixa**

1. Abrir a tela de Fecho de Caixa
2. Clicar em "ABRIR CAIXA"
3. Verificar que o caixa foi aberto

### **Teste 2: Fazer Vendas**

1. Voltar para tela de vendas
2. Fazer algumas vendas com diferentes formas de pagamento
3. Registrar algumas despesas

### **Teste 3: Ver Relatório**

1. Abrir Fecho de Caixa novamente
2. Ver que os totais foram atualizados
3. Clicar em "Atualizar" para recalcular

### **Teste 4: Fechar Caixa**

1. Clicar em "FECHAR CAIXA"
2. Adicionar observações
3. Confirmar fechamento
4. Ver resumo final

### **Teste 5: Imprimir**

1. Com um caixa aberto ou fechado
2. Clicar em "IMPRIMIR RELATÓRIO"
3. Verificar impressão na impressora configurada

---

## 🐛 Troubleshooting

### **Problema: "Já existe um caixa aberto"**

**Solução**: Feche o caixa atual antes de abrir um novo.

```sql
-- Ver caixa aberto
SELECT * FROM v_caixa_atual;

-- Fechar manualmente
SELECT * FROM fechar_caixa(ID_DO_CAIXA, 'Fechamento manual');
```

### **Problema: "Totais não batem"**

**Solução**: Execute a validação:

```sql
SELECT
    numero,
    total_entradas,
    (total_cash + total_emola + total_mpesa + total_pos) as soma_formas,
    ABS(total_entradas - (total_cash + total_emola + total_mpesa + total_pos)) as diferenca
FROM caixas
WHERE status = 'ABERTO';
```

### **Problema: "Impressora não encontrada"**

**Solução**:
1. Verificar nome da impressora em `lib/core/utils/caixa_printer_service.dart`
2. Alterar constante `printerName` para o nome correto da sua impressora
3. Ou usar a função `listarImpressoras()` para ver impressoras disponíveis

---

## 📚 Arquivos Criados/Modificados

### **Novos Arquivos**

- `database/fecho_caixa.sql` - SQL completo do sistema
- `lib/app/data/models/caixa_model.dart` - Model do caixa
- `lib/app/data/repositories/caixa_repository.dart` - Repository
- `lib/app/modules/caixa/controllers/caixa_controller.dart` - Controller
- `lib/app/modules/caixa/views/tela_fecho_caixa.dart` - Interface
- `lib/core/utils/caixa_printer_service.dart` - Serviço de impressão

### **Arquivos Modificados**

- `lib/app/modules/vendas/vendas_page.dart` - Adicionado botão "FECHO CAIXA"

---

## ✨ Funcionalidades

✅ Abertura automática ou manual de caixa
✅ Controle de vendas pagas por forma de pagamento
✅ Controle de vendas a crédito (separadas)
✅ Controle de pagamentos de dívidas antigas
✅ Controle de despesas
✅ Cálculo automático de saldo final
✅ Validação de totais
✅ Relatório completo em tela
✅ Impressão do relatório
✅ Fechamento de caixa com observações
✅ Histórico de caixas fechados
✅ Interface amigável e intuitiva

---

## 🎉 Pronto para Usar!

O sistema de fecho de caixa está **100% funcional** e pronto para ser usado em produção!

**Desenvolvido com base nos guias:**
- `GUIA_FECHO_CAIXA.md`
- `CORRECAO_GUIA_FECHO_CAIXA.md`

**Data de implementação:** 2025-01-12
**Tecnologias:** Flutter + GetX + PostgreSQL + PDF Printing
