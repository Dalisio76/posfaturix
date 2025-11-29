import '../../../app/data/models/impressora_model.dart';
import 'impressao_base.dart';

/// Serviço de Impressão de Pedidos da Cozinha
class ImpressaoCozinha extends ImpressaoBase {
  /// Imprime pedido para a cozinha
  static Future<bool> imprimirPedido({
    required String numeroMesa,
    required String numeroPedido,
    required List<ItemPedido> itens,
    String? observacoes,
    int? areaId,
    ImpressoraModel? impressora,
  }) async {
    final conteudo = formatarPedidoCozinha(
      numeroMesa: numeroMesa,
      numeroPedido: numeroPedido,
      itens: itens,
      observacoes: observacoes,
    );

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'PEDIDO_COZINHA',
      conteudo: conteudo,
      impressora: impressora,
    );
  }

  /// Formata pedido da cozinha para impressão
  static String formatarPedidoCozinha({
    required String numeroMesa,
    required String numeroPedido,
    required List<ItemPedido> itens,
    String? observacoes,
  }) {
    final buffer = StringBuffer();
    final largura = 32;

    // Cabeçalho destacado
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln(ImpressaoBase.centralizarTexto('*** COZINHA ***', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();

    // Informações do pedido
    buffer.writeln('MESA: $numeroMesa');
    buffer.writeln('Pedido: $numeroPedido');
    buffer.writeln('Hora: ${ImpressaoBase.formatarHora(DateTime.now())}');
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Itens do pedido
    buffer.writeln('ITENS:');
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln();

    for (final item in itens) {
      // Quantidade e nome do item (DESTAQUE)
      final qtdTexto = '${item.quantidade}x';
      buffer.writeln('$qtdTexto ${item.nome.toUpperCase()}');

      // Observações do item (se houver)
      if (item.observacoes != null && item.observacoes!.isNotEmpty) {
        final obsLinhas = ImpressaoBase.quebrarTexto(item.observacoes!, largura - 4);
        for (final linha in obsLinhas) {
          buffer.writeln('  > $linha');
        }
      }

      buffer.writeln();
    }

    buffer.writeln(ImpressaoBase.linha(largura, '-'));

    // Observações gerais
    if (observacoes != null && observacoes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('*** OBSERVACOES IMPORTANTES ***');
      final obsLinhas = ImpressaoBase.quebrarTexto(observacoes, largura);
      for (final linha in obsLinhas) {
        buffer.writeln(linha);
      }
      buffer.writeln();
    }

    // Rodapé
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln(ImpressaoBase.centralizarTexto('PRIORIDADE: NORMAL', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }

  /// Imprime pedido urgente (com destaque especial)
  static Future<bool> imprimirPedidoUrgente({
    required String numeroMesa,
    required String numeroPedido,
    required List<ItemPedido> itens,
    String? observacoes,
    ImpressoraModel? impressora,
  }) async {
    final buffer = StringBuffer();
    final largura = 32;

    // Cabeçalho URGENTE
    buffer.writeln(ImpressaoBase.linha(largura, '!'));
    buffer.writeln(ImpressaoBase.centralizarTexto('!!! URGENTE !!!', largura));
    buffer.writeln(ImpressaoBase.centralizarTexto('COZINHA', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '!'));
    buffer.writeln();

    // Resto do pedido
    buffer.write(formatarPedidoCozinha(
      numeroMesa: numeroMesa,
      numeroPedido: numeroPedido,
      itens: itens,
      observacoes: observacoes,
    ).replaceAll('PRIORIDADE: NORMAL', 'PRIORIDADE: URGENTE !!!'));

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'PEDIDO_COZINHA',
      conteudo: buffer.toString(),
      impressora: impressora,
    );
  }
}

/// Modelo de item de pedido para cozinha
class ItemPedido {
  final String nome;
  final int quantidade;
  final String? observacoes;

  ItemPedido({
    required this.nome,
    required this.quantidade,
    this.observacoes,
  });
}
