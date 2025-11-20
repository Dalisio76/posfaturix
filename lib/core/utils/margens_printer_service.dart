import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../app/data/models/empresa_model.dart';

class MargensPrinterService {
  static const String printerName = 'balcao';

  /// Imprimir relatório completo de margens
  static Future<bool> imprimirRelatorio({
    required EmpresaModel? empresa,
    required DateTime dataInicio,
    required DateTime dataFim,
    required List<Map<String, dynamic>> margens,
    required Map<String, dynamic> resumo,
    String? setor,
  }) async {
    try {
      final pdf = await _gerarRelatorioPDF(
        empresa: empresa,
        dataInicio: dataInicio,
        dataFim: dataFim,
        margens: margens,
        resumo: resumo,
        setor: setor,
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

      print('✅ Relatório de margens impresso com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir relatório de margens: $e');
      return false;
    }
  }

  /// Imprimir apenas resumo de margens
  static Future<bool> imprimirResumo({
    required EmpresaModel? empresa,
    required DateTime dataInicio,
    required DateTime dataFim,
    required Map<String, dynamic> resumo,
    String? setor,
  }) async {
    try {
      final pdf = await _gerarResumoPDF(
        empresa: empresa,
        dataInicio: dataInicio,
        dataFim: dataFim,
        resumo: resumo,
        setor: setor,
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

      print('✅ Resumo de margens impresso com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir resumo de margens: $e');
      return false;
    }
  }

  static Future<pw.Document> _gerarRelatorioPDF({
    required EmpresaModel? empresa,
    required DateTime dataInicio,
    required DateTime dataFim,
    required List<Map<String, dynamic>> margens,
    required Map<String, dynamic> resumo,
    String? setor,
  }) async {
    final pdf = pw.Document();

    final totalVendas = double.tryParse(resumo['total_vendas']?.toString() ?? '0') ?? 0.0;
    final totalCompra = double.tryParse(resumo['total_compra']?.toString() ?? '0') ?? 0.0;
    final totalLucro = double.tryParse(resumo['total_lucro']?.toString() ?? '0') ?? 0.0;
    final percentagemTotal = double.tryParse(resumo['percentagem_total']?.toString() ?? '0') ?? 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return [
            // Cabeçalho - Setor/Empresa
            if (setor != null)
              pw.Text(
                setor.toUpperCase(),
                style: pw.TextStyle(fontSize: 10),
              )
            else if (empresa != null)
              pw.Text(
                empresa.nome.toUpperCase(),
                style: pw.TextStyle(fontSize: 10),
              ),

            pw.SizedBox(height: 2),

            // Título
            pw.Text(
              'RELATÓRIO DE MARGENS/LUCROS',
              style: pw.TextStyle(fontSize: 10, decoration: pw.TextDecoration.underline),
            ),

            pw.SizedBox(height: 4),

            // Período
            _buildLinha('PERIODO DE', DateFormat('dd/MM/yyyy HH:mm').format(dataInicio)),
            pw.SizedBox(height: 2),
            _buildLinha('ATE', DateFormat('dd/MM/yyyy HH:mm').format(dataFim)),
            pw.SizedBox(height: 4),

            // Divisória
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5),
                ),
              ),
              margin: pw.EdgeInsets.symmetric(vertical: 2),
            ),

            // Cabeçalho da tabela
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text('PRODUTO', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text('QTD', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('LUCRO', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text('%', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),

            pw.SizedBox(height: 2),

            // Produtos
            ...margens.map((margem) {
              final quantidade = double.tryParse(margem['quantidade']?.toString() ?? '0') ?? 0.0;
              final lucro = double.tryParse(margem['lucro']?.toString() ?? '0') ?? 0.0;
              final percentagem = double.tryParse(margem['percentagem']?.toString() ?? '0') ?? 0.0;

              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        (margem['designacao'] as String).toUpperCase(),
                        style: pw.TextStyle(fontSize: 6),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        quantidade.toStringAsFixed(1),
                        style: pw.TextStyle(fontSize: 6),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatarMoeda(lucro),
                        style: pw.TextStyle(fontSize: 6),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        percentagem.toStringAsFixed(0),
                        style: pw.TextStyle(fontSize: 6),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 4),

            // Divisória
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5),
                ),
              ),
              margin: pw.EdgeInsets.symmetric(vertical: 2),
            ),

            // Totais
            _buildLinha('VENDAS', _formatarMoeda(totalVendas)),
            pw.SizedBox(height: 2),
            _buildLinha('COMPRA', _formatarMoeda(totalCompra)),
            pw.SizedBox(height: 2),
            _buildLinha('LUCRO', _formatarMoeda(totalLucro)),
            pw.SizedBox(height: 2),
            _buildLinha('PERCENTAGEM', '${percentagemTotal.toStringAsFixed(2)}%'),
            pw.SizedBox(height: 4),

            // Rodapé
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5),
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                '/*PANTHERA SYSTEMS*/',
                style: pw.TextStyle(fontSize: 8),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Document> _gerarResumoPDF({
    required EmpresaModel? empresa,
    required DateTime dataInicio,
    required DateTime dataFim,
    required Map<String, dynamic> resumo,
    String? setor,
  }) async {
    final pdf = pw.Document();

    final totalVendas = double.tryParse(resumo['total_vendas']?.toString() ?? '0') ?? 0.0;
    final totalCompra = double.tryParse(resumo['total_compra']?.toString() ?? '0') ?? 0.0;
    final totalLucro = double.tryParse(resumo['total_lucro']?.toString() ?? '0') ?? 0.0;
    final percentagemTotal = double.tryParse(resumo['percentagem_total']?.toString() ?? '0') ?? 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho - Setor/Empresa
              if (setor != null)
                pw.Text(
                  setor.toUpperCase(),
                  style: pw.TextStyle(fontSize: 10),
                )
              else if (empresa != null)
                pw.Text(
                  empresa.nome.toUpperCase(),
                  style: pw.TextStyle(fontSize: 10),
                ),

              pw.SizedBox(height: 2),

              // Título
              pw.Text(
                'RESUMO DE MARGENS',
                style: pw.TextStyle(fontSize: 10, decoration: pw.TextDecoration.underline),
              ),

              pw.SizedBox(height: 4),

              // Período
              _buildLinha('PERIODO DE', DateFormat('dd/MM/yyyy HH:mm').format(dataInicio)),
              pw.SizedBox(height: 2),
              _buildLinha('ATE', DateFormat('dd/MM/yyyy HH:mm').format(dataFim)),
              pw.SizedBox(height: 4),

              // Divisória
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5),
                  ),
                ),
                margin: pw.EdgeInsets.symmetric(vertical: 2),
              ),

              // Totais
              _buildLinha('VENDAS', _formatarMoeda(totalVendas)),
              pw.SizedBox(height: 2),
              _buildLinha('COMPRA', _formatarMoeda(totalCompra)),
              pw.SizedBox(height: 2),
              _buildLinha('LUCRO', _formatarMoeda(totalLucro)),
              pw.SizedBox(height: 2),
              _buildLinha('PERCENTAGEM', '${percentagemTotal.toStringAsFixed(2)}%'),
              pw.SizedBox(height: 4),

              // Rodapé
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5),
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  '/*PANTHERA SYSTEMS*/',
                  style: pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildLinha(String label, String valor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8)),
        pw.Text(valor, style: pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static String _formatarMoeda(double valor) {
    final formatter = NumberFormat('#,##0.00', 'pt_MZ');
    return formatter.format(valor);
  }

  static Future<Printer?> _buscarImpressora(String nomeParcial) async {
    try {
      await Printing.listPrinters();
      final printers = await Printing.listPrinters();

      for (var printer in printers) {
        if (printer.name.toLowerCase().contains(nomeParcial.toLowerCase())) {
          print('✅ Impressora encontrada: ${printer.name}');
          return printer;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar impressoras: $e');
      return null;
    }
  }
}
