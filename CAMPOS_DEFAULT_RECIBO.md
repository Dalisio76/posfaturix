# Campos DEFAULT no Recibo de Venda

Este documento lista todos os campos que estão usando valores **DEFAULT (padrão)** no recibo de venda e onde substituí-los pelos valores reais quando forem implementados no sistema.

---

## 📋 Campos com Valores DEFAULT

### 1. **IVA (Taxa de Imposto)**

**Valor Atual:** 16% (0.16)
**Localização:** `lib/core/config/print_layout_config.dart:114`
**Código:**
```dart
static const double taxaIVAPadrao = 0.16;
```

**Como substituir:**
```dart
// NO ARQUIVO: lib/core/utils/windows_printer_service.dart
// LINHA: 62

// ATUAL (DEFAULT):
final valorIVA = subtotal * taxaIVA;

// SUBSTITUA POR (quando tiver IVA real no banco):
final valorIVA = item.iva ?? (subtotal * taxaIVA); // Usar IVA do produto/venda
```

---

### 2. **DESCONTO**

**Valor Atual:** 0.00
**Localização:** `lib/core/config/print_layout_config.dart:117`
**Código:**
```dart
static const double descontoPadrao = 0.0;
```

**Como substituir:**
```dart
// NO ARQUIVO: lib/core/utils/windows_printer_service.dart
// LINHA: 63

// ATUAL (DEFAULT):
final desconto = PrintLayoutConfig.descontoPadrao;

// SUBSTITUA POR (quando tiver desconto real):
final desconto = venda.desconto ?? 0.0; // Pegar desconto da venda
```

---

### 3. **CONTA DE REFERENCIA**

**Valor Atual:** Número gerado automaticamente baseado no timestamp
**Localização:** `lib/core/utils/windows_printer_service.dart:71`
**Código:**
```dart
final contaReferencia = '${DateTime.now().millisecondsSinceEpoch % 1000000}';
```

**Como substituir:**
```dart
// ATUAL (DEFAULT):
final contaReferencia = '${DateTime.now().millisecondsSinceEpoch % 1000000}';

// SUBSTITUA POR (quando tiver referência real):
final contaReferencia = venda.contaReferencia ?? venda.numero; // Usar campo real
```

---

### 4. **OPERADOR (Quem criou a venda)**

**Valor Atual:** Nome do terminal ou "SISTEMA"
**Localização:** `lib/core/config/print_layout_config.dart:120`
**Código:**
```dart
static const String operadorPadrao = 'SISTEMA';
```

**Como substituir:**
```dart
// NO ARQUIVO: lib/core/utils/windows_printer_service.dart
// LINHA: 74

// ATUAL (DEFAULT):
final operador = venda.terminal ?? PrintLayoutConfig.operadorPadrao;

// SUBSTITUA POR (quando tiver operador real):
final operador = venda.operadorNome ?? venda.usuarioNome ?? 'SISTEMA';
```

---

### 5. **SECTOR (Setor/Departamento)**

**Valor Atual:** "BALCAO"
**Localização:** `lib/core/config/print_layout_config.dart:123`
**Código:**
```dart
static const String setorPadrao = 'BALCAO';
```

**Como substituir:**
```dart
// NO ARQUIVO: lib/core/utils/windows_printer_service.dart
// LINHA: 75

// ATUAL (DEFAULT):
final setor = PrintLayoutConfig.setorPadrao;

// SUBSTITUA POR (quando tiver setor real):
final setor = venda.setor ?? venda.departamento ?? 'BALCAO';
```

---

### 6. **CLIENTE**

**Valor Atual:** Linha em branco
**Localização:** `lib/core/utils/windows_printer_service.dart:142`
**Código:**
```dart
pw.Text('CLIENTE:', style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena)),
```

**Como substituir:**
```dart
// ATUAL (DEFAULT):
pw.Text('CLIENTE:', ...),

// SUBSTITUA POR (quando tiver cliente na venda):
pw.Text(
  'CLIENTE: ${venda.clienteNome?.toUpperCase() ?? ''}',
  style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
),
```

---

## 🔧 Resumo das Mudanças Futuras

Quando você implementar esses campos no banco de dados, siga estes passos:

### Passo 1: Adicionar campos ao modelo `VendaModel`

```dart
// lib/app/data/models/venda_model.dart
class VendaModel {
  // ... campos existentes ...

  final double? desconto;
  final String? contaReferencia;
  final String? operadorNome;
  final String? setor;
  final String? clienteNome;

  // ... construtor e métodos ...
}
```

### Passo 2: Atualizar a query SQL para buscar esses dados

### Passo 3: Substituir os valores DEFAULT no código conforme documentado acima

---

## 📝 Checklist de Implementação

Quando for implementar os campos reais, marque:

- [ ] IVA por produto/venda implementado no banco
- [ ] Desconto implementado na venda
- [ ] Conta de Referência gerada no sistema
- [ ] Campo de Operador/Usuário vinculado à venda
- [ ] Campo de Setor/Departamento implementado
- [ ] Cliente vinculado à venda
- [ ] Código atualizado para usar valores reais
- [ ] Testes realizados com impressão

---

## ⚠️ IMPORTANTE

**NÃO REMOVA os valores DEFAULT até que os campos reais estejam totalmente implementados e testados!**

Use o padrão:
```dart
final valor = valorReal ?? valorDefault;
```

Isso garante que o recibo sempre terá algum valor, mesmo se o campo real ainda não existir.
