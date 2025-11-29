import '../../../app/data/models/impressora_model.dart';
import 'impressao_cozinha.dart'; // Reutiliza modelo ItemPedido
import 'impressao_base.dart';

/// Serviço de Impressão de Pedidos do Bar
class ImpressaoBar extends ImpressaoBase {
  /// Imprime pedido para o bar
  static Future<bool> imprimirPedido({
    required String numeroMesa,
    required String numeroPedido,
    required List<ItemPedido> itens,
    String? observacoes,
    int? areaId,
    ImpressoraModel? impressora,
  }) async {
    final conteudo = formatarPedidoBar(
      numeroMesa: numeroMesa,
      numeroPedido: numeroPedido,
      itens: itens,
      observacoes: observacoes,
    );

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'PEDIDO_BAR',
      conteudo: conteudo,
      impressora: impressora,
    );
  }

  /// Formata pedido do bar para impressão
  static String formatarPedidoBar({
    required String numeroMesa,
    required String numeroPedido,
    required List<ItemPedido> itens,
    String? observacoes,
  }) {
    final buffer = StringBuffer();
    final largura = 32;

    // Cabeçalho destacado
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln(ImpressaoBase.centralizarTexto('*** BAR ***', largura));
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();

    // Informações do pedido
    buffer.writeln('MESA: $numeroMesa');
    buffer.writeln('Pedido: $numeroPedido');
    buffer.writeln('Hora: ${ImpressaoBase.formatarHora(DateTime.now())}');
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Itens do pedido
    buffer.writeln('BEBIDAS:');
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln();

    for (final item in itens) {
      // Quantidade e nome do item
      final qtdTexto = '${item.quantidade}x';
      buffer.writeln('$qtdTexto ${item.nome.toUpperCase()}');

      // Observações do item (temperatura, gelo, etc.)
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
      buffer.writeln('*** OBSERVACOES ***');
      final obsLinhas = ImpressaoBase.quebrarTexto(observacoes, largura);
      for (final linha in obsLinhas) {
        buffer.writeln(linha);
      }
      buffer.writeln();
    }

    // Rodapé
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }
}
