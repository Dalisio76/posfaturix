import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../app/data/models/venda_model.dart';
import '../../app/data/models/item_venda_model.dart';
import '../../app/data/models/empresa_model.dart';
import '../../app/data/models/pagamento_venda_model.dart';

class WindowsPrinterService {
  // Nome da impressora configurada no Windows
  static const String printerName = 'balcao';

  /// Imprimir cupom de venda na impressora Windows
  static Future<bool> imprimirCupom(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    try {
      // Gerar PDF do cupom
      final pdf = await _gerarCupomPDF(venda, itens, empresa, pagamentos);

      // Buscar a impressora pelo nome
      final printer = await _buscarImpressora(printerName);

      if (printer == null) {
        print('❌ Impressora "$printerName" não encontrada');
        print('Impressoras disponíveis:');
        await listarImpressoras();
        return false;
      }

      // Imprimir diretamente na impressora
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf.save(),
      );

      print('✅ Cupom impresso com sucesso na impressora: $printerName');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir cupom: $e');
      return false;
    }
  }

  /// Gerar PDF do cupom
  static Future<pw.Document> _gerarCupomPDF(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Papel 80mm
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO COM DADOS DA EMPRESA
              pw.Center(
                child: pw.Column(
                  children: [
                    if (empresa != null) ...[
                      pw.Text(
                        empresa.nome,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (empresa.nuit != null && empresa.nuit!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'NUIT: ${empresa.nuit}',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                      if (empresa.endereco != null && empresa.endereco!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          empresa.endereco!,
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                      if (empresa.cidade != null && empresa.cidade!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          empresa.cidade!,
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                      if (empresa.contacto != null && empresa.contacto!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Tel: ${empresa.contacto}',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                      if (empresa.email != null && empresa.email!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          empresa.email!,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ] else ...[
                      pw.Text(
                        'SISTEMA PDV',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // INFORMAÇÕES DA VENDA
              _buildInfoRow('Cupom:', venda.numero),
              _buildInfoRow(
                'Data:',
                DateFormat('dd/MM/yyyy HH:mm').format(venda.dataVenda),
              ),
              _buildInfoRow('Terminal:', venda.terminal ?? 'CAIXA-01'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // CABEÇALHO DOS ITENS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Qtd',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Valor',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.Divider(height: 2),
              pw.SizedBox(height: 8),

              // ITENS
              ...itens.map((item) => _buildItemRow(item)),

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatarValor(venda.total),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // FORMAS DE PAGAMENTO
              if (pagamentos != null && pagamentos.isNotEmpty) ...[
                pw.Text(
                  'FORMAS DE PAGAMENTO:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...pagamentos.map((pagamento) => pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        pagamento.formaPagamentoNome ?? 'Pagamento',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        _formatarValor(pagamento.valor),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
              ],

              // RODAPÉ
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Obrigado pela preferência!',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Volte sempre!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (empresa != null)
                      pw.Text(
                        empresa.nome,
                        style: pw.TextStyle(fontSize: 8),
                      )
                    else
                      pw.Text(
                        'Sistema PDV',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Construir linha de informação
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Construir linha de item
  static pw.Widget _buildItemRow(ItemVendaModel item) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.produtoNome ?? 'Produto',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${item.quantidade}x ${_formatarValor(item.precoUnitario)}',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                _formatarValor(item.subtotal),
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Formatar valor em moeda
  static String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_MZ',
      symbol: 'MT ',
      decimalDigits: 2,
    ).format(valor);
  }

  /// Buscar impressora pelo nome
  static Future<Printer?> _buscarImpressora(String nome) async {
    try {
      final impressoras = await Printing.listPrinters();

      // Buscar exatamente pelo nome
      for (var impressora in impressoras) {
        if (impressora.name.toLowerCase() == nome.toLowerCase()) {
          return impressora;
        }
      }

      // Se não encontrar exato, buscar que contenha o nome
      for (var impressora in impressoras) {
        if (impressora.name.toLowerCase().contains(nome.toLowerCase())) {
          return impressora;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar impressora: $e');
      return null;
    }
  }

  /// Listar todas as impressoras disponíveis
  static Future<void> listarImpressoras() async {
    try {
      final impressoras = await Printing.listPrinters();

      if (impressoras.isEmpty) {
        print('Nenhuma impressora encontrada no sistema');
        return;
      }

      print('\n📄 Impressoras disponíveis no Windows:');
      for (var i = 0; i < impressoras.length; i++) {
        print('${i + 1}. ${impressoras[i].name}');
        if (impressoras[i].isDefault) {
          print('   ⭐ (Padrão)');
        }
      }
      print('');
    } catch (e) {
      print('❌ Erro ao listar impressoras: $e');
    }
  }

  /// Visualizar cupom antes de imprimir (Preview)
  static Future<void> visualizarCupom(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    try {
      final pdf = await _gerarCupomPDF(venda, itens, empresa, pagamentos);

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Cupom_${venda.numero}.pdf',
      );
    } catch (e) {
      print('❌ Erro ao visualizar cupom: $e');
    }
  }

  /// Testar impressão
  static Future<bool> testarImpressora() async {
    try {
      final printer = await _buscarImpressora(printerName);

      if (printer == null) {
        print('❌ Impressora "$printerName" não encontrada');
        await listarImpressoras();
        return false;
      }

      // Criar PDF de teste
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'TESTE DE IMPRESSÃO',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Impressora: $printerName'),
                pw.SizedBox(height: 5),
                pw.Text('Status: OK'),
                pw.SizedBox(height: 10),
                pw.Text(
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf.save(),
      );

      print('✅ Teste de impressão concluído');
      return true;
    } catch (e) {
      print('❌ Erro no teste de impressão: $e');
      return false;
    }
  }
}
