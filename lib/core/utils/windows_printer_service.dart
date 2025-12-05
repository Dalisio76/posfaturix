import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/data/models/venda_model.dart';
import '../../app/data/models/item_venda_model.dart';
import '../../app/data/models/empresa_model.dart';
import '../../app/data/models/pagamento_venda_model.dart';
import '../config/print_layout_config.dart';

class WindowsPrinterService {
  // Nome da impressora configurada no Windows
  static const String printerName = 'balcao';

  /// Remove acentos e caracteres especiais para evitar problemas com fonte Helvetica
  static String _sanitizarTexto(String texto) {
    const comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const semAcento = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    var resultado = texto;
    for (var i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }

    // Remove qualquer caractere que não seja ASCII básico (códigos 32-126)
    resultado = resultado.codeUnits
        .where((code) => code >= 32 && code <= 126)
        .map((code) => String.fromCharCode(code))
        .join();

    return resultado;
  }

  /// Imprimir recibo de venda na impressora Windows
  static Future<bool> imprimirCupom(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    try {
      print('DEBUG: Iniciando impressao com ${itens.length} itens');

      // Gerar PDF do cupom
      final pdf = await _gerarCupomPDF(venda, itens, empresa, pagamentos);

      // Buscar a impressora pelo nome
      final printer = await _buscarImpressora(printerName);

      if (printer == null) {
        print('ERRO: Impressora "$printerName" nao encontrada');
        print('Impressoras disponiveis:');
        await listarImpressoras();
        return false;
      }

      print('DEBUG: PDF gerado, enviando para impressora...');

      // Imprimir diretamente na impressora
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf.save(),
      );

      print('SUCESSO: Recibo impresso com sucesso na impressora: $printerName');
      return true;
    } catch (e) {
      print('ERRO: Erro ao imprimir recibo: $e');
      return false;
    }
  }

  /// Helper para criar TextStyle com fonte Unicode
  static pw.TextStyle _textStyle(double fontSize, pw.Font font) {
    return pw.TextStyle(fontSize: fontSize, font: font);
  }

  /// Gerar PDF do recibo (Layout compacto baseado em recibo térmico)
  static Future<pw.Document> _gerarCupomPDF(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    final pdf = pw.Document();

    print('DEBUG: Carregando fonte com suporte Unicode...');

    // SOLUCAO: Usar fonte do sistema que suporta Unicode
    // Isso baixa a fonte Roboto do Google Fonts e cria um pw.Font
    final ttf = await PdfGoogleFonts.robotoRegular();

    print('DEBUG: Fonte carregada com sucesso');

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

    // Calcular altura necessária do papel baseada no conteúdo
    // Altura base + altura por item + altura do rodapé
    final numItens = itens.length;
    final numPagamentos = pagamentos?.length ?? 0;

    print('DEBUG: Gerando PDF com $numItens itens e $numPagamentos pagamentos');

    // Estimativa de altura (em mm):
    // - Cabecalho: ~60mm
    // - Cada item: ~15mm (nome + preco + espacos)
    // - Totais e pagamentos: ~50mm
    // - Rodape: ~60mm
    final alturaEstimada = 60.0 + (numItens * 15.0) + (numPagamentos * 10.0) + 50.0 + 60.0;

    print('DEBUG: Altura estimada do papel: ${alturaEstimada}mm');

    // Criar formato customizado de papel térmico com altura dinâmica
    final formatoCustomizado = PdfPageFormat(
      80 * PdfPageFormat.mm, // Largura 80mm
      alturaEstimada * PdfPageFormat.mm, // Altura calculada
      marginAll: 5 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: formatoCustomizado,
        theme: pw.ThemeData.withFont(
          base: ttf,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ========== CABEÇALHO - DADOS DA EMPRESA ==========
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
                  'TELEFONE(S): ${empresa.contacto!}',
                  style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
                ),
              ],
              if (empresa.nuit != null && empresa.nuit!.isNotEmpty) ...[
                pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
                pw.Text(
                  'NUIT: ${empresa.nuit!}',
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

            pw.SizedBox(height: PrintLayoutConfig.espacoAposTitulo),

            // NÚMERO DA VENDA (centralizado) - Exibe numero_venda se disponível
            pw.Center(
              child: pw.Text(
                'VENDA Nº: ${venda.numeroExibicao}',
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
            ...itens.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              if (index == 0) {
                print('DEBUG: Adicionando ${itens.length} itens ao PDF');
              }
              if (index == 23) {
                print('DEBUG: Processando item 24 (indice 23): ${item.produtoNome}');
              }
              if (index == 24) {
                print('DEBUG: Processando item 25 (indice 24): ${item.produtoNome}');
              }
              if (index == itens.length - 1) {
                print('DEBUG: Processado ultimo item (indice ${index}): ${item.produtoNome}');
              }
              return _buildItemRowCompacto(item);
            }),

            _buildLinhaPontilhada(),
            pw.SizedBox(height: PrintLayoutConfig.espacoPequeno),

            // ========== IVA (16%) - DEFAULT ==========
            pw.Builder(builder: (context) {
              print('DEBUG: Adicionando secao de IVA/TVA');
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TVA (${(taxaIVA * 100).toInt()}%)', style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                  pw.Text(_formatarValorSimples(valorIVA), style: pw.TextStyle(fontSize: PrintLayoutConfig.fonteNormal)),
                ],
              );
            }),
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
              ...pagamentos.map(
                (pagamento) => pw.Row(
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
                ),
              ),
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
              'CONTA DE REFERÊNCIA: $contaReferencia',
              style: pw.TextStyle(fontSize: PrintLayoutConfig.fontePequena),
            ),
            pw.SizedBox(height: PrintLayoutConfig.espacoEntreLinhaDados),
            pw.Text(
              'CONTA CRIADA POR:    ${operador.toUpperCase()}',
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
        ),
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
      print('ERRO: Erro ao buscar impressora: $e');
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

      print('\nImpressoras disponiveis no Windows:');
      for (var i = 0; i < impressoras.length; i++) {
        print('${i + 1}. ${impressoras[i].name}');
        if (impressoras[i].isDefault) {
          print('   (Padrao)');
        }
      }
      print('');
    } catch (e) {
      print('ERRO: Erro ao listar impressoras: $e');
    }
  }

  /// Retorna lista de impressoras disponíveis (para UI)
  static Future<List<Printer>> listarImpressorasDisponiveis() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      print('ERRO: Erro ao listar impressoras: $e');
      return [];
    }
  }

  /// Testa impressão em uma impressora específica
  static Future<bool> testarImpressoraEspecifica(String nomeImpressora) async {
    try {
      final printer = await _buscarImpressora(nomeImpressora);

      if (printer == null) {
        print('ERRO: Impressora "$nomeImpressora" nao encontrada');
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
                  'TESTE DE IMPRESSAO',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Impressora: $_sanitizarTexto($nomeImpressora)'),
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

      print('SUCESSO: Teste de impressao enviado para: $nomeImpressora');
      return true;
    } catch (e) {
      print('ERRO: Erro no teste de impressao: $e');
      return false;
    }
  }

  /// Salvar recibo em arquivo PDF
  static Future<void> salvarCupom(
    VendaModel venda,
    List<ItemVendaModel> itens,
    EmpresaModel? empresa,
    List<PagamentoVendaModel>? pagamentos,
  ) async {
    try {
      print('DEBUG: Gerando PDF para salvar...');
      final pdf = await _gerarCupomPDF(venda, itens, empresa, pagamentos);

      print('DEBUG: Salvando PDF em arquivo...');
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'recibo_venda_${venda.numero}.pdf',
      );
      print('DEBUG: PDF salvo com sucesso');
    } catch (e) {
      print('ERRO: Erro ao salvar recibo: $e');
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
      print('ERRO: Erro ao visualizar recibo: $e');
    }
  }

  /// Testar impressão
  static Future<bool> testarImpressora() async {
    try {
      final printer = await _buscarImpressora(printerName);

      if (printer == null) {
        print('ERRO: Impressora "$printerName" nao encontrada');
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
                  'TESTE DE IMPRESSAO',
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

      print('SUCESSO: Teste de impressao concluido');
      return true;
    } catch (e) {
      print('ERRO: Erro no teste de impressao: $e');
      return false;
    }
  }

  /// Imprimir pedido de área (Cozinha, Bar, etc)
  static Future<bool> imprimirPedidoArea({
    required String nomeImpressora,
    required String nomeMesa,
    required String nomeArea,
    required List<Map<String, dynamic>> itens,
    String? nomeUsuario,
    String? observacoes,
  }) async {
    try {
      print('🖨️ Iniciando impressão de pedido área...');
      print('📍 Impressora destino: $nomeImpressora');

      // Buscar a impressora pelo nome
      final printer = await _buscarImpressora(nomeImpressora);

      if (printer == null) {
        print('❌ ERRO: Impressora "$nomeImpressora" não encontrada');
        print('Impressoras disponíveis:');
        await listarImpressoras();
        return false;
      }

      print('✅ Impressora encontrada: ${printer.name}');

      // Gerar PDF do pedido
      final pdf = await _gerarPedidoAreaPDF(
        nomeMesa: nomeMesa,
        nomeArea: nomeArea,
        itens: itens,
        nomeUsuario: nomeUsuario,
        observacoes: observacoes,
      );

      print('📄 PDF gerado, enviando para impressora...');

      // Imprimir diretamente na impressora
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf.save(),
      );

      print('✅ SUCESSO: Pedido impresso na impressora: $nomeImpressora');
      return true;
    } catch (e) {
      print('❌ ERRO ao imprimir pedido: $e');
      return false;
    }
  }

  /// Gerar PDF de pedido para cozinha/bar
  static Future<pw.Document> _gerarPedidoAreaPDF({
    required String nomeMesa,
    required String nomeArea,
    required List<Map<String, dynamic>> itens,
    String? nomeUsuario,
    String? observacoes,
  }) async {
    final pdf = pw.Document();

    // Carregar fonte com suporte Unicode
    final ttf = await PdfGoogleFonts.robotoRegular();

    // Calcular altura necessária
    final numItens = itens.length;
    final alturaEstimada = 120.0 + (numItens * 20.0) + 50.0;

    final formatoCustomizado = PdfPageFormat(
      80 * PdfPageFormat.mm,
      alturaEstimada * PdfPageFormat.mm,
      marginAll: 5 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: formatoCustomizado,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            pw.Center(
              child: pw.Text(
                '================================',
                style: pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'PEDIDO - ${nomeArea.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                '================================',
                style: pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.SizedBox(height: 3),

            // Mesa
            pw.Text(
              'Mesa: $nomeMesa',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1),

            // Usuário (se fornecido)
            if (nomeUsuario != null && nomeUsuario.isNotEmpty) ...[
              pw.Text(
                'Usuario: $nomeUsuario',
                style: pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 1),
            ],

            // Data
            pw.Text(
              'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 7),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
              style: pw.TextStyle(fontSize: 7),
            ),
            pw.SizedBox(height: 3),

            // Itens
            ...itens.map((item) {
              final qtd = item['quantidade'] ?? 0;
              final nome = item['nome'] ?? '';
              final obs = item['observacoes'];

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 25,
                        child: pw.Text(
                          '${qtd}x',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          nome.toUpperCase(),
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                  if (obs != null && obs.toString().isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Padding(
                      padding: pw.EdgeInsets.only(left: 25),
                      child: pw.Text(
                        'OBS: $obs',
                        style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 3),
                ],
              );
            }),

            pw.Text(
              '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
              style: pw.TextStyle(fontSize: 7),
            ),

            // Observações gerais
            if (observacoes != null && observacoes.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                'OBSERVAÇÕES:',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                observacoes,
                style: pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 3),
            ],

            pw.Center(
              child: pw.Text(
                '================================',
                style: pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
      ),
    );

    return pdf;
  }
}
