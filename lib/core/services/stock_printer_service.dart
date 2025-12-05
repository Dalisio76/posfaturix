import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart';
import '../../app/data/models/produto_model.dart';
import '../../app/data/models/empresa_model.dart';
import 'package:intl/intl.dart';

class StockPrinterService {
  static Future<void> imprimirStockA4(
    List<ProdutoModel> produtos,
    EmpresaModel empresa,
  ) async {
    final pdf = pw.Document();

    // Dados do relatorio
    final dataHora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final totalProdutos = produtos.length;
    final totalStock = produtos.fold(0, (sum, p) => sum + p.estoque);
    final valorTotal = produtos.fold(0.0, (sum, p) => sum + (p.preco * p.estoque));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          // Cabecalho
          _buildHeader(empresa, dataHora),
          pw.SizedBox(height: 20),

          // Titulo
          pw.Text(
            'RELATORIO DE STOCK',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          // Info geral
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total de produtos: $totalProdutos',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Total em stock: $totalStock unidades',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Valor total: MT ${_formatMoeda(valorTotal)}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabela
          _buildTable(produtos),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static pw.Widget _buildHeader(EmpresaModel empresa, String dataHora) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          empresa.nome,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'NUIT: ${empresa.nuit ?? "N/A"}',
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          empresa.endereco ?? "",
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Data: $dataHora',
          style: pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(List<ProdutoModel> produtos) {
    return TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 20,
      cellAlignments: {
        0: pw.Alignment.centerLeft, // Nome
        1: pw.Alignment.center, // Stock
        2: pw.Alignment.centerRight, // Preco
      },
      headers: ['PRODUTO', 'STOCK', 'PRECO VENDA'],
      data: produtos.map((p) => [
            p.nome,
            p.estoque.toString(),
            'MT ${_formatMoeda(p.preco)}',
          ]).toList(),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Pagina ${context.pageNumber} de ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8),
      ),
    );
  }

  static String _formatMoeda(double valor) {
    return NumberFormat('#,##0.00', 'pt_BR').format(valor);
  }
}
