import '../../../app/data/models/impressora_model.dart';
import 'impressao_base.dart';

/// Serviço de Impressão de Conta de Mesa
class ImpressaoConta extends ImpressaoBase {
  /// Imprime conta da mesa
  static Future<bool> imprimirConta({
    required String numeroMesa,
    required List<ItemConta> itens,
    required double subtotal,
    required double taxaServico,
    required double total,
    String? observacoes,
    ImpressoraModel? impressora,
  }) async {
    final conteudo = formatarConta(
      numeroMesa: numeroMesa,
      itens: itens,
      subtotal: subtotal,
      taxaServico: taxaServico,
      total: total,
      observacoes: observacoes,
    );

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'CONTA_MESA',
      conteudo: conteudo,
      impressora: impressora,
    );
  }

  /// Formata conta da mesa para impressão
  static String formatarConta({
    required String numeroMesa,
    required List<ItemConta> itens,
    required double subtotal,
    required double taxaServico,
    required double total,
    String? observacoes,
  }) {
    final buffer = StringBuffer();
    final largura = 32;

    // Cabeçalho
    buffer.writeln(ImpressaoBase.formatarCabecalho(
      titulo: 'CONTA DA MESA',
      subtitulo: 'Mesa: $numeroMesa',
      largura: largura,
    ));
    buffer.writeln();

    // Data e hora
    buffer.writeln('Data: ${ImpressaoBase.formatarDataHora(DateTime.now())}');
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Cabeçalho dos itens
    buffer.writeln(ImpressaoBase.ajustarColunas(['QTD', 'ITEM', 'VALOR'], [3, 20, 9], largura));
    buffer.writeln(ImpressaoBase.linha(largura, '-'));

    // Itens consumidos
    for (final item in itens) {
      buffer.writeln(ImpressaoBase.ajustarColunas([
        item.quantidade.toString(),
        ImpressaoBase.truncar(item.nome, 20),
        ImpressaoBase.formatarValor(item.subtotal),
      ], [3, 20, 9], largura));
    }

    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln();

    // Subtotal
    buffer.writeln(ImpressaoBase.alinharDireita('Subtotal: ${ImpressaoBase.formatarValor(subtotal)}', largura));

    // Taxa de serviço (se houver)
    if (taxaServico > 0) {
      buffer.writeln(ImpressaoBase.alinharDireita('Taxa Servico: ${ImpressaoBase.formatarValor(taxaServico)}', largura));
    }

    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln(ImpressaoBase.alinharDireita('TOTAL: ${ImpressaoBase.formatarValor(total)}', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();

    // Observações
    if (observacoes != null && observacoes.isNotEmpty) {
      buffer.writeln(observacoes);
      buffer.writeln();
    }

    // Informações adicionais
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('Esta nao e uma fatura', largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('Solicite o recibo ao pagar', largura));
    buffer.writeln();

    // Rodapé
    buffer.write(ImpressaoBase.formatarRodape(
      mensagem: 'Obrigado pela preferencia!',
      largura: largura,
    ));

    return buffer.toString();
  }

  /// Imprime conta parcial (para conferência)
  static Future<bool> imprimirContaParcial({
    required String numeroMesa,
    required List<ItemConta> itens,
    required double subtotal,
    String? mensagem,
    ImpressoraModel? impressora,
  }) async {
    final buffer = StringBuffer();
    final largura = 32;

    // Cabeçalho
    buffer.writeln(ImpressaoBase.centralizarTexto('CONTA PARCIAL', largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('Mesa: $numeroMesa', largura));
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Itens
    for (final item in itens) {
      buffer.writeln('${item.quantidade}x ${item.nome}');
    }

    buffer.writeln();
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln(ImpressaoBase.alinharDireita('Total parcial: ${ImpressaoBase.formatarValor(subtotal)}', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln();

    if (mensagem != null) {
      buffer.writeln(ImpressaoBase.centralizarTexto(mensagem, largura));
      buffer.writeln();
    }

    buffer.writeln(ImpressaoBase.espaco(3));

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'CONTA_MESA',
      conteudo: buffer.toString(),
      impressora: impressora,
    );
  }
}

/// Modelo de item de conta
class ItemConta {
  final String nome;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  ItemConta({
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
  });
}
