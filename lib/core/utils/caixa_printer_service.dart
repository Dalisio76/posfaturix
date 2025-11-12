import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../app/data/models/caixa_model.dart';
import '../../app/data/models/caixa_detalhe_model.dart';
import '../../app/data/models/empresa_model.dart';

class CaixaPrinterService {
  // Nome da impressora configurada no Windows
  static const String printerName = 'balcao';

  /// Imprimir relatório de fecho de caixa
  static Future<bool> imprimirFechoCaixa(
    CaixaModel caixa,
    EmpresaModel? empresa,
    List<DespesaDetalhe> despesas,
    List<PagamentoDividaDetalhe> pagamentosDividas,
    List<ResumoProdutoVendido> produtosVendidos,
  ) async {
    try {
      // Gerar PDF do relatório
      final pdf = await _gerarRelatorioPDF(caixa, empresa, despesas, pagamentosDividas, produtosVendidos);

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

      print('✅ Relatório de fecho de caixa impresso com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir relatório: $e');
      return false;
    }
  }

  /// Gerar PDF do relatório de fecho de caixa (estilo VendasReport.pdf)
  static Future<pw.Document> _gerarRelatorioPDF(
    CaixaModel caixa,
    EmpresaModel? empresa,
    List<DespesaDetalhe> despesas,
    List<PagamentoDividaDetalhe> pagamentosDividas,
    List<ResumoProdutoVendido> produtosVendidos,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO - Nome da empresa
              pw.Text(
                empresa?.nome ?? 'RESTAURANTE',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              // TÍTULO
              pw.Text(
                'RELATÓRIO DE FECHO DE CAIXA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              // OPERADOR
              pw.Text(
                'OPERADOR',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),

              // INFORMAÇÕES DO CAIXA
              _buildLinhaDados('ABERTURA', DateFormat('dd-MM-yyyy HH:mm:ss').format(caixa.dataAbertura)),
              if (caixa.dataFechamento != null)
                _buildLinhaDados('FECHO', DateFormat('dd-MM-yyyy HH:mm:ss').format(caixa.dataFechamento!)),

              _buildLinhaDados('EM DIVIDA', _formatarValorSimples(caixa.totalVendasCredito)),
              _buildLinhaDados('PAGTO. DIVIDA', _formatarValorSimples(caixa.totalDividasPagas)),

              pw.SizedBox(height: 4),
              _buildLinhaSeparadora(),

              // FORMAS DE PAGAMENTO (só as usadas)
              ..._buildFormasPagamento(caixa, empresa?.nome ?? 'CAIXA'),

              pw.SizedBox(height: 4),
              _buildLinhaSeparadora(),

              // TOTAIS
              _buildLinhaDados('TOTAL PAGO', _formatarValorComVirgula(caixa.totalVendasPagas)),
              _buildLinhaDados('DESPESAS', _formatarValorComVirgula(caixa.totalDespesas)),
              _buildLinhaDados('EM CAIXA', _formatarValorComVirgula(caixa.saldoFinal)),
              _buildLinhaDados('DIFERENÇA', _formatarValorComVirgula(caixa.totalEntradas - caixa.totalVendasPagas)),

              pw.SizedBox(height: 8),

              // CABEÇALHO DA TABELA DE PRODUTOS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('PRODUTO', style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(
                    width: 60,
                    child: pw.Text('QUANT', style: pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                  ),
                  pw.Container(
                    width: 70,
                    child: pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // PRODUTOS VENDIDOS
              ...produtosVendidos.map((produto) => _buildLinhaProduto(
                produto.produtoNome,
                produto.quantidadeTotal.toDouble(),
                produto.subtotalTotal,
              )).toList(),

              pw.SizedBox(height: 8),
              _buildLinhaSeparadora(),

              // DESPESAS DETALHADAS
              if (despesas.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'DESPESAS DETALHADAS',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...despesas.map((desp) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            desp.descricao,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Text(
                          _formatarValorComVirgula(desp.valor),
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Text(
                      '  ${DateFormat('dd/MM HH:mm').format(desp.dataDespesa)}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                )).toList(),
                pw.SizedBox(height: 4),
                _buildLinhaSeparadora(),
              ],

              // PAGAMENTOS DE DÍVIDAS DETALHADOS
              if (pagamentosDividas.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'PAGAMENTOS DE DÍVIDAS',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...pagamentosDividas.map((pag) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            pag.clienteNome,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Text(
                          _formatarValorComVirgula(pag.valor),
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Text(
                      '  ${pag.formaPagamento} • ${DateFormat('dd/MM HH:mm').format(pag.dataPagamento)}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                )).toList(),
                pw.SizedBox(height: 4),
                _buildLinhaSeparadora(),
              ],

              // RODAPÉ
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  '/*${empresa?.nome ?? 'SISTEMA PDV'}*/',
                  style: pw.TextStyle(fontSize: 9),
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

  /// Construir linha de dados (chave: valor)
  static pw.Widget _buildLinhaDados(String label, String valor) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10)),
          pw.Text(valor, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Construir formas de pagamento (só as usadas)
  static List<pw.Widget> _buildFormasPagamento(CaixaModel caixa, String nomeEmpresa) {
    final List<pw.Widget> widgets = [];

    if (caixa.totalCash > 0) {
      widgets.add(_buildLinhaDados(
        '$nomeEmpresa          CASH',
        _formatarValorComVirgula(caixa.totalCash),
      ));
    }
    if (caixa.totalEmola > 0) {
      widgets.add(_buildLinhaDados(
        '$nomeEmpresa          EMOLA',
        _formatarValorComVirgula(caixa.totalEmola),
      ));
    }
    if (caixa.totalMpesa > 0) {
      widgets.add(_buildLinhaDados(
        '$nomeEmpresa          MPESA',
        _formatarValorComVirgula(caixa.totalMpesa),
      ));
    }
    if (caixa.totalPos > 0) {
      widgets.add(_buildLinhaDados(
        '$nomeEmpresa          POS BCI',
        _formatarValorComVirgula(caixa.totalPos),
      ));
    }

    return widgets;
  }

  /// Construir linha de produto
  static pw.Widget _buildLinhaProduto(String nome, double quantidade, double subtotal) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(nome, style: pw.TextStyle(fontSize: 9)),
          ),
          pw.Container(
            width: 60,
            child: pw.Text(
              quantidade.toStringAsFixed(3),
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Container(
            width: 70,
            child: pw.Text(
              subtotal.toStringAsFixed(2),
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Linha separadora
  static pw.Widget _buildLinhaSeparadora() {
    return pw.Container(
      height: 1,
      color: PdfColors.black,
    );
  }

  /// Formatar valor simples (.00)
  static String _formatarValorSimples(double valor) {
    return '.${valor.toStringAsFixed(2).split('.')[1]}';
  }

  /// Formatar valor com vírgula (1,234.00)
  static String _formatarValorComVirgula(double valor) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(valor);
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

  /// Visualizar relatório antes de imprimir (Preview)
  static Future<void> visualizarRelatorio(
    CaixaModel caixa,
    EmpresaModel? empresa,
    List<DespesaDetalhe> despesas,
    List<PagamentoDividaDetalhe> pagamentosDividas,
    List<ResumoProdutoVendido> produtosVendidos,
  ) async {
    try {
      final pdf = await _gerarRelatorioPDF(caixa, empresa, despesas, pagamentosDividas, produtosVendidos);

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Fecho_Caixa_${caixa.numero}.pdf',
      );
    } catch (e) {
      print('❌ Erro ao visualizar relatório: $e');
    }
  }
}
