# 💳 NOVA TELA DE PAGAMENTO - INSTRUÇÕES

## 🎉 O QUE FOI IMPLEMENTADO

Redesenhamos completamente a tela de pagamento do sistema PDV com as seguintes funcionalidades:

### ✨ Recursos Novos

1. **Formas de Pagamento em Grid 2x2**
   - Botões grandes e visuais
   - Ícones personalizados por forma (CASH, EMOLA, MPESA, POS)
   - Layout responsivo

2. **Teclado Numérico Customizado**
   - Números de 0 a 9
   - Ponto decimal (.)
   - Botão Backspace para apagar
   - Botão LIMPAR para zerar

3. **Múltiplas Formas de Pagamento**
   - Possibilidade de pagar com mais de uma forma
   - Exemplo: MT 100 em CASH + MT 50 em MPESA
   - Controle automático do valor restante
   - Lista de pagamentos adicionados com opção de remover

4. **Validações Inteligentes**
   - Não permite valor maior que o restante
   - Não permite finalizar sem pagar o total
   - Valor digitado deve ser maior que zero

5. **Interface Moderna**
   - Resumo visual dos valores
   - Feedback em tempo real
   - Cores indicativas (verde = pago, vermelho = restante)

---

## 🗄️ ALTERAÇÕES NO BANCO DE DADOS

### Nova Tabela: `pagamentos_venda`

```sql
CREATE TABLE pagamentos_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER NOT NULL REFERENCES vendas(id) ON DELETE CASCADE,
    forma_pagamento_id INTEGER NOT NULL REFERENCES formas_pagamento(id),
    valor DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Executar Script SQL

1. Abra o pgAdmin ou psql
2. Conecte ao database `pdv_system`
3. Execute o arquivo: `database/adicionar_pagamentos.sql`

```bash
# No psql:
\c pdv_system
\i database/adicionar_pagamentos.sql
```

---

## 📁 ARQUIVOS CRIADOS/MODIFICADOS

### Novos Arquivos

1. **database/adicionar_pagamentos.sql**
   - Script para criar tabela de pagamentos

2. **lib/app/data/models/pagamento_venda_model.dart**
   - Model para pagamentos de venda

3. **lib/app/data/repositories/pagamento_venda_repository.dart**
   - Repository para operações de pagamento

4. **lib/app/modules/vendas/widgets/teclado_numerico.dart**
   - Widget do teclado numérico customizado

5. **lib/app/modules/vendas/widgets/dialog_pagamento.dart**
   - Dialog completo de pagamento com grid e teclado

### Arquivos Modificados

1. **lib/app/data/repositories/venda_repository.dart**
   - Atualizado para salvar múltiplos pagamentos

2. **lib/app/modules/vendas/controllers/vendas_controller.dart**
   - Usa novo dialog de pagamento
   - Processa múltiplas formas

3. **lib/core/utils/windows_printer_service.dart**
   - Imprime todas as formas de pagamento no cupom

---

## 🚀 COMO USAR

### Fluxo de Pagamento

1. **Adicione produtos ao carrinho**
2. **Clique em "Finalizar Venda"**
3. **Na tela de pagamento:**
   - Digite o valor usando o teclado numérico
   - Clique na forma de pagamento desejada
   - O pagamento será adicionado à lista
   - Repita para adicionar mais pagamentos
   - Quando o total estiver pago, clique em "FINALIZAR PAGAMENTO"

### Exemplos de Uso

#### Exemplo 1: Pagamento Simples
- Total da venda: MT 150.00
- Digite: `150`
- Clique em: **CASH**
- Clique em: **FINALIZAR PAGAMENTO**

#### Exemplo 2: Pagamento Misto
- Total da venda: MT 250.00
- Digite: `100`
- Clique em: **CASH**
- Digite: `150`
- Clique em: **MPESA**
- Clique em: **FINALIZAR PAGAMENTO**

#### Exemplo 3: Corrigir Erro
- Digite um valor errado
- Use o botão **←** (Backspace) para apagar
- Ou clique em **LIMPAR** para zerar
- Digite o valor correto

---

## 🎨 LAYOUT DA TELA

```
┌─────────────────────────────────────────────────────┐
│  💳 PAGAMENTO                                   ✕   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  TOTAL DA VENDA:                    MT 250.00      │
│  Total Pago:                        MT 100.00      │
│  Restante:                          MT 150.00      │
│                                                     │
│  PAGAMENTOS ADICIONADOS:                           │
│  💵 CASH                 MT 100.00         [🗑]    │
│                                                     │
├──────────────────────┬──────────────────────────────┤
│ FORMAS DE PAGAMENTO  │          VALOR              │
│                      │                              │
│  ┌────┐  ┌────┐     │      MT 0.00                │
│  │💵  │  │📱  │     │                              │
│  │CASH│  │EMOL│     │    ┌───┬───┬───┐           │
│  └────┘  └────┘     │    │ 7 │ 8 │ 9 │           │
│                      │    ├───┼───┼───┤           │
│  ┌────┐  ┌────┐     │    │ 4 │ 5 │ 6 │           │
│  │📱  │  │💳  │     │    ├───┼───┼───┤           │
│  │MPES│  │POS │     │    │ 1 │ 2 │ 3 │           │
│  └────┘  └────┘     │    ├───┼───┼───┤           │
│                      │    │ . │ 0 │ ← │           │
│                      │    └───┴───┴───┘           │
│                      │                              │
│                      │    [ LIMPAR ]               │
└──────────────────────┴──────────────────────────────┘
│                                                     │
│          [ ✓ FINALIZAR PAGAMENTO ]                 │
└─────────────────────────────────────────────────────┘
```

---

## ✅ TESTES

### Teste 1: Pagamento Único
- [x] Adicionar produtos ao carrinho
- [x] Clicar em "Finalizar Venda"
- [x] Digitar valor total
- [x] Selecionar forma de pagamento
- [x] Finalizar deve funcionar

### Teste 2: Múltiplos Pagamentos
- [x] Total: MT 200
- [x] Adicionar: MT 100 em CASH
- [x] Adicionar: MT 100 em MPESA
- [x] Restante deve mostrar MT 0.00
- [x] Botão finalizar deve estar ativo

### Teste 3: Validações
- [x] Tentar adicionar valor 0 → deve mostrar erro
- [x] Tentar adicionar valor maior que restante → deve mostrar erro
- [x] Tentar finalizar sem pagar total → botão desabilitado

### Teste 4: Remoção
- [x] Adicionar pagamento
- [x] Clicar no ícone de lixeira
- [x] Pagamento deve ser removido
- [x] Restante deve atualizar

### Teste 5: Teclado
- [x] Digitar números → deve aparecer no campo
- [x] Clicar em ponto → adiciona decimal
- [x] Clicar backspace → remove último dígito
- [x] Clicar limpar → zera o valor

### Teste 6: Impressão
- [x] Finalizar venda com múltiplas formas
- [x] Escolher imprimir
- [x] Cupom deve mostrar todas as formas de pagamento
- [x] Valores devem estar corretos

### Teste 7: Banco de Dados
```sql
-- Verificar última venda com pagamentos
SELECT
    v.numero,
    v.total,
    pv.forma_pagamento_id,
    fp.nome,
    pv.valor
FROM vendas v
INNER JOIN pagamentos_venda pv ON v.id = pv.venda_id
INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
WHERE v.id = (SELECT MAX(id) FROM vendas);
```

---

## 🎯 BENEFÍCIOS

### Para o Usuário
✅ Interface mais intuitiva e visual
✅ Teclado grande e fácil de usar
✅ Controle total sobre formas de pagamento
✅ Feedback visual em tempo real

### Para o Negócio
✅ Rastreamento preciso de formas de pagamento
✅ Relatórios mais detalhados
✅ Melhor controle financeiro
✅ Redução de erros

### Para o Sistema
✅ Dados estruturados no banco
✅ Histórico completo de pagamentos
✅ Facilita auditorias
✅ Base para futuras funcionalidades

---

## 🔮 PRÓXIMAS FUNCIONALIDADES SUGERIDAS

- [ ] Relatório de vendas por forma de pagamento
- [ ] Gráfico de formas mais utilizadas
- [ ] Troco automático (para pagamento em dinheiro)
- [ ] Integração com APIs de pagamento (M-Pesa, eMola)
- [ ] Suporte a vouchers/cupons de desconto
- [ ] Parcelamento em cartão

---

## 📊 ESTATÍSTICAS DE PAGAMENTO

Após usar o sistema, você pode gerar estatísticas:

```sql
-- Formas de pagamento mais usadas
SELECT
    fp.nome,
    COUNT(pv.id) as total_usos,
    SUM(pv.valor) as valor_total
FROM pagamentos_venda pv
INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
GROUP BY fp.nome
ORDER BY total_usos DESC;

-- Vendas com múltiplas formas de pagamento
SELECT
    v.numero,
    v.total,
    COUNT(pv.id) as formas_utilizadas
FROM vendas v
INNER JOIN pagamentos_venda pv ON v.id = pv.venda_id
GROUP BY v.id, v.numero, v.total
HAVING COUNT(pv.id) > 1
ORDER BY v.data_venda DESC;
```

---

**Desenvolvido com ❤️ para Frentex e Serviços**

*Nova Tela de Pagamento v1.0 - Novembro 2025*
