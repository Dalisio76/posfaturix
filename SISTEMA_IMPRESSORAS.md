# 🖨️ SISTEMA DE GESTÃO DE IMPRESSORAS

Sistema completo de gerenciamento de impressoras com impressão automática por área e mapeamento de documentos.

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Funcionalidades](#funcionalidades)
3. [Estrutura do Banco de Dados](#estrutura-do-banco-de-dados)
4. [Como Usar](#como-usar)
5. [Integração com o Sistema](#integração-com-o-sistema)
6. [Exemplos de Uso](#exemplos-de-uso)

---

## 🎯 Visão Geral

O sistema permite:
- **Cadastrar impressoras** com nome, tipo e largura de papel
- **Mapear documentos para impressoras** (ex: recibo vai para impressora X)
- **Associar impressoras às áreas** (ex: cozinha imprime na impressora da cozinha)
- **Impressão automática de pedidos** por área (cozinha, bar, etc)

---

## ✨ Funcionalidades

### 1. Gestão de Impressoras

**Localização:** Admin > Sistema & Segurança > Impressoras

- ✅ Adicionar/Editar/Remover impressoras
- ✅ Configurar nome, tipo (térmica/matricial/laser) e largura do papel (58mm/80mm)
- ✅ Ativar/Desativar impressoras
- ✅ Visualização em cards modernos e touch-friendly

### 2. Mapeamento de Documentos

**Localização:** Admin > Sistema & Segurança > Mapeamento Impressão

- ✅ Definir qual impressora usa para cada tipo de documento
- ✅ Tipos de documento disponíveis:
  - **RECIBO_VENDA** - Recibo de venda
  - **CONTA_MESA** - Conta da mesa
  - **PEDIDO_COZINHA** - Pedido para cozinha
  - **PEDIDO_BAR** - Pedido para bar
  - **COTACAO** - Cotação
  - **FECHO_CAIXA** - Fechamento de caixa

### 3. Impressoras por Área

**Localização:** Admin > Sistema & Segurança > Áreas

- ✅ Ao cadastrar/editar área, selecionar impressora padrão
- ✅ Quando adicionar produtos da área em pedidos → imprime automaticamente
- ✅ Exemplo:
  - Área "Cozinha" → Impressora "Cozinha"
  - Área "Bar" → Impressora "Bar"

---

## 🗄️ Estrutura do Banco de Dados

### Arquivo SQL
`database/sistema_impressoras.sql`

### Tabelas Criadas

#### 1. `impressoras`
```sql
id SERIAL PRIMARY KEY
nome VARCHAR(100) UNIQUE
tipo VARCHAR(50) -- 'termica', 'matricial', 'laser'
descricao TEXT
largura_papel INTEGER -- 58, 80, etc (em mm)
ativo BOOLEAN
created_at TIMESTAMP
updated_at TIMESTAMP
```

#### 2. `tipos_documento`
```sql
id SERIAL PRIMARY KEY
codigo VARCHAR(50) UNIQUE -- 'RECIBO_VENDA', 'CONTA_MESA', etc
nome VARCHAR(100)
descricao TEXT
ativo BOOLEAN
```

#### 3. `documento_impressora`
Mapeamento N:N entre documentos e impressoras
```sql
id SERIAL PRIMARY KEY
tipo_documento_id INTEGER → tipos_documento(id)
impressora_id INTEGER → impressoras(id)
prioridade INTEGER -- caso haja backup
```

#### 4. Alteração em `areas`
```sql
ALTER TABLE areas ADD COLUMN impressora_id INTEGER → impressoras(id)
```

### Views Criadas

**`vw_mapeamento_impressao`**
- Lista documentos e suas impressoras

**`vw_areas_impressoras`**
- Lista áreas com suas impressoras

---

## 🚀 Como Usar

### Passo 1: Executar o SQL

```bash
# No PostgreSQL, executar:
psql -U seu_usuario -d nome_banco -f database/sistema_impressoras.sql
```

### Passo 2: Cadastrar Impressoras

1. Vá em **Admin > Sistema & Segurança > Impressoras**
2. Clique em **ADICIONAR IMPRESSORA**
3. Preencha:
   - Nome: Ex: "Impressora Cozinha"
   - Tipo: Térmica / Matricial / Laser
   - Largura: 58mm / 80mm
   - Descrição: (opcional)
   - Ativa: Sim
4. Salvar

**Exemplo:**
- Nome: `Impressora Cozinha`
- Tipo: `Térmica`
- Largura: `80mm`

### Passo 3: Associar Impressoras às Áreas

1. Vá em **Admin > Sistema & Segurança > Áreas**
2. Edite a área "Cozinha"
3. Selecione a impressora: `Impressora Cozinha`
4. Salvar

Faça o mesmo para:
- **Área "Bar"** → `Impressora Bar`
- **Área "Esplanada"** → `Impressora Esplanada` (ou deixe sem impressora)

### Passo 4: Mapear Documentos (Opcional)

1. Vá em **Admin > Sistema & Segurança > Mapeamento Impressão**
2. Para cada tipo de documento, selecione a impressora:
   - **RECIBO_VENDA** → `Impressora Principal`
   - **CONTA_MESA** → `Impressora Principal`
   - **PEDIDO_COZINHA** → `Impressora Cozinha`
   - **PEDIDO_BAR** → `Impressora Bar`
   - **FECHO_CAIXA** → `Impressora Principal`

---

## 🔗 Integração com o Sistema

### Arquivos Criados/Modificados

#### Novos Arquivos

**Models:**
- `lib/app/data/models/impressora_model.dart`
  - `ImpressoraModel`
  - `TipoDocumentoModel`
  - `DocumentoImpressoraModel`

**Repositories:**
- `lib/app/data/repositories/impressora_repository.dart`
  - Métodos CRUD de impressoras
  - Métodos de mapeamento
  - Métodos de busca por área/documento

**Views:**
- `lib/app/modules/admin/views/impressoras_tab.dart` - Gestão de impressoras
- `lib/app/modules/admin/views/mapeamento_impressoras_tab.dart` - Mapeamento documentos

**Services:**
- `lib/core/services/impressao_service.dart` - Serviço centralizado de impressão

#### Arquivos Modificados

**Area Model:**
- `lib/app/data/models/area_model.dart`
  - Adicionado: `impressoraId`, `impressoraNome`
  - Adicionado método `copyWith()`

**Area Repository:**
- `lib/app/data/repositories/area_repository.dart`
  - Queries agora fazem LEFT JOIN com impressoras
  - INSERT/UPDATE incluem `impressora_id`

**Area Tab:**
- `lib/app/modules/admin/views/areas_tab.dart`
  - Dropdown para selecionar impressora
  - Mostra impressora associada na listagem

**Admin Controller:**
- `lib/app/modules/admin/controllers/admin_controller.dart`
  - `adicionarArea()` aceita `impressoraId`
  - `editarArea()` aceita `impressoraId`

**Admin Page:**
- `lib/app/modules/admin/admin_page.dart`
  - Imports das novas tabs
  - Adicionado menu "Impressoras"
  - Adicionado menu "Mapeamento Impressão"

---

## 💡 Exemplos de Uso

### Exemplo 1: Imprimir Pedido na Impressora da Área

```dart
import 'package:seu_projeto/core/services/impressao_service.dart';

// Quando adicionar produtos da cozinha em um pedido
Future<void> adicionarProdutosCozinha() async {
  final itensCozinha = [
    {'quantidade': 2, 'nome': 'Hamburguer', 'observacoes': 'Sem cebola'},
    {'quantidade': 1, 'nome': 'Batata Frita', 'observacoes': null},
  ];

  final conteudo = ImpressaoService.formatarPedidoArea(
    nomeMesa: 'Mesa 5',
    nomeArea: 'Cozinha',
    itens: itensCozinha,
    observacoes: 'Cliente com pressa',
  );

  final sucesso = await ImpressaoService.imprimirPedidoArea(
    areaId: 1, // ID da área Cozinha
    conteudo: conteudo,
  );

  if (sucesso) {
    print('✅ Pedido impresso na cozinha!');
  }
}
```

### Exemplo 2: Imprimir Recibo de Venda

```dart
// Ao finalizar venda
Future<void> finalizarVenda() async {
  final conteudoRecibo = gerarReciboVenda(); // Sua função de gerar recibo

  final sucesso = await ImpressaoService.imprimirDocumento(
    tipoDocumento: 'RECIBO_VENDA',
    conteudo: conteudoRecibo,
  );

  if (sucesso) {
    print('✅ Recibo impresso!');
  }
}
```

### Exemplo 3: Imprimir Diretamente em uma Impressora

```dart
Future<void> imprimirUrgente() async {
  await ImpressaoService.imprimirNaImpressora(
    impressoraNome: 'Impressora Cozinha',
    conteudo: 'PEDIDO URGENTE!\n\n3x Pizza\n2x Refrigerante',
  );
}
```

### Exemplo 4: Verificar se Área Tem Impressora

```dart
Future<void> verificarImpressao() async {
  final temImpressora = await ImpressaoService.areaTemImpressora(1);

  if (temImpressora) {
    print('✅ Área possui impressora configurada');
  } else {
    print('⚠️ Área sem impressora - pedido não será impresso');
  }
}
```

---

## 🎨 Interface do Usuário

### Tela de Impressoras

- **Cards visuais** com ícone, nome, tipo, largura, status
- **Ações:** Editar, Deletar
- **Filtros:** Por status (ativa/inativa)
- **Touch-friendly:** Botões grandes, espaçamento adequado

### Tela de Mapeamento

- **Cards por documento** com dropdown de impressoras
- **Cores diferentes** por tipo de documento
- **Contador:** "X de Y documentos mapeados"
- **Descrições:** Explica o que cada documento faz

### Tela de Áreas (Atualizada)

- **Dropdown de impressoras** ao criar/editar área
- **Indicador visual:** Mostra qual impressora está associada
- **Info box:** Explica que produtos da área serão impressos automaticamente

---

## ⚙️ Configuração Avançada

### Adicionar Novo Tipo de Documento

```sql
INSERT INTO tipos_documento (codigo, nome, descricao)
VALUES (
  'MEU_DOCUMENTO',
  'Meu Documento Personalizado',
  'Descrição do documento'
);
```

### Múltiplas Impressoras para Mesmo Documento (Backup)

```sql
-- Impressora principal (prioridade 1)
INSERT INTO documento_impressora (tipo_documento_id, impressora_id, prioridade)
VALUES (1, 1, 1);

-- Impressora backup (prioridade 2)
INSERT INTO documento_impressora (tipo_documento_id, impressora_id, prioridade)
VALUES (1, 2, 2);
```

---

## 🔜 Próximos Passos

### TODO: Integração com Impressão Real

O serviço `ImpressaoService` atualmente apenas loga. Para integrar com impressoras reais:

1. **Instalar dependências:**
```yaml
dependencies:
  esc_pos_printer: ^4.1.0
  esc_pos_utils: ^1.1.0
```

2. **Implementar no `ImpressaoService`:**
```dart
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

static Future<bool> _imprimirReal(ImpressoraModel impressora, String conteudo) async {
  try {
    final printer = NetworkPrinter(
      PaperSize.mm80, // ou mm58 conforme impressora.larguraPapel
      await CapabilityProfile.load(),
    );

    final result = await printer.connect(impressora.nome, port: 9100);

    if (result == PosPrintResult.success) {
      printer.text(conteudo);
      printer.feed(3);
      printer.cut();
      printer.disconnect();
      return true;
    }

    return false;
  } catch (e) {
    print('Erro na impressão real: $e');
    return false;
  }
}
```

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs do console
2. Confira se as impressoras estão ativas
3. Verifique se as áreas estão associadas corretamente
4. Teste o mapeamento de documentos

---

## 🎉 Conclusão

Sistema completo de impressoras implementado com:
- ✅ Gestão visual de impressoras
- ✅ Mapeamento flexível de documentos
- ✅ Associação de impressoras às áreas
- ✅ Serviço centralizado de impressão
- ✅ Interface moderna e touch-friendly
- ✅ Pronto para integração com hardware real

**Benefícios:**
- 🚀 Impressão automática por área (cozinha, bar)
- 🎯 Configuração centralizada
- 🔧 Fácil manutenção
- 📱 Interface intuitiva
- 🔄 Escalável para novos tipos de documentos
