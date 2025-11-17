import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../app/data/models/venda_model.dart';
import '../../app/data/models/item_venda_model.dart';
import '../../app/data/models/empresa_model.dart';
import '../../app/data/models/pagamento_venda_model.dart';
import '../config/print_layout_config.dart';

class WindowsPrinterService {
  // Nome da impressora configurada no Windows
  static const String printerName = 'balcao';

  /// Imprimir recibo de venda na impressora Windows
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

      print('✅ Recibo impresso com sucesso na impressora: $printerName');
      return true;
    } catch (e) {
      print('❌ Erro ao imprimir recibo: $e');
      return false;
    }
  }

  /// Gerar PDF do recibo (Layout compacto baseado em recibo térmico)
  static Future<pw.Document> _gerarCupomPDF(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    final pdf = pw.Document();

    // Calcular valores (DEFAULT - serão substituídos pelos reais futuramente)
    final subtotal = venda.total;
    final taxaIVA = PrintLayoutConfig.taxaIVAPadrao;
    final valorIVA = subtotal * taxaIVA; // TODO: Usar valor real do banco quando implementado
    final desconto = PrintLayoutConfig.descontoPadrao; // TODO: Usar valor real do banco quando implementado
    final valorAPagar = subtotal; // Subtotal já inclui IVA no sistema atual

    // Calcular total pago e troco
    final totalPago = pagamentos?.fold(0.0, (sum, p) => sum + p.valor) ?? 0.0;
    final troco = totalPago > valorAPagar ? totalPago - valorAPagar : 0.0;

    // Gerar CONTA DE REFERENCIA (DEFAULT - número aleatório baseado na venda)
    final contaReferencia = '${DateTime.now().millisecondsSinceEpoch % 1000000}';

    // Operador e Setor (DEFAULT)
    final operador = venda.terminal ?? PrintLayoutConfig.operadorPadrao; // TODO: Usar operador real do banco
    final setor = PrintLayoutConfig.setorPadrao; // TODO: Usar setor real do banco

    pdf.addPage(
      pw.Page(
        pageFormat: PrintLayoutConfig.formatoPapel,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ========== CABEÇALHO - DADOS DA EMPRESA ==========
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (empresa != null) ...[
                    pw.Text(
                      empresa.nome.toUpperCase(),
                      style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteTituloPrincipal),
                    ),
                    if (empresa.endereco != null && empresa.endereco!.isNotEmpty) ...[
                      pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
                      pw.Text(
                        empresa.endereco!.toUpperCase(),
                        style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                      ),
                    ],
                    if (empresa.contacto != null && empresa.contacto!.isNotEmpty) ...[
                      pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
                      pw.Text(
                        'TELEFONE(S):${empresa.contacto}',
                        style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                      ),
                    ],
                    if (empresa.nuit != null && empresa.nuit!.isNotEmpty) ...[
                      pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
                      pw.Text(
                        'NUIT: ${empresa.nuit}',
                        style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                      ),
                    ],
                    if (empresa.cidade != null && empresa.cidade!.isNotEmpty) ...[
                      pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
                      pw.Text(
                        empresa.cidade!.toUpperCase(),
                        style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                      ),
                    ],
                  ] else ...[
                    pw.Text(
                      'SISTEMA PDV',
                      style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteTituloPrincipal),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoAposTitulo),

              // NÚMERO DA VENDA (centralizado)
              pw.Center(
                child: pw.Text(
                  'VENDA Nº: ${venda.numero}',
                  style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                ),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),

              // CLIENTE (placeholder - será implementado futuramente)
              pw.Text(
                'CLIENTE:',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),

              // ========== LINHA PONTILHADA ==========
              _buildLinhaPontilhada(),
              pw.SizedBox(height: PrintLayoutConfig.espacoAposDivisor),

              // ========== CABEÇALHO DA TABELA ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('PRODUTO', style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena)),
                  ),
                  pw.Container(
                    width: 40,
                    child: pw.Text('QUANT', style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena), textAlign: pw.TextAlign.center),
                  ),
                  pw.Container(
                    width: 60,
                    child: pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              _buildLinhaPontilhada(),

              // ========== ITENS DA VENDA ==========
              ...itens.map((item) => _buildItemRowCompacto(item)),

              _buildLinhaPontilhada(),
              pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),

              // ========== IVA (16%) - DEFAULT ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TVA (${(taxaIVA * 100).toInt()}%)', style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                  pw.Text(_formatarValorSimples(valorIVA), style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                ],
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),

              // ========== DESCONTO - DEFAULT ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DESCONTO', style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                  pw.Text(_formatarValorSimples(desconto), style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                ],
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),

              // ========== VALOR A PAGAR ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('VALOR A PAGAR', style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                  pw.Text(_formatarValorSimples(valorAPagar), style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                ],
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),

              // ========== FORMA DE PAGAMENTO ==========
              if (pagamentos != null && pagamentos.isNotEmpty) ...[
                ...pagamentos.map((pagamento) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PAGO  ${pagamento.formaPagamentoNome?.toUpperCase() ?? 'CASH'}',
                      style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal),
                    ),
                    pw.Text(
                      _formatarValorSimples(pagamento.valor),
                      style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal),
                    ),
                  ],
                )),
              ],

              _buildLinhaPontilhada(),
              pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),

              // ========== TOTAL PAGO E TROCO ==========
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAGO', style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                  pw.Text(_formatarValorSimples(totalPago), style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                ],
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TROCO', style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                  pw.Text(_formatarValorSimples(troco), style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                ],
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreSecoes),

              // ========== INFORMAÇÕES ADICIONAIS (RODAPÉ) ==========
              pw.Text(
                'CONTA DE REFERENCIA: $contaReferencia',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
              pw.Text(
                'CONTA CRIADA POR:    ${operador.toUpperCase()}', // TODO: Nome do operador real
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
              pw.Text(
                'CONTA CRIADA A:      ${DateFormat('dd-MM-yyyy HH:mm:ss').format(venda.dataVenda)}',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
              pw.Text(
                'DATA E HORA: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
              pw.Text(
                'OPERADOR:    ${operador.toUpperCase()}',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
              pw.Text(
                'SECTOR: $setor',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoAntesRodape),

              // ========== RODAPÉ FINAL ==========
              pw.Text(
                '/*${empresa?.nome.toUpperCase() ?? 'SISTEMA PDV'}*/',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
              ),
              pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Construir linha pontilhada (separador)
  static pw.Widget _buildLinhaPontilhada() {
    return pw.Text(
      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
      style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
    );
  }

  /// Construir linha de item compacta (estilo térmico)
  static pw.Widget _buildItemRowCompacto(ItemVendaModel item) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Nome do produto
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                item.produtoNome?.toUpperCase() ?? 'PRODUTO',
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal),
              ),
            ),
            pw.Container(
              width: 40,
              child: pw.Text(
                item.quantidade.toStringAsFixed(2),
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              width: 60,
              child: pw.Text(
                _formatarValorSimples(item.subtotal),
                style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Preço unitário e IVA
        pw.Text(
          '${_formatarValorSimples(item.precoUnitario)}/Un    ${(PrintLayoutConfig.taxaIVAPadrao * 100).toInt()}%',
          style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
        ),
        pw.SizedBox(height: PrintLayoutConfig.espacoEntreItens),
      ],
    );
  }

  /// Formatar valor simples (sem símbolo de moeda)
  static String _formatarValorSimples(double valor) {
    return valor.toStringAsFixed(2);
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

  /// Visualizar recibo antes de imprimir (Preview)
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
        name: 'Recibo_${venda.numero}.pdf',
      );
    } catch (e) {
      print('❌ Erro ao visualizar recibo: $e');
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
