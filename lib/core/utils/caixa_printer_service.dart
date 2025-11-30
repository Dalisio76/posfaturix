import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/data/models/caixa_model.dart';
import '../../app/data/models/caixa_detalhe_model.dart';
import '../../app/data/models/empresa_model.dart';
import '../../app/data/models/conferencia_model.dart';
import '../config/print_layout_config.dart';

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

  /// FASE 1: Imprimir relatório de fecho de caixa COM conferência manual
  static Future<bool> imprimirFechoCaixaComConferencia(
    CaixaModel caixa,
    EmpresaModel? empresa,
    List<DespesaDetalhe> despesas,
    List<PagamentoDividaDetalhe> pagamentosDividas,
    List<ResumoProdutoVendido> produtosVendidos,
    ConferenciaModel? conferencia,
  ) async {
    try {
      // Gerar PDF do relatório com conferência
      final pdf = await _gerarRelatorioPDFComConferencia(
        caixa,
        empresa,
        despesas,
        pagamentosDividas,
        produtosVendidos,
        conferencia,
      );

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

      print('✅ Relatório de fecho de caixa (com conferência) impresso com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir relatório: $e');
      return false;
    }
  }

  /// FASE 1: Gerar PDF do relatório com conferência manual
  static Future<pw.Document> _gerarRelatorioPDFComConferencia(
    CaixaModel caixa,
    EmpresaModel? empresa,
    List<DespesaDetalhe> despesas,
    List<PagamentoDividaDetalhe> pagamentosDividas,
    List<ResumoProdutoVendido> produtosVendidos,
    ConferenciaModel? conferencia,
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
              _buildLinhaSeparadora(),

              // ===== SEÇÃO DE CONFERÊNCIA MANUAL (FASE 1) =====
              if (conferencia != null) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'CONFERÊNCIA MANUAL',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Valores contados manualmente:',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),

                // Tabela de conferência
                ..._buildTabelaConferencia(conferencia),

                pw.SizedBox(height: 4),

                // Status da conferência
                if (conferencia.conferenciaOk)
                  pw.Container(
                    padding: pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green, width: 1),
                    ),
                    child: pw.Text(
                      '✓ CONFERÊNCIA OK - Valores conferem',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.green),
                    ),
                  )
                else
                  pw.Container(
                    padding: pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.orange, width: 1),
                    ),
                    child: pw.Text(
                      '⚠ DIFERENÇA: ${_formatarValorComVirgula(conferencia.diferencaTotal)}',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.orange),
                    ),
                  ),

                pw.SizedBox(height: 8),
                _buildLinhaSeparadora(),
              ],

              // CABEÇALHO DA TABELA DE PRODUTOS
              pw.SizedBox(height: 8),
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

  /// FASE 1: Construir tabela de conferência manual
  static List<pw.Widget> _buildTabelaConferencia(ConferenciaModel conferencia) {
    final List<pw.Widget> widgets = [];

    // Só mostrar formas que foram usadas (sistema > 0)
    if (conferencia.sistemaCash > 0) {
      widgets.add(_buildLinhaConferencia(
        'CASH',
        conferencia.sistemaCash,
        conferencia.contadoCash,
        conferencia.diferencaCash,
      ));
    }

    if (conferencia.sistemaEmola > 0) {
      widgets.add(_buildLinhaConferencia(
        'E-MOLA',
        conferencia.sistemaEmola,
        conferencia.contadoEmola,
        conferencia.diferencaEmola,
      ));
    }

    if (conferencia.sistemaMpesa > 0) {
      widgets.add(_buildLinhaConferencia(
        'M-PESA',
        conferencia.sistemaMpesa,
        conferencia.contadoMpesa,
        conferencia.diferencaMpesa,
      ));
    }

    if (conferencia.sistemaPos > 0) {
      widgets.add(_buildLinhaConferencia(
        'POS',
        conferencia.sistemaPos,
        conferencia.contadoPos,
        conferencia.diferencaPos,
      ));
    }

    // Linha de total
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(_buildLinhaSeparadora());
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(_buildLinhaConferencia(
      'TOTAL',
      conferencia.sistemaTotal,
      conferencia.contadoTotal,
      conferencia.diferencaTotal,
      isBold: true,
    ));

    return widgets;
  }

  /// FASE 1: Construir linha de conferência (Sistema | Contado | Diferença)
  static pw.Widget _buildLinhaConferencia(
    String forma,
    double sistema,
    double contado,
    double diferenca, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Container(
            width: 50,
            child: pw.Text(
              forma,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Container(
            width: 55,
            child: pw.Text(
              _formatarValorComVirgula(sistema),
              style: pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Container(
            width: 55,
            child: pw.Text(
              _formatarValorComVirgula(contado),
              style: pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Container(
            width: 50,
            child: pw.Text(
              diferenca == 0 ? '0.00' : _formatarValorComVirgula(diferenca),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: diferenca != 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: diferenca == 0 ? PdfColors.green : PdfColors.orange,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Gerar PDF do relatório de fecho de caixa COMPLETO
  static Future<pw.Document> _gerarRelatorioPDF(
    CaixaModel caixa,
    EmpresaModel? empresa,
    List<DespesaDetalhe> despesas,
    List<PagamentoDividaDetalhe> pagamentosDividas,
    List<ResumoProdutoVendido> produtosVendidos,
  ) async {
    final pdf = pw.Document();

    // Carregar fonte com suporte Unicode
    final ttf = await PdfGoogleFonts.robotoRegular();

    // Calcular altura necessária
    final numItens = produtosVendidos.length + despesas.length + pagamentosDividas.length;
    final alturaEstimada = 200.0 + (numItens * 15.0) + 100.0;

    final formatoCustomizado = PdfPageFormat(
      80 * PdfPageFormat.mm,
      alturaEstimada * PdfPageFormat.mm,
      marginAll: 5 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: formatoCustomizado,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ========== CABEÇALHO ==========
              pw.Center(
                child: pw.Text(
                  empresa?.nome.toUpperCase() ?? 'RESTAURANTE',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 3),

              pw.Center(
                child: pw.Text(
                  '================================',
                  style: pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'FECHO DE CAIXA',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '================================',
                  style: pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(height: 3),

              // ========== DATAS ==========
              pw.Text(
                'Abertura: ${DateFormat('dd/MM/yyyy HH:mm').format(caixa.dataAbertura)}',
                style: pw.TextStyle(fontSize: 7),
              ),
              if (caixa.dataFechamento != null)
                pw.Text(
                  'Fecho: ${DateFormat('dd/MM/yyyy HH:mm').format(caixa.dataFechamento!)}',
                  style: pw.TextStyle(fontSize: 7),
                ),
              pw.SizedBox(height: 4),

              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),
              pw.Text('FORMAS DE PAGAMENTO:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),

              // ========== FORMAS DE PAGAMENTO ==========
              ..._buildFormasPagamentoDetalhado(caixa),

              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 4),

              // ========== TOTAIS ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL VENDAS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatarValorComVirgula(caixa.totalVendasPagas), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vendas a Credito:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(_formatarValorComVirgula(caixa.totalVendasCredito), style: pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pagtos. Dividas:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(_formatarValorComVirgula(caixa.totalDividasPagas), style: pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Despesas:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(_formatarValorComVirgula(caixa.totalDespesas), style: pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SALDO FINAL:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatarValorComVirgula(caixa.saldoFinal), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 4),
              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),
              pw.Text('PRODUTOS VENDIDOS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),

              // ========== CABEÇALHO TABELA PRODUTOS ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('PRODUTO', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Container(
                    width: 40,
                    child: pw.Text('QUANT', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                  ),
                  pw.Container(
                    width: 50,
                    child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),

              // ========== PRODUTOS VENDIDOS ==========
              ...produtosVendidos.map((produto) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      produto.produtoNome.toUpperCase(),
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ),
                  pw.Container(
                    width: 40,
                    child: pw.Text(
                      produto.quantidadeTotal.toStringAsFixed(0),
                      style: pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Container(
                    width: 50,
                    child: pw.Text(
                      produto.subtotalTotal.toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              )).toList(),

              // ========== DESPESAS DETALHADAS ==========
              if (despesas.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
                pw.SizedBox(height: 2),
                pw.Text('DESPESAS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
                pw.SizedBox(height: 2),
                ...despesas.map((desp) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            desp.descricao,
                            style: pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Text(
                          _formatarValorComVirgula(desp.valor),
                          style: pw.TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                    pw.Text(
                      '  ${DateFormat('dd/MM HH:mm').format(desp.dataDespesa)}',
                      style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                )).toList(),
              ],

              // ========== PAGAMENTOS DE DÍVIDAS DETALHADOS ==========
              if (pagamentosDividas.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
                pw.SizedBox(height: 2),
                pw.Text('PAGAMENTOS DE DIVIDAS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
                pw.SizedBox(height: 2),
                ...pagamentosDividas.map((pag) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            pag.clienteNome,
                            style: pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Text(
                          _formatarValorComVirgula(pag.valor),
                          style: pw.TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                    pw.Text(
                      '  ${pag.formaPagamento} • ${DateFormat('dd/MM HH:mm').format(pag.dataPagamento)}',
                      style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                )).toList(),
              ],

              pw.SizedBox(height: 4),
              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 4),

              // ========== RODAPÉ ==========
              pw.Center(
                child: pw.Text(
                  '${empresa?.nome.toUpperCase() ?? 'SISTEMA PDV'}',
                  style: pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Construir formas de pagamento detalhado
  static List<pw.Widget> _buildFormasPagamentoDetalhado(CaixaModel caixa) {
    final List<pw.Widget> widgets = [];

    if (caixa.totalCash > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Cash:', style: pw.TextStyle(fontSize: 7)),
          pw.Text(_formatarValorComVirgula(caixa.totalCash), style: pw.TextStyle(fontSize: 7)),
        ],
      ));
    }
    if (caixa.totalEmola > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('E-Mola:', style: pw.TextStyle(fontSize: 7)),
          pw.Text(_formatarValorComVirgula(caixa.totalEmola), style: pw.TextStyle(fontSize: 7)),
        ],
      ));
    }
    if (caixa.totalMpesa > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('M-Pesa:', style: pw.TextStyle(fontSize: 7)),
          pw.Text(_formatarValorComVirgula(caixa.totalMpesa), style: pw.TextStyle(fontSize: 7)),
        ],
      ));
    }
    if (caixa.totalPos > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('POS/Cartao:', style: pw.TextStyle(fontSize: 7)),
          pw.Text(_formatarValorComVirgula(caixa.totalPos), style: pw.TextStyle(fontSize: 7)),
        ],
      ));
    }

    return widgets;
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

  /// Linha separadora (antiga - mantida para compatibilidade com conferência)
  static pw.Widget _buildLinhaSeparadora() {
    return pw.Container(
      height: 1,
      color: PdfColors.black,
    );
  }

  /// Linha sólida (underline) - estilo fecho.pdf
  static pw.Widget _buildLinhaSolida() {
    return pw.Text(
      '_________________________________________________________________',
      style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
    );
  }

  /// Construir linha de dados compacta (sem padding extra)
  static pw.Widget _buildLinhaDadosCompacta(String label, String valor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena)),
        pw.Text(valor, style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena)),
      ],
    );
  }

  /// Construir formas de pagamento compacto (estilo fecho.pdf)
  static List<pw.Widget> _buildFormasPagamentoCompacto(CaixaModel caixa, String nomeEmpresa) {
    final List<pw.Widget> widgets = [];

    if (caixa.totalCash > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${nomeEmpresa.toUpperCase()}          CASH',
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
          pw.Text(
            _formatarValorComVirgula(caixa.totalCash),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
        ],
      ));
    }
    if (caixa.totalEmola > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${nomeEmpresa.toUpperCase()}          EMOLA',
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
          pw.Text(
            _formatarValorComVirgula(caixa.totalEmola),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
        ],
      ));
    }
    if (caixa.totalMpesa > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${nomeEmpresa.toUpperCase()}          MPESA',
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
          pw.Text(
            _formatarValorComVirgula(caixa.totalMpesa),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
        ],
      ));
    }
    if (caixa.totalPos > 0) {
      widgets.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${nomeEmpresa.toUpperCase()}          POS BCI',
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
          pw.Text(
            _formatarValorComVirgula(caixa.totalPos),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
        ],
      ));
    }

    return widgets;
  }

  /// Construir linha de produto compacto (estilo fecho.pdf)
  static pw.Widget _buildLinhaProdutoCompacto(String nome, double quantidade, double subtotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 4,
          child: pw.Text(
            nome.toUpperCase(),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
          ),
        ),
        pw.Container(
          width: 50,
          child: pw.Text(
            quantidade.toStringAsFixed(3),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Container(
          width: 60,
          child: pw.Text(
            subtotal.toStringAsFixed(2),
            style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
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
