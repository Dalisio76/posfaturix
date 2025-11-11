# ✅ Sistema de Dívidas - CORRIGIDO

## 🎯 Implementação Correta

A seleção de clientes e registro de dívidas agora está **DENTRO DO DIALOG DE PAGAMENTO**, conforme solicitado.

---

## 📍 Localização Correta

### ❌ **ANTES (Errado)**
- Botão CLIENTES na tela de vendas abria seleção de cliente
- Botão DÍVIDAS na tela de vendas alternava modo
- Indicadores no carrinho

### ✅ **AGORA (Correto)**
- **Dialog de Pagamento** tem botão "DÍVIDAS"
- Ao clicar em DÍVIDAS, abre seleção de cliente
- Cliente selecionado aparece no próprio dialog
- Modo dívida permite finalizar sem pagar tudo

---

## 🚀 Como Usar

### **1. Fazer uma Venda Normal**

1. Adicionar produtos ao carrinho
2. Clicar em **FINALIZAR VENDA**
3. Dialog de pagamento abre
4. Adicionar pagamentos (CASH, EMOLA, etc)
5. Quando `Total Pago >= Total`, botão FINALIZAR fica verde
6. Clicar em **FINALIZAR PAGAMENTO**
7. ✅ Venda registrada normalmente

---

### **2. Fazer uma Venda a Crédito (Dívida)**

1. Adicionar produtos ao carrinho
2. Clicar em **FINALIZAR VENDA**
3. Dialog de pagamento abre
4. **Clicar no botão DÍVIDAS** (laranja/vermelho)
5. Dialog de seleção de cliente abre
6. Pesquisar cliente com teclado virtual
7. Selecionar cliente e clicar **SELECIONAR**
8. ✅ Voltou ao dialog de pagamento
9. Resumo muda de cor (vermelho)
10. Aparece: "VENDA A CRÉDITO - Nome do Cliente"
11. Botão DÍVIDAS muda para: "CLIENTE: NOME"

**OPÇÕES:**

**A) Pagamento Parcial:**
- Adicionar parte do valor em pagamentos
- Botão FINALIZAR fica verde (mesmo sem pagar tudo)
- Clicar em **FINALIZAR PAGAMENTO**
- ✅ Venda registrada + Dívida com valor restante

**B) Sem Pagamento (100% a Crédito):**
- NÃO adicionar nenhum pagamento
- Botão FINALIZAR fica verde (modo dívida permite)
- Clicar em **FINALIZAR PAGAMENTO**
- ✅ Venda registrada + Dívida com valor total

---

## 🎨 Interface Visual do Dialog de Pagamento

### **Modo Normal:**
```
┌─────────────────────────────────────┐
│ 🔵 RESUMO (fundo azul)              │
│ TOTAL: MT 500.00                    │
│ Pago: MT 500.00                     │
│ Restante: MT 0.00                   │
└─────────────────────────────────────┘

[CASH] [EMOLA] [MPESA] [POS]

[🟠 DÍVIDAS] ← Laranja
```

### **Modo Dívida (Cliente Selecionado):**
```
┌─────────────────────────────────────┐
│ 🔴 RESUMO (fundo vermelho)          │
│ ┌─────────────────────────────────┐ │
│ │ 💳 VENDA A CRÉDITO - João Silva │ │
│ └─────────────────────────────────┘ │
│ TOTAL: MT 500.00                    │
│ Pago: MT 200.00                     │
│ Restante: MT 300.00                 │
└─────────────────────────────────────┘

[CASH] [EMOLA] [MPESA] [POS]

[🔴 CLIENTE: JOÃO] ← Vermelho
```

---

## 🔄 Fluxo Completo

### **Venda a Crédito com Pagamento Parcial:**

```
1. Carrinho: MT 1000.00
   ↓
2. FINALIZAR VENDA
   ↓
3. Dialog de Pagamento abre
   ↓
4. Clicar DÍVIDAS
   ↓
5. Selecionar cliente (João Silva)
   ↓
6. Voltar ao dialog
   ↓
7. Adicionar pagamento: MT 300.00 (CASH)
   ↓
8. Ainda falta: MT 700.00
   ↓
9. Botão FINALIZAR está VERDE (modo dívida permite)
   ↓
10. FINALIZAR PAGAMENTO
    ↓
11. ✅ Registra:
    - Venda: MT 1000.00
    - Pagamento: MT 300.00 (CASH)
    - Dívida: cliente_id=5, valor_total=1000.00,
              valor_pago=300.00, valor_restante=700.00
    ↓
12. Mensagem: "Dívida Registrada - Valor restante: MT 700.00"
```

---

## 🗂️ Estrutura no Banco de Dados

### **Tabela: vendas**
```sql
id | numero | total | data_venda | cliente_id | tipo_venda
1  | VD123  | 1000  | 2025-11-11 | NULL       | NORMAL
2  | VD124  | 1000  | 2025-11-11 | 5          | DIVIDA  ← (futuro)
```

### **Tabela: dividas**
```sql
id | cliente_id | venda_id | valor_total | valor_pago | valor_restante | status
1  | 5          | 2        | 1000.00     | 300.00     | 700.00         | PARCIAL
```

### **Tabela: pagamentos_divida**
```sql
id | divida_id | valor  | forma_pagamento_id | data_pagamento
1  | 1         | 300.00 | 1 (CASH)          | 2025-11-11
```

---

## 📋 Validações Implementadas

### **1. Modo Normal:**
- ✅ Só pode finalizar se `Total Pago >= Total`
- ✅ Não pode clicar FINALIZAR se falta pagar

### **2. Modo Dívida:**
- ✅ Exige cliente selecionado
- ✅ Pode finalizar mesmo sem pagar tudo
- ✅ Se pagar parcial, registra dívida do restante
- ✅ Se não pagar nada, registra dívida total

### **3. Botão DÍVIDAS:**
- ✅ Começa laranja: "DÍVIDAS"
- ✅ Ao selecionar cliente, fica vermelho: "CLIENTE: NOME"
- ✅ Ao clicar novamente, remove cliente e volta ao normal

---

## 🎯 Funcionalidades do Botão DÍVIDAS

### **Estado 1: Sem Cliente (Laranja)**
```
[🟠 DÍVIDAS]
```
- Ao clicar: Abre dialog de seleção de cliente

### **Estado 2: Cliente Selecionado (Vermelho)**
```
[🔴 CLIENTE: JOÃO]
```
- Ao clicar: Remove cliente e volta ao modo normal
- Mensagem: "Voltou ao modo de venda normal"

---

## 📊 Indicadores Visuais

### **Resumo de Valores:**
- **Modo Normal:** Fundo azul
- **Modo Dívida:** Fundo vermelho + banner do cliente

### **Botão DÍVIDAS:**
- **Sem cliente:** 🟠 Laranja + "DÍVIDAS"
- **Com cliente:** 🔴 Vermelho + "CLIENTE: NOME"

### **Botão FINALIZAR:**
- **Desabilitado (cinza):** Falta pagar (modo normal)
- **Habilitado (verde):** Pode finalizar

---

## 🔧 Arquivos Modificados

### **1. dialog_pagamento.dart**
- ✅ Adicionado carregamento de clientes
- ✅ Variável `modoDivida` e `clienteSelecionado`
- ✅ Método `_selecionarCliente()` funcional
- ✅ Resumo muda de cor conforme modo
- ✅ Banner mostrando cliente selecionado
- ✅ Botão DÍVIDAS com estados visuais
- ✅ `_finalizarPagamento()` retorna dados completos

### **2. vendas_controller.dart**
- ✅ `finalizarVenda()` recebe Map ao invés de List
- ✅ `_processarVenda()` extrai dados do Map
- ✅ `_registrarDivida()` novo método privado
- ✅ Registra dívida se `modoDivida && valorRestante > 0`
- ✅ Removido lógica de clientes/dívidas da tela

### **3. vendas_page.dart**
- ✅ Botão CLIENTES voltou a "Em Desenvolvimento"
- ✅ Removido botão DÍVIDAS da tela
- ✅ Removido indicadores visuais do carrinho
- ✅ Header do carrinho simplificado

---

## ✅ Checklist de Verificação

- [x] Botão DÍVIDAS está no dialog de pagamento
- [x] Seleção de cliente abre ao clicar DÍVIDAS
- [x] Teclado virtual funciona na seleção
- [x] Cliente selecionado aparece no botão
- [x] Resumo muda de cor (vermelho)
- [x] Pode finalizar sem pagar tudo
- [x] Dívida é registrada automaticamente
- [x] Valor restante é calculado corretamente
- [x] Mensagem de sucesso mostra valor restante
- [x] Botão pode remover cliente (clicar novamente)

---

## 🎓 Exemplo Prático

### **Cenário: Cliente João deve MT 1500.00**

**1. Adicionar produtos:**
- 3x Produto A (MT 500 cada) = MT 1500.00

**2. FINALIZAR VENDA:**
- Dialog abre

**3. Clicar DÍVIDAS:**
- Dialog de clientes abre
- Pesquisar "João" no teclado
- Selecionar "João Silva"
- Clicar SELECIONAR

**4. De volta ao dialog:**
- Resumo vermelho
- "VENDA A CRÉDITO - João Silva"
- Botão: "CLIENTE: JOÃO"

**5. Pagamento parcial:**
- Digitar 500
- Clicar CASH
- Pagamento adicionado: MT 500.00
- Restante: MT 1000.00

**6. FINALIZAR PAGAMENTO:**
- Venda registrada
- Dívida registrada:
  - Cliente: João Silva
  - Total: MT 1500.00
  - Pago: MT 500.00
  - Restante: MT 1000.00
  - Status: PARCIAL

---

## 🔮 Próximos Passos (Opcional)

Para completar o sistema:

1. **Tela de Devedores**
   - Listar todos os clientes com dívidas
   - Usar view `v_devedores`
   - Mostrar total devendo

2. **Dialog de Pagamento de Dívida**
   - Selecionar dívida específica
   - Registrar pagamento
   - Usar function `registrar_pagamento_divida()`

3. **Histórico de Pagamentos**
   - Ver todos os pagamentos de uma dívida
   - Tabela `pagamentos_divida`

---

**🎉 Sistema de Dívidas Funcionando Corretamente!**

A implementação está agora no lugar correto: **dentro do dialog de pagamento**, conforme solicitado.
