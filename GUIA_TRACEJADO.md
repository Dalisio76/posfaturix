# Guia de Controle de Tracejado/Separadores

## Como Aumentar ou Diminuir o Tracejado

### Localização
**Arquivo:** `lib/core/utils/windows_printer_service.dart`
**Função:** `_buildLinhaPontilhada()`
**Linha:** 293-299

### Código Atual (Pontilhado):
```dart
static pw.Widget _buildLinhaPontilhada() {
  return pw.Text(
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
    style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
  );
}
```

---

## 🎨 Opções de Separadores

### 1. Linha Pontilhada (atual)
```dart
'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
```
**Resultado:** `- - - - - - - - - - - - - -`

### 2. Linha Sólida (como no fecho.pdf)
```dart
'_________________________________________________________________'
```
**Resultado:** `_________________________________`

### 3. Linha com Traços Curtos
```dart
'‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾'
```

### 4. Linha com Asteriscos
```dart
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
```

### 5. Linha com Iguais
```dart
'================================================================='
```

---

## 📐 Como Ajustar o Tamanho

### Método 1: Adicionar/Remover Caracteres
```dart
// Curto (40 caracteres)
'- - - - - - - - - - - - - - - - - - - -'

// Médio (60 caracteres) ✓ Atual
'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'

// Longo (80 caracteres)
'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
```

### Método 2: Usar Repetição Programática
```dart
static pw.Widget _buildLinhaPontilhada() {
  return pw.Text(
    '- ' * 30,  // Repete "- " 30 vezes
    style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
  );
}
```

### Método 3: Usar Container com Borda
```dart
static pw.Widget _buildLinhaSolida() {
  return pw.Container(
    height: 1,
    color: PdfColors.black,
  );
}
```

---

## 🔧 Exemplos Práticos

### Para o Recibo de Venda (usar pontilhado):
```dart
static pw.Widget _buildLinhaPontilhada() {
  return pw.Text(
    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
    style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
  );
}
```

### Para o Fecho de Caixa (usar linha sólida como no PDF):
```dart
static pw.Widget _buildLinhaSolida() {
  return pw.Text(
    '_________________________________________________________________',
    style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
  );
}
```

---

## 💡 Dica Rápida

**Para mudar globalmente:**
1. Abra: `lib/core/utils/windows_printer_service.dart`
2. Encontre: `_buildLinhaPontilhada()`
3. Substitua o texto dentro de `pw.Text('...')` pelo padrão desejado
4. Salve e faça hot reload

**Para ter múltiplos estilos:**
Crie funções diferentes:
- `_buildLinhaPontilhada()` → para recibos
- `_buildLinhaSolida()` → para fechos
- `_buildLinhaTracejada()` → para relatórios
