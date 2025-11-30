# Solução para Unicode em PDFs

## Problema
A fonte padrão Helvetica não suporta acentos (ã, ç, á, etc), causando travamento ao gerar PDFs.

## Solução: Usar Google Fonts (Roboto)

### Passo 1: Adicionar dependência
No `pubspec.yaml`, já existe:
```yaml
dependencies:
  pdf: ^3.11.1
  google_fonts: ^6.2.1  # Já instalado!
```

### Passo 2: Modificar windows_printer_service.dart

**SUBSTITUIR** a função `_gerarCupomPDF` para usar Roboto:

```dart
import 'package:google_fonts/google_fonts.dart';

static Future<pw.Document> _gerarCupomPDF(...) async {
  final pdf = pw.Document();

  // IMPORTANTE: Carregar fonte Roboto que suporta Unicode
  final fontData = await GoogleFonts.robotoRegular();
  final ttf = pw.Font.ttf(fontData);

  // Usar ttf em todos os pw.TextStyle:
  pw.TextStyle(fontSize: 10, font: ttf)

  // Agora pode usar acentos sem problemas!
}
```

### Passo 3: Aplicar em todos os textos

**ANTES:**
```dart
pw.Text('NÚMERO', style: pw.TextStyle(fontSize: 10))
```

**DEPOIS:**
```dart
pw.Text('NÚMERO', style: pw.TextStyle(fontSize: 10, font: ttf))
```

## Vantagens
✅ Mantém todos os acentos originais
✅ Não precisa sanitizar nada
✅ Texto fica mais legível
✅ Profissional

## Desvantagens
❌ PDF fica ~200KB maior (inclui fonte)
❌ Precisa modificar todos os pw.TextStyle

## Alternativa Mais Simples
Use o pacote `pdf_editor` ou crie um Theme padrão para não precisar adicionar font em cada Text.
