import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../app/data/models/empresa_model.dart';

class RelatorioVendasPrinterService {
  static const String printerName = 'balcao';

  /// Imprimir relatório de vendas
  static Future<bool> imprimirRelatorio({
    required EmpresaModel? empresa,
    required DateTime dataInicio,
    required DateTime dataFim,
    required Map<String, dynamic> dadosRelatorio,
    required Map<String, List<Map<String, dynamic>>> produtosPorFamilia,
    String? operador,
    String? setor,
  }) async {
    try {
      final pdf = await _gerarRelatorioPDF(
        empresa: empresa,
        dataInicio: dataInicio,
        dataFim: dataFim,
        dadosRelatorio: dadosRelatorio,
        produtosPorFamilia: produtosPorFamilia,
        operador: operador,
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

      print('✅ Relatório impresso com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir relatório: $e');
      return false;
    }
  }

  static Future<pw.Document> _gerarRelatorioPDF({
    required EmpresaModel? empresa,
    required DateTime dataInicio,
    required DateTime dataFim,
    required Map<String, dynamic> dadosRelatorio,
    required Map<String, List<Map<String, dynamic>>> produtosPorFamilia,
    String? operador,
    String? setor,
  }) async {
    final pdf = pw.Document();

    final vendas = dadosRelatorio['vendas'] as Map<String, dynamic>;
    final formasPagamento = dadosRelatorio['formas_pagamento'] as List<Map<String, dynamic>>;
    final dividasPagas = dadosRelatorio['dividas_pagas'] as Map<String, dynamic>;
    final despesas = dadosRelatorio['despesas'] as Map<String, dynamic>;

    final totalVendasPagas = double.tryParse(vendas['total_vendas_pagas']?.toString() ?? '0') ?? 0.0;
    final totalVendasCredito = double.tryParse(vendas['total_vendas_credito']?.toString() ?? '0') ?? 0.0;
    final totalDividasPagas = double.tryParse(dividasPagas['total_dividas_pagas']?.toString() ?? '0') ?? 0.0;
    final totalDespesas = double.tryParse(despesas['total_despesas']?.toString() ?? '0') ?? 0.0;
    final totalPago = totalVendasPagas + totalDividasPagas;
    final emCaixa = totalPago - totalDespesas;

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
              'RELATÓRIO DE VENDAS',
              style: pw.TextStyle(fontSize: 10, decoration: pw.TextDecoration.underline),
            ),

            pw.SizedBox(height: 4),

            // Operador
            if (operador != null) ...[
              pw.Text('OPERADOR', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 2),
            ],

            // Datas
            _buildLinha('ABERTURA', DateFormat('dd-MM-yyyy HH:mm:ss').format(dataInicio)),
            pw.SizedBox(height: 2),
            _buildLinha('FECHO', DateFormat('dd-MM-yyyy HH:mm:ss').format(dataFim)),
            pw.SizedBox(height: 2),

            // Dívidas
            _buildLinha('EM DIVIDA', _formatarMoeda(totalVendasCredito)),
            pw.SizedBox(height: 2),
            _buildLinha('PAGTO. DIVIDA', _formatarMoeda(totalDividasPagas)),
            pw.SizedBox(height: 2),

            // Divisória
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5),
                ),
              ),
              margin: pw.EdgeInsets.symmetric(vertical: 2),
            ),

            // Formas de pagamento (agrupadas por cliente ou forma)
            ...formasPagamento.map((forma) {
              final formaNome = forma['forma_pagamento']?.toString() ?? '';
              final valor = double.tryParse(forma['total']?.toString() ?? '0') ?? 0.0;
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(formaNome.toUpperCase(), style: pw.TextStyle(fontSize: 8)),
                    pw.Text(_formatarMoeda(valor), style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 2),

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
            _buildLinha('TOTAL PAGO', _formatarMoeda(totalPago)),
            pw.SizedBox(height: 2),
            _buildLinha('DESPESAS', _formatarMoeda(totalDespesas)),
            pw.SizedBox(height: 2),
            _buildLinha('EM CAIXA', _formatarMoeda(emCaixa)),
            pw.SizedBox(height: 2),

            // Diferença (se houver)
            if (emCaixa != totalPago) ...[
              _buildLinha('DIFERENÇA', _formatarMoeda(emCaixa - totalPago)),
              pw.SizedBox(height: 2),
            ],

            // Cabeçalho da tabela de produtos
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text('PRODUTO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('QUANT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),

            pw.SizedBox(height: 2),

            // Produtos agrupados por família
            ...produtosPorFamilia.entries.expand((entry) {
              final familia = entry.key;
              final produtos = entry.value;

              // Calcular total da família
              final totalFamilia = produtos.fold(0.0, (sum, p) =>
                sum + (double.tryParse(p['total_vendido']?.toString() ?? '0') ?? 0.0)
              );
              final quantidadeFamilia = produtos.fold(0.0, (sum, p) =>
                sum + (double.tryParse(p['quantidade_total']?.toString() ?? '0') ?? 0.0)
              );

              return [
                // Nome da família com totais
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        familia.toUpperCase(),
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        quantidadeFamilia.toStringAsFixed(3),
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        _formatarMoedaSemSimbolo(totalFamilia),
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),

                // Produtos da família (indentados)
                ...produtos.map((produto) {
                  final quantidade = double.tryParse(produto['quantidade_total']?.toString() ?? '0') ?? 0.0;
                  final total = double.tryParse(produto['total_vendido']?.toString() ?? '0') ?? 0.0;

                  return pw.Padding(
                    padding: pw.EdgeInsets.only(left: 10, bottom: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            (produto['produto_nome'] as String).toUpperCase(),
                            style: pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            quantidade.toStringAsFixed(3),
                            style: pw.TextStyle(fontSize: 7),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            _formatarMoedaSemSimbolo(total),
                            style: pw.TextStyle(fontSize: 7),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 2),
              ];
            }),

            // Rodapé
            pw.SizedBox(height: 4),
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

  static String _formatarMoedaSemSimbolo(double valor) {
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
