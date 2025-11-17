import 'package:pdf/pdf.dart';

/// Configuração centralizada de layout para impressão de recibos e relatórios
///
/// CUSTOMIZE AQUI: Todos os tamanhos, espaçamentos e estilos de impressão
class PrintLayoutConfig {
  // ============================================================
  // TAMANHOS DE FONTE (Estilo Compacto - baseado em layout térmico)
  // ============================================================

  /// Título principal (ex: nome da empresa) - SEM negrito
  static const double fonteTituloPrincipal = 9.0;

  /// Títulos de seção (ex: "PRODUTO", "QUANT", "SUBTOTAL")
  static const double fonteTituloSecao = 8.0;

  /// Subtítulos e labels (ex: "Cupom:", "Data:")
  static const double fonteSubtitulo = 8.0;

  /// Texto normal (corpo do documento)
  static const double fonteNormal = 8.0;

  /// Texto pequeno (detalhes, observações)
  static const double fontePequena = 7.0;

  /// Texto muito pequeno (rodapé, informações secundárias)
  static const double fonteMuitoPequena = 7.0;

  // ============================================================
  // ESPAÇAMENTOS VERTICAIS (Layout Compacto - economiza papel)
  // ============================================================

  /// Espaço após o título principal
  static const double espacoAposTitulo = 3.0;

  /// Espaço após divisor/linha separadora
  static const double espacoAposDivisor = 2.0;

  /// Espaço entre seções principais
  static const double espacoEntreSecoes = 4.0;

  /// Espaço entre linhas de dados
  static const double espacoEntreLinhaDados = 1.0;

  /// Espaço entre itens da lista
  static const double espacoEntreItens = 2.0;

  /// Espaço antes do rodapé
  static const double espacoAntesRodape = 6.0;

  /// Espaço pequeno (uso geral)
  static const double espacoPequeno = 2.0;

  /// Espaço médio (uso geral)
  static const double espacoMedio = 3.0;

  /// Espaço grande (uso geral)
  static const double espacoGrande = 5.0;

  // ============================================================
  // LARGURAS DE COLUNAS (Recibo de Venda)
  // ============================================================

  /// Largura da coluna de quantidade nos itens
  static const double larguraQuantidade = 60.0;

  /// Largura da coluna de valores/preços
  static const double larguraValor = 70.0;

  /// Largura da coluna de subtotal
  static const double larguraSubtotal = 70.0;

  // ============================================================
  // LARGURAS DE COLUNAS (Conferência de Caixa)
  // ============================================================

  /// Largura da coluna de forma de pagamento
  static const double larguraFormaPagamento = 50.0;

  /// Largura das colunas de valores na conferência
  static const double larguraValorConferencia = 55.0;

  /// Largura da coluna de diferença
  static const double larguraDiferenca = 50.0;

  // ============================================================
  // DIVISORES E BORDAS
  // ============================================================

  /// Altura da linha divisória
  static const double alturaLinhaDivisoria = 1.0;

  /// Cor da linha divisória
  static const PdfColor corLinhaDivisoria = PdfColors.black;

  /// Espessura da borda de containers destacados
  static const double espessuraBorda = 1.0;

  // ============================================================
  // PADDING E MARGENS
  // ============================================================

  /// Padding interno de containers/boxes
  static const double paddingContainer = 3.0;

  /// Padding vertical de linhas
  static const double paddingVerticalLinha = 1.0;

  // ============================================================
  // CONFIGURAÇÕES DE IVA E DESCONTOS (VALORES DEFAULT)
  // ============================================================

  /// Taxa de IVA padrão (16%)
  static const double taxaIVAPadrao = 0.16;

  /// Desconto padrão (0.00)
  static const double descontoPadrao = 0.0;

  /// Operador padrão (quando não especificado)
  static const String operadorPadrao = 'SISTEMA';

  /// Setor padrão (quando não especificado)
  static const String setorPadrao = 'BALCAO';

  // ============================================================
  // CORES
  // ============================================================

  /// Cor de sucesso (conferência OK)
  static const PdfColor corSucesso = PdfColors.green;

  /// Cor de alerta (diferenças, avisos)
  static const PdfColor corAlerta = PdfColors.orange;

  /// Cor de erro
  static const PdfColor corErro = PdfColors.red;

  /// Cor de texto secundário
  static const PdfColor corTextoSecundario = PdfColors.grey700;

  // ============================================================
  // CONFIGURAÇÕES DO PAPEL
  // ============================================================

  /// Formato do papel (80mm para impressoras térmicas)
  static const PdfPageFormat formatoPapel = PdfPageFormat.roll80;

  // ============================================================
  // MÉTODO DE AJUSTE RÁPIDO
  // ============================================================

  /// Multiplica todos os tamanhos de fonte por um fator
  /// Use para aumentar/diminuir todas as fontes proporcionalmente
  /// Exemplo: ajustarTamanhoGeral(1.2) aumenta tudo em 20%
  static Map<String, double> ajustarTamanhoGeral(double fator) {
    return {
      'tituloPrincipal': fonteTituloPrincipal * fator,
      'tituloSecao': fonteTituloSecao * fator,
      'subtitulo': fonteSubtitulo * fator,
      'normal': fonteNormal * fator,
      'pequena': fontePequena * fator,
      'muitoPequena': fonteMuitoPequena * fator,
    };
  }

  /// Multiplica todos os espaçamentos por um fator
  /// Use para deixar o layout mais compacto ou espaçado
  /// Exemplo: ajustarEspacamentoGeral(0.8) reduz espaços em 20%
  static Map<String, double> ajustarEspacamentoGeral(double fator) {
    return {
      'aposTitulo': espacoAposTitulo * fator,
      'aposDivisor': espacoAposDivisor * fator,
      'entreSecoes': espacoEntreSecoes * fator,
      'entreLinhaDados': espacoEntreLinhaDados * fator,
      'entreItens': espacoEntreItens * fator,
      'antesRodape': espacoAntesRodape * fator,
    };
  }

  // ============================================================
  // PRESETS PRONTOS
  // ============================================================

  /// Layout compacto (economiza papel)
  static void aplicarLayoutCompacto() {
    // Aqui você pode criar lógica para alterar dinamicamente
    // Por enquanto, use como referência dos valores
  }

  /// Layout espaçado (mais legível)
  static void aplicarLayoutEspacado() {
    // Aqui você pode criar lógica para alterar dinamicamente
  }

  /// Layout para impressora de baixa resolução
  static void aplicarLayoutBaixaResolucao() {
    // Fontes maiores, mais espaços
  }
}

/// EXEMPLOS DE USO:
///
/// 1. Ajustar tamanho geral:
///    final novosTamanhos = PrintLayoutConfig.ajustarTamanhoGeral(1.2);
///    // Tudo ficará 20% maior
///
/// 2. Ajustar espaçamento:
///    final novosEspacos = PrintLayoutConfig.ajustarEspacamentoGeral(0.8);
///    // Layout mais compacto (20% menos espaço)
///
/// 3. Usar nos widgets:
///    pw.Text('Título', style: pw.TextStyle(
///      fontSize: PrintLayoutConfig.fonteTituloPrincipal
///    ))
///    pw.SizedBox(height: PrintLayoutConfig.espacoAposTitulo)
