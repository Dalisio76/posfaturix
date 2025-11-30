# Problema: Impressora Corta em 24 Itens

## 🔍 Diagnóstico Completo

### Situação Atual
- **PDF gerado**: Contém TODOS os 105 itens ✅
- **Console mostra**: Todos os itens foram processados ✅
- **Impressão física**: Corta no item 24 ❌

### Causa Provável
**Limitação da impressora térmica**, não do software.

## Possíveis Causas da Impressora

### 1. Buffer da Impressora Cheio
- Impressoras térmicas têm buffer limitado (geralmente 64KB-256KB)
- PDF muito grande excede capacidade do buffer
- **Solução**: Dividir impressão em múltiplas páginas menores

### 2. Timeout da Impressora
- Impressora para de responder após X segundos
- **Solução**: Aumentar timeout no driver da impressora

### 3. Limite do Driver Windows
- Driver pode ter limite de linhas por documento
- **Solução**: Atualizar driver ou usar driver genérico ESC/POS

### 4. Papel Acabou
- Papel térmico acabou fisicamente
- **Solução**: Verificar se papel tem comprimento suficiente

## ✅ Soluções Implementadas no Software

1. **Altura dinâmica do papel** - Calcula tamanho baseado em itens
2. **Fonte Unicode (Roboto)** - Suporta todos os acentos
3. **PDF completo gerado** - 105 itens presentes
4. **Opção SALVAR PDF** - Para verificar conteúdo

## 🔧 Próximos Passos (Quando Tiver Outra Impressora)

### Testar com:
1. **Impressora diferente** - Para confirmar se é hardware
2. **Impressora A4 comum** - Se imprimir tudo, confirma que é térmica
3. **Múltiplas páginas** - Dividir recibo em páginas de 20 itens

### Código para Dividir em Páginas (SE NECESSÁRIO)

```dart
// Em windows_printer_service.dart
static Future<pw.Document> _gerarCupomPDF(...) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.robotoRegular();

  const ITENS_POR_PAGINA = 20; // Limite seguro

  for (int i = 0; i < itens.length; i += ITENS_POR_PAGINA) {
    final itensPagina = itens.skip(i).take(ITENS_POR_PAGINA).toList();
    final ultimaPagina = (i + ITENS_POR_PAGINA >= itens.length);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) => _buildPagina(
          itensPagina,
          numeroPagina: (i ~/ ITENS_POR_PAGINA) + 1,
          totalPaginas: (itens.length / ITENS_POR_PAGINA).ceil(),
          isUltima: ultimaPagina,
          // ... outros parâmetros
        ),
      ),
    );
  }

  return pdf;
}
```

## 📊 Configurações Testadas

| Configuração | Status |
|--------------|--------|
| Formato papel | PdfPageFormat com altura dinâmica ✅ |
| Fonte | Roboto Unicode ✅ |
| Todos itens no PDF | Sim ✅ |
| Informação pagamento | Sim ✅ |
| Impressão física | Corta em 24 ❌ |

## 🎯 Impressora Configurada Atualmente
- Nome: `balcao`
- Localização: `lib/core/utils/windows_printer_service.dart:13`

## ⚙️ Configuração Alternativa

Se precisar mudar nome da impressora:
```dart
// lib/core/utils/windows_printer_service.dart
static const String printerName = 'NOME_DA_SUA_IMPRESSORA';
```

Ou usar Admin > Impressoras > "VER IMPRESSORAS DO WINDOWS" para listar.
