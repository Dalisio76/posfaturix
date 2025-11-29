import '../../../app/data/models/impressora_model.dart';
import 'impressao_base.dart';

/// Serviço de Impressão de Fecho de Caixa
class ImpressaoFecho extends ImpressaoBase {
  /// Imprime relatório de fecho de caixa
  static Future<bool> imprimirFecho({
    required DateTime dataFecho,
    required String nomeUsuario,
    required int totalVendas,
    required double valorTotal,
    required double valorDinheiro,
    required double valorCartao,
    required double valorTransferencia,
    required double valorAbertura,
    required double valorFechamento,
    required double diferenca,
    Map<String, double>? vendasPorCategoria,
    String? observacoes,
    ImpressoraModel? impressora,
  }) async {
    final conteudo = formatarFecho(
      dataFecho: dataFecho,
      nomeUsuario: nomeUsuario,
      totalVendas: totalVendas,
      valorTotal: valorTotal,
      valorDinheiro: valorDinheiro,
      valorCartao: valorCartao,
      valorTransferencia: valorTransferencia,
      valorAbertura: valorAbertura,
      valorFechamento: valorFechamento,
      diferenca: diferenca,
      vendasPorCategoria: vendasPorCategoria,
      observacoes: observacoes,
    );

    return await ImpressaoBase.imprimirDocumento(
      tipoDocumento: 'FECHO_CAIXA',
      conteudo: conteudo,
      impressora: impressora,
    );
  }

  /// Formata fecho de caixa para impressão
  static String formatarFecho({
    required DateTime dataFecho,
    required String nomeUsuario,
    required int totalVendas,
    required double valorTotal,
    required double valorDinheiro,
    required double valorCartao,
    required double valorTransferencia,
    required double valorAbertura,
    required double valorFechamento,
    required double diferenca,
    Map<String, double>? vendasPorCategoria,
    String? observacoes,
  }) {
    final buffer = StringBuffer();
    final largura = 32;

    // Cabeçalho
    buffer.writeln(ImpressaoBase.formatarCabecalho(
      titulo: 'FECHO DE CAIXA',
      subtitulo: ImpressaoBase.formatarData(dataFecho),
      largura: largura,
    ));
    buffer.writeln();

    // Informações do fecho
    buffer.writeln('Usuario: $nomeUsuario');
    buffer.writeln('Data: ${ImpressaoBase.formatarDataHora(DateTime.now())}');
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();

    // Resumo de vendas
    buffer.writeln('RESUMO DE VENDAS:');
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln('Total de vendas: $totalVendas');
    buffer.writeln(ImpressaoBase.alinharDireita('Valor: ${ImpressaoBase.formatarValor(valorTotal)}', largura));
    buffer.writeln();

    // Formas de pagamento
    buffer.writeln('FORMAS DE PAGAMENTO:');
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Dinheiro:', ImpressaoBase.formatarValor(valorDinheiro)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Cartao:', ImpressaoBase.formatarValor(valorCartao)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Transferencia:', ImpressaoBase.formatarValor(valorTransferencia)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['TOTAL:', ImpressaoBase.formatarValor(valorTotal)],
      [15, 17],
      largura,
    ));
    buffer.writeln();

    // Vendas por categoria (se houver)
    if (vendasPorCategoria != null && vendasPorCategoria.isNotEmpty) {
      buffer.writeln('VENDAS POR CATEGORIA:');
      buffer.writeln(ImpressaoBase.linha(largura, '-'));

      vendasPorCategoria.forEach((categoria, valor) {
        buffer.writeln(ImpressaoBase.ajustarColunas(
          [ImpressaoBase.truncar(categoria, 15), ImpressaoBase.formatarValor(valor)],
          [15, 17],
          largura,
        ));
      });

      buffer.writeln();
    }

    // Conferência de caixa
    buffer.writeln('CONFERENCIA DE CAIXA:');
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Abertura:', ImpressaoBase.formatarValor(valorAbertura)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Vendas:', ImpressaoBase.formatarValor(valorTotal)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.linha(largura, '-'));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Esperado:', ImpressaoBase.formatarValor(valorAbertura + valorTotal)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.ajustarColunas(
      ['Contado:', ImpressaoBase.formatarValor(valorFechamento)],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.linha(largura, '-'));

    // Diferença (destacar se houver)
    final labelDiferenca = diferenca >= 0 ? 'Sobra:' : 'Falta:';
    buffer.writeln(ImpressaoBase.ajustarColunas(
      [labelDiferenca, ImpressaoBase.formatarValor(diferenca.abs())],
      [15, 17],
      largura,
    ));
    buffer.writeln(ImpressaoBase.linha(largura, '='));
    buffer.writeln();

    // Observações
    if (observacoes != null && observacoes.isNotEmpty) {
      buffer.writeln('OBSERVACOES:');
      buffer.writeln(observacoes);
      buffer.writeln();
    }

    // Assinatura
    buffer.writeln(ImpressaoBase.linha(largura));
    buffer.writeln();
    buffer.writeln('Responsavel: __________________');
    buffer.writeln();
    buffer.writeln('Gerente: ______________________');
    buffer.writeln();

    // Rodapé
    buffer.write(ImpressaoBase.formatarRodape(
      mensagem: 'Documento de controle interno',
      largura: largura,
    ));

    return buffer.toString();
  }
}
