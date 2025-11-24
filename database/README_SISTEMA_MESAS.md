# Sistema de Mesas e Pedidos

Sistema completo para gerenciar mesas e pedidos no restaurante.

## 📋 Funcionalidades

### 1. **Gestão de Mesas**
- Criar locais (BALCAO, SALA, ESPLANADA)
- Adicionar mesas em cada local
- Criar mesas em lote
- Visualizar status das mesas (Livre, Ocupada, Inativa)

### 2. **Sistema de Pedidos**
- Adicionar produtos ao carrinho
- Selecionar mesa para enviar pedido
- Botão dinâmico:
  - **PEDIDOS** quando carrinho vazio
  - **MESA** quando há produtos no carrinho (muda cor para laranja)
- Ver mesas com pedidos abertos
- Ver total e responsável de cada mesa

### 3. **Segurança**
- Usuários normais veem apenas:
  - Suas próprias mesas ocupadas
  - Todas as mesas livres
- Administradores (com permissão `gestao_mesas`) veem todas as mesas

## 🗄️ Estrutura do Banco de Dados

### Tabelas Criadas:
1. **locais_mesa** - Locais onde as mesas estão (BALCAO, SALA, ESPLANADA)
2. **mesas** - Mesas do restaurante
3. **pedidos** - Pedidos realizados nas mesas
4. **itens_pedido** - Itens de cada pedido

### Views Criadas:
1. **v_mesas_completo** - Mesas com informações completas (pedidos, usuários, totais)
2. **v_pedidos_abertos** - Pedidos em aberto
3. **v_mesas_por_local** - Resumo de mesas por local

## 🚀 Instalação

### 1. Executar Scripts SQL (na ordem):

```bash
# 1. Criar estrutura de mesas e pedidos
psql -U postgres -d posfaturix -f database/sistema_mesas_pedidos.sql

# 2. Adicionar permissão gestao_mesas
psql -U postgres -d posfaturix -f database/adicionar_permissao_mesas.sql
```

### 2. Configurar Mesas no Admin

1. Abra a aplicação como **Administrador**
2. Vá em **Admin → Mesas**
3. Os locais padrão (BALCAO, SALA, ESPLANADA) já estarão criados
4. Para cada local, clique no ícone `+` verde
5. Configure:
   - **Número Inicial**: 1 (para BALCAO), 2 (para SALA), 3 (para ESPLANADA)
   - **Quantidade**: Quantas mesas deseja criar

#### Exemplo de Configuração (baseado na imagem):

| Local      | Número Inicial | Quantidade | Mesas Criadas    |
|------------|----------------|------------|------------------|
| BALCAO     | 1              | 5          | 1, 6, 11, 16, etc|
| SALA       | 2              | 5          | 2, 7, 12, 17, etc|
| ESPLANADA  | 3              | 30         | 3, 4, 5, 8, 9, etc|

**Observação**: O sistema cria as mesas sequencialmente. Para ter o layout da imagem (40 mesas no total), você pode:
- Criar mesas manualmente com números específicos, ou
- Ajustar a lógica para distribuir melhor

## 📱 Como Usar

### Fluxo de Vendas com Mesas:

1. **Adicionar Produtos ao Carrinho**
   - Selecione área (BAR, COZINHA)
   - Selecione família
   - Clique nos produtos para adicionar

2. **Enviar para Mesa**
   - Clique no botão **MESA** (laranja, com ícone de mesa)
   - Selecione a mesa disponível (azul escuro)
   - Confirme

3. **Visualizar Mesas Ocupadas**
   - Mesas com pedidos aparecem em amarelo
   - Mostram: Valor total e nome do usuário responsável

4. **Finalizar Pedido da Mesa**
   - Será implementado em breve
   - Por enquanto, os pedidos ficam registrados nas mesas

## 🔒 Permissões

### Permissão: `gestao_mesas`
- Permite acessar a configuração de mesas no Admin
- Ver todas as mesas (de todos os usuários)
- Criar e editar locais e mesas

### Sem Permissão:
- Pode usar mesas normalmente em Vendas
- Vê apenas suas próprias mesas ocupadas + mesas livres
- Não acessa configuração no Admin

## 📊 Visualização de Mesas

### Cores das Mesas:
- 🟦 **Azul Escuro** - Mesa Livre (pode ser selecionada)
- 🟨 **Amarelo** - Mesa Ocupada (mostra total e usuário)
- ⬜ **Cinza** - Mesa Inativa

### Layout do Dialog:
```
┌─────────────┬──────────────────────────────────────────┐
│  BALCAO     │  [1]  [6]  [11] [16] [21] [26] [31] [36]│
│  SALA       │  [2]  [7]  [12] [17] [22] [27] [32] [37]│
│  ESPLANADA  │  [3]  [8]  [13] [18] [23] [28] [33] [38]│
│             │  [4]  [9]  [14] [19] [24] [29] [34] [39]│
│             │  [5]  [10] [15] [20] [25] [30] [35] [40]│
└─────────────┴──────────────────────────────────────────┘
 Legenda: 🟦 Livre  🟨 Ocupada  ⬜ Inativa
```

## 🔄 Próximos Passos

- [ ] Finalizar pedido e converter em venda
- [ ] Transferir pedido entre mesas
- [ ] Juntar mesas
- [ ] Dividir conta
- [ ] Imprimir comanda
- [ ] Relatório de mesas

## 📝 Notas Importantes

1. **Não excluir mesas com pedidos abertos**
   - O sistema impede (ON DELETE RESTRICT)

2. **Trigger automático**
   - O total do pedido é calculado automaticamente ao adicionar/remover itens

3. **Usuários precisam estar logados**
   - O sistema usa o usuário logado para associar pedidos

## 🐛 Troubleshooting

### "Usuário não autenticado"
- Certifique-se de estar logado
- Verifique se AuthService está configurado

### "Nenhuma mesa disponível"
- Verifique se as mesas foram criadas no Admin
- Verifique permissões do usuário

### Mesas não aparecem no dialog
- Execute o script SQL `sistema_mesas_pedidos.sql`
- Verifique se os locais foram criados
- Recarregue os dados

## 📚 Arquivos Criados

### Database:
- `database/sistema_mesas_pedidos.sql` - Estrutura completa
- `database/adicionar_permissao_mesas.sql` - Permissão gestao_mesas

### Models:
- `lib/app/data/models/local_mesa_model.dart`
- `lib/app/data/models/mesa_model.dart`
- `lib/app/data/models/pedido_model.dart`
- `lib/app/data/models/item_pedido_model.dart`

### Repositories:
- `lib/app/data/repositories/local_mesa_repository.dart`
- `lib/app/data/repositories/mesa_repository.dart`
- `lib/app/data/repositories/pedido_repository.dart`

### Views:
- `lib/app/modules/admin/views/mesas_tab.dart` - Configuração no Admin
- `lib/app/modules/vendas/widgets/dialog_selecao_mesa.dart` - Dialog de seleção

### Controllers:
- Métodos adicionados em `vendas_controller.dart`:
  - `abrirSelecaoMesa()`
  - `_criarPedidoNaMesa()`
  - `textoBotaoPedido` getter
  - `temProdutosNoCarrinho` getter

---

**Sistema implementado com sucesso! 🎉**
