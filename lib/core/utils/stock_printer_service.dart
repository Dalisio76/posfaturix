import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class StockPrinterService {
  static const String printerName = 'balcao';

  /// Imprimir relatório de stock
  static Future<bool> imprimirRelatorio({
    required List<Map<String, dynamic>> produtos,
    required Map<String, dynamic> totais,
    String? setor,
    String? filtroNome,
  }) async {
    try {
      final pdf = await _gerarPDF(
        produtos: produtos,
        totais: totais,
        setor: setor,
        filtroNome: filtroNome,
      );

      final printer = await _buscarImpressora(printerName);

      if (printer == null) {
        print('❌ Impressora "$printerName" não encontrada');
        return false;
      }

      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf.save(),
      );

      print('✅ Relatório de stock impresso com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir relatório de stock: $e');
      return false;
    }
  }

  /// Buscar impressora pelo nome
  static Future<Printer?> _buscarImpressora(String nome) async {
    final printers = await Printing.listPrinters();
    return printers.firstWhere(
      (printer) => printer.name.toLowerCase().contains(nome.toLowerCase()),
      orElse: () => printers.first,
    );
  }

  /// Gerar PDF do relatório
  static Future<pw.Document> _gerarPDF({
    required List<Map<String, dynamic>> produtos,
    required Map<String, dynamic> totais,
    String? setor,
    String? filtroNome,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Center(
                child: pw.Text(
                  'RELATORIO DE STOCK',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(),
              pw.SizedBox(height: 2),

              // Data
              pw.Center(
                child: pw.Text(
                  'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              // Setor
              if (setor != null) ...[
                pw.Center(
                  child: pw.Text(
                    'Setor: $setor',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],

              // Filtro
              if (filtroNome != null && filtroNome.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    'Filtro: $filtroNome',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],

              pw.SizedBox(height: 2),
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Totais
              pw.Text(
                'TOTAL PRODUTOS: ${totais['total_produtos'] ?? 0}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'TOTAL QUANTIDADE: ${(double.tryParse(totais['total_quantidade']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Lista de produtos
              ...produtos.map((produto) {
                final nome = produto['produto_nome'] ?? '';
                final quantidade = double.tryParse(produto['quantidade']?.toString() ?? '0') ?? 0;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      nome,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Qtd: ${quantidade.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 3),
                  ],
                );
              }).toList(),

              // Rodapé
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
