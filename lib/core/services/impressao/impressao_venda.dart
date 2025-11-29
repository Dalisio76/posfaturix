import '../../../app/data/models/impressora_model.dart';
import 'impressao_base.dart';

/// Serviço de Impressão de Vendas/Recibos
class ImpressaoVenda extends ImpressaoBase {
  /// Imprime recibo de venda
  static Future<bool> imprimirRecibo({
    required String numeroVenda,
    required String nomeCliente,
    required List<ItemVenda> itens,
    required double subtotal,
    required double desconto,
    required double total,
    String? formaPagamento,
    String? observacoes,
    ImpressoraModel? impressora,
  }) async {
    final conteudo = formatarRecibo(
      numeroVenda: numeroVenda,
      nomeCliente: nomeCliente,
      itens: itens,
      subtotal: subtotal,
      desconto: desconto,
      total: total,
      formaPagamento: formaPagamento,
      observacoes: observacoes,
    );

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'RECIBO_VENDA',
      conteudo: conteudo,
      impressora: impressora,
    );
  }

  /// Formata recibo de venda para impressão
  static String formatarRecibo({
    required String numeroVenda,
    required String nomeCliente,
    required List<ItemVenda> itens,
    required double subtotal,
    required double desconto,
    required double total,
    String? formaPagamento,
    String? observacoes,
  }) {
    final buffer = StringBuffer();
    final largura = 32; // 80mm térmica = 32 caracteres

    // Cabeçalho
    buffer.writeln(ImpressaoBase.centralizarTexto('POS FATURIX', largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('RECIBO DE VENDA', largura));
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Informações da venda
    buffer.writeln('Recibo: $numeroVenda');
    buffer.writeln('Cliente: $nomeCliente');
    buffer.writeln('Data: ${ImpressaoBase.formatarDataHora(DateTime.now())}');
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Cabeçalho dos itens
    buffer.writeln(ImpressaoBase.ajustarColunas(['QTD', 'ITEM', 'VALOR'], [3, 20, 9], largura));
    buffer.writeln(ImpressaoBase.linha(largura, '-'));

    // Itens
    for (final item in itens) {
      // Linha principal do item
      buffer.writeln(ImpressaoBase.ajustarColunas([
        item.quantidade.toString(),
        ImpressaoBase.truncar(item.nome, 20),
        ImpressaoBase.formatarValor(item.subtotal),
      ], [3, 20, 9], largura));

      // Se tiver observação, mostra embaixo
      if (item.observacoes != null && item.observacoes!.isNotEmpty) {
        buffer.writeln('  OBS: ${item.observacoes}');
      }
    }

    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln();

    // Totais
    buffer.writeln(ImpressaoBase.alinharDireita('Subtotal: ${ImpressaoBase.formatarValor(subtotal)}', largura));

    if (desconto > 0) {
      buffer.writeln(ImpressaoBase.alinharDireita('Desconto: ${ImpressaoBase.formatarValor(desconto)}', largura));
    }

    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln(ImpressaoBase.alinharDireita('TOTAL: ${ImpressaoBase.formatarValor(total)}', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();

    // Forma de pagamento
    if (formaPagamento != null && formaPagamento.isNotEmpty) {
      buffer.writeln('Pagamento: $formaPagamento');
      buffer.writeln();
    }

    // Observações
    if (observacoes != null && observacoes.isNotEmpty) {
      buffer.writeln('Observacoes:');
      buffer.writeln(observacoes);
      buffer.writeln();
    }

    // Rodapé
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('Obrigado pela preferencia!', largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('Volte sempre!', largura));
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }
}

/// Modelo de item de venda para impressão
class ItemVenda {
  final String nome;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;
  final String? observacoes;

  ItemVenda({
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.observacoes,
  });
}
