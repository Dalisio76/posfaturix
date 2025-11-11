# 🛒 POSFaturix - Sistema PDV Completo

> Sistema de Ponto de Venda (PDV) desenvolvido em Flutter com PostgreSQL, focado em gestão de vendas, clientes, produtos, dívidas e despesas.

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791?logo=postgresql)](https://www.postgresql.org/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![GetX](https://img.shields.io/badge/GetX-4.6.6-7952B3)](https://pub.dev/packages/get)

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades](#-funcionalidades)
- [Tecnologias](#-tecnologias)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Banco de Dados](#-banco-de-dados)
- [Como Usar](#-como-usar)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

---

## 🎯 Sobre o Projeto

**POSFaturix** é um sistema completo de PDV (Ponto de Venda) desenvolvido especificamente para o mercado moçambicano, com suporte nativo a **Meticais (MT)**, múltiplas formas de pagamento (CASH, EMOLA, MPESA, POS) e gestão avançada de dívidas.

### Características Principais

- ✅ **Interface Moderna e Responsiva** - Design otimizado para desktop, tablets e touch screens
- ✅ **Gestão Completa de Vendas** - Carrinho inteligente, desconto por produto, múltiplas formas de pagamento
- ✅ **Sistema de Dívidas Avançado** - Pagamentos parcelados, histórico completo, alertas de vencimento
- ✅ **Impressão Automática** - Recibos térmicos 80mm com layout profissional
- ✅ **Relatórios em Tempo Real** - Vendas do dia, produtos mais vendidos, análise de despesas
- ✅ **Gestão de Estoque** - Controle de produtos, categorias e movimentações
- ✅ **Multi-usuário** - Sistema preparado para múltiplos operadores

---

## 🚀 Funcionalidades

### 📦 Gestão de Produtos
- ✓ Cadastro completo de produtos (nome, preço, estoque, categoria)
- ✓ Categorização de produtos
- ✓ Busca rápida com teclado QWERTY virtual
- ✓ Controle de estoque em tempo real
- ✓ Alertas de estoque baixo

### 💰 Sistema de Vendas
- ✓ Carrinho de compras intuitivo
- ✓ Desconto por produto ou venda completa
- ✓ Múltiplas formas de pagamento (CASH, EMOLA, MPESA, POS)
- ✓ Pagamento misto (ex: parte em dinheiro, parte em MPESA)
- ✓ Cálculo automático de troco
- ✓ Impressão automática de recibos
- ✓ Histórico completo de vendas

### 👥 Gestão de Clientes
- ✓ Cadastro completo (nome, contactos, endereço, NUIT)
- ✓ Histórico de compras
- ✓ Listagem de dívidas por cliente
- ✓ Filtros avançados (por cliente, data, status)

### 💳 Sistema de Dívidas
- ✓ Registro de vendas a crédito
- ✓ **Pagamentos parcelados** - Cliente pode pagar em múltiplas vezes
- ✓ Histórico completo de pagamentos
- ✓ Status automático (PENDENTE → PARCIAL → PAGO)
- ✓ Atalhos rápidos (50%, TOTAL)
- ✓ Observações por pagamento (ex: "Parcela 1/3")
- ✓ Resumo financeiro (Total, Pago, Restante)
- ✓ Alertas visuais com cores (🔴 Pendente | 🟠 Parcial | 🟢 Pago)

### 💸 Gestão de Despesas
- ✓ Registro de despesas operacionais
- ✓ Categorização (Aluguel, Fornecedores, Salários, etc.)
- ✓ Anexo de comprovantes
- ✓ Relatórios por período
- ✓ Análise de fluxo de caixa

### 📊 Relatórios e Dashboards
- ✓ Vendas do dia/mês/ano
- ✓ Produtos mais vendidos
- ✓ Análise de formas de pagamento
- ✓ Total em dívidas (ativo/recebido)
- ✓ Despesas por categoria
- ✓ Margem de lucro

### 🖨️ Impressão
- ✓ Recibos térmicos 80mm
- ✓ Layout profissional com logo
- ✓ Código de barras/QR Code (futuro)
- ✓ Impressão silenciosa em background

---

## 🛠️ Tecnologias

### Frontend
- **Flutter 3.9.2** - Framework multiplataforma
- **Dart 3.0+** - Linguagem de programação
- **GetX 4.6.6** - Gerenciamento de estado e navegação
- **Google Fonts** - Tipografia customizada
- **Material Design 3** - Design system

### Backend
- **PostgreSQL 15+** - Banco de dados relacional
- **Stored Procedures** - Lógica de negócio no banco
- **Views Materializadas** - Performance otimizada
- **Triggers** - Automação de processos

### Bibliotecas Principais
```yaml
dependencies:
  get: ^4.6.6              # Estado e Navegação
  postgres: ^3.0.0         # Conexão PostgreSQL
  printing: ^5.13.4        # Impressão Windows
  pdf: ^3.11.1             # Geração de PDFs
  intl: ^0.18.1            # Formatação (datas, moedas)
  google_fonts: ^6.1.0     # Fontes customizadas
```

---

## 📋 Pré-requisitos

Antes de começar, você precisa ter instalado:

- [Flutter SDK 3.9.2+](https://flutter.dev/docs/get-started/install)
- [Dart 3.0+](https://dart.dev/get-dart)
- [PostgreSQL 15+](https://www.postgresql.org/download/)
- [Git](https://git-scm.com/)
- Editor de código (VS Code recomendado)

---

## 🔧 Instalação

### 1️⃣ Clone o repositório

```bash
git clone https://github.com/seu-usuario/posfaturix.git
cd posfaturix
```

### 2️⃣ Instale as dependências

```bash
flutter pub get
```

### 3️⃣ Configure o Banco de Dados

#### Criar banco de dados PostgreSQL

```bash
# Entre no PostgreSQL
psql -U postgres

# Crie o banco
CREATE DATABASE posfaturix;

# Conecte ao banco
\c posfaturix
```

#### Execute os scripts SQL

```bash
# No diretório database/
psql -U postgres -d posfaturix -f 01_estrutura_inicial.sql
psql -U postgres -d posfaturix -f 02_views_e_funcoes.sql
psql -U postgres -d posfaturix -f 03_dados_iniciais.sql
```

### 4️⃣ Configure a conexão

Edite o arquivo `lib/core/database/database_service.dart`:

```dart
final connection = await Connection.open(
  Endpoint(
    host: 'localhost',        // Seu host
    database: 'posfaturix',   // Nome do banco
    username: 'postgres',     // Seu usuário
    password: 'sua_senha',    // Sua senha
  ),
  settings: ConnectionSettings(sslMode: SslMode.disable),
);
```

⚠️ **Importante**: Nunca commite senhas no GitHub! Use variáveis de ambiente.

### 5️⃣ Execute o projeto

```bash
flutter run -d windows
```

---

## 📁 Estrutura do Projeto

```
posfaturix/
├── lib/
│   ├── app/
│   │   ├── data/
│   │   │   ├── models/              # Modelos de dados
│   │   │   │   ├── produto_model.dart
│   │   │   │   ├── venda_model.dart
│   │   │   │   ├── cliente_model.dart
│   │   │   │   ├── divida_model.dart
│   │   │   │   └── despesa_model.dart
│   │   │   └── repositories/        # Acesso ao banco
│   │   │       ├── produto_repository.dart
│   │   │       ├── venda_repository.dart
│   │   │       ├── cliente_repository.dart
│   │   │       ├── divida_repository.dart
│   │   │       └── despesa_repository.dart
│   │   │
│   │   └── modules/
│   │       ├── vendas/              # Módulo principal de vendas
│   │       │   ├── controllers/
│   │       │   ├── views/
│   │       │   └── widgets/
│   │       │       ├── dialog_pagamento.dart
│   │       │       ├── dialog_pagamento_divida.dart
│   │       │       ├── dialog_detalhes_divida.dart
│   │       │       └── teclado_numerico.dart
│   │       │
│   │       ├── admin/               # Cadastros e configurações
│   │       └── home/                # Dashboard e relatórios
│   │
│   ├── core/
│   │   ├── database/                # Serviço PostgreSQL
│   │   ├── theme/                   # Tema da aplicação
│   │   └── utils/                   # Utilitários e helpers
│   │
│   └── main.dart                    # Ponto de entrada
│
├── database/
│   ├── 01_estrutura_inicial.sql     # Tabelas e índices
│   ├── 02_views_e_funcoes.sql       # Views e stored procedures
│   └── 03_dados_iniciais.sql        # Dados de teste
│
├── docs/                            # Documentação técnica
├── assets/                          # Imagens e recursos
├── pubspec.yaml                     # Dependências
└── README.md                        # Este arquivo
```

---

## 🗄️ Banco de Dados

### Esquema Principal

```
┌─────────────┐       ┌──────────────┐       ┌────────────┐
│  produtos   │       │    vendas    │       │  clientes  │
├─────────────┤       ├──────────────┤       ├────────────┤
│ id          │◄──┐   │ id           │   ┌──►│ id         │
│ nome        │   │   │ numero       │   │   │ nome       │
│ preco       │   │   │ data_venda   │   │   │ contacto   │
│ estoque     │   │   │ valor_total  │   │   │ email      │
│ categoria   │   │   │ cliente_id   │───┘   │ nuit       │
└─────────────┘   │   └──────────────┘       └────────────┘
                  │            │
                  │            │
                  │   ┌────────▼──────────┐
                  │   │  itens_venda      │
                  │   ├───────────────────┤
                  └───┤ produto_id        │
                      │ venda_id          │
                      │ quantidade        │
                      │ preco_unitario    │
                      │ subtotal          │
                      └───────────────────┘
                                │
                                │
              ┌─────────────────┴──────────────────┐
              │                                     │
     ┌────────▼────────┐               ┌───────────▼────────┐
     │    dividas      │               │ pagamentos_venda   │
     ├─────────────────┤               ├────────────────────┤
     │ id              │               │ venda_id           │
     │ cliente_id      │               │ forma_pagamento_id │
     │ venda_id        │               │ valor              │
     │ valor_total     │               └────────────────────┘
     │ valor_pago      │
     │ valor_restante  │
     │ status          │
     └─────────────────┘
              │
              │
     ┌────────▼────────────┐
     │ pagamentos_divida   │
     ├─────────────────────┤
     │ divida_id           │
     │ valor               │
     │ forma_pagamento_id  │
     │ data_pagamento      │
     │ observacoes         │
     └─────────────────────┘
```

### Stored Procedures Principais

- `registrar_venda()` - Registra uma venda completa com itens e pagamentos
- `registrar_pagamento_divida()` - Registra pagamento parcial/total de dívida
- `atualizar_estoque()` - Atualiza estoque após venda
- `calcular_total_dividas_cliente()` - Calcula total de dívidas por cliente

---

## 💻 Como Usar

### 1. Realizar uma Venda

1. Clique em **"PRODUTOS"** no menu lateral
2. Busque produtos ou navegue por categoria
3. Clique nos produtos para adicionar ao carrinho
4. Ajuste quantidades ou aplique descontos
5. Clique **"FINALIZAR VENDA"**
6. Selecione forma(s) de pagamento
7. Confirme e imprima o recibo

### 2. Vender a Crédito (Com Dívida)

1. Adicione produtos ao carrinho
2. Clique **"FINALIZAR VENDA"**
3. (Opcional) Adicione pagamento parcial
4. Clique em **"DÍVIDAS"** (botão laranja)
5. Selecione o cliente
6. Confirme a venda a crédito

### 3. Registrar Pagamento de Dívida

1. Clique em **"CLIENTES"** (botão verde)
2. Filtre e selecione uma dívida
3. Clique na dívida para ver detalhes
4. Clique **"REGISTRAR PAGAMENTO"**
5. Selecione forma de pagamento
6. Digite o valor (use atalhos 50% ou TOTAL)
7. Adicione observação (ex: "Parcela 1/3")
8. Confirme o pagamento

### 4. Cadastrar Cliente

1. Vá para **Admin → Clientes**
2. Clique **"+ NOVO CLIENTE"**
3. Preencha os dados
4. Salve o cadastro

### 5. Registrar Despesa

1. Vá para **Despesas**
2. Clique **"+ NOVA DESPESA"**
3. Preencha categoria, valor e descrição
4. (Opcional) Anexe comprovante
5. Salve o registro

---

## 🔄 Roadmap

### ✅ Implementado
- [x] Sistema completo de vendas
- [x] Gestão de produtos e categorias
- [x] Gestão de clientes
- [x] Sistema de dívidas com pagamentos parcelados
- [x] Gestão de despesas
- [x] Impressão de recibos
- [x] Relatórios básicos

### 🚧 Em Desenvolvimento
- [ ] Dashboard avançado com gráficos
- [ ] Exportação de relatórios (Excel, PDF)
- [ ] Sistema de backup automático
- [ ] Notificações de dívidas vencidas

### 📅 Planejado
- [ ] Integração com API EMOLA/MPESA
- [ ] App mobile (Android/iOS)
- [ ] Sistema multi-loja
- [ ] API REST para integrações
- [ ] Sistema de fidelidade
- [ ] Gestão de fornecedores
- [ ] Controle de comissões de vendedores

---

## 🤝 Contribuindo

Contribuições são sempre bem-vindas! Siga os passos:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Frentex**

- GitHub: [@frentex](https://github.com/frentex)

---

## 🙏 Agradecimentos

- Flutter Team pelo excelente framework
- Comunidade PostgreSQL
- GetX Package contributors
- Todos que contribuíram com feedback e sugestões

---

## 📞 Suporte

Se você encontrar algum problema ou tiver sugestões:

- Abra uma [Issue](https://github.com/seu-usuario/posfaturix/issues)
- Entre em contato via email: seuemail@exemplo.com

---

<div align="center">

**Desenvolvido com ❤️ para o mercado moçambicano**

⭐ Se este projeto te ajudou, deixe uma estrela!

</div>
