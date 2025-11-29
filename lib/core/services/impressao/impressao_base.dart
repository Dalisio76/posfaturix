import 'package:intl/intl.dart';
import '../../../app/data/repositories/impressora_repository.dart';
import '../../../app/data/models/impressora_model.dart';

/// Classe base para serviços de impressão
/// Contém métodos utilitários compartilhados
abstract class ImpressaoBase {
  static final ImpressoraRepository _repo = ImpressoraRepository();

  /// Imprime um documento usando o mapeamento configurado
  static Future<bool> imprimirDocumento({
    required String tipoDocumento,
    required String conteudo,
    ImpressoraModel? impressora,
  }) async {
    try {
      ImpressoraModel? imp = impressora;

      // Se não foi fornecida impressora, buscar pelo mapeamento
      if (imp == null) {
        imp = await _repo.buscarImpressoraPorDocumento(tipoDocumento);

        if (imp == null) {
          print('⚠️ Tipo de documento "$tipoDocumento" não possui impressora configurada');
          return false;
        }
      }

      if (!imp.ativo) {
        print('⚠️ Impressora ${imp.nome} está inativa');
        return false;
      }

      // Imprimir
      return await _enviarParaImpressora(imp, conteudo, tipoDocumento);
    } catch (e) {
      print('❌ Erro ao imprimir documento $tipoDocumento: $e');
      return false;
    }
  }

  /// Envia conteúdo para a impressora
  static Future<bool> _enviarParaImpressora(
    ImpressoraModel impressora,
    String conteudo,
    String tipoDocumento,
  ) async {
    try {
      print('📄 Imprimindo $tipoDocumento');
      print('   Impressora: ${impressora.nome}');
      print('   Tipo: ${impressora.tipo}');
      print('   Largura: ${impressora.larguraPapel}mm');

      if (impressora.caminhoRede != null && impressora.caminhoRede!.isNotEmpty) {
        print('   Rede: ${impressora.caminhoRede}');
      }

      print('   Conteúdo:\n$conteudo');

      // TODO: Integrar com biblioteca de impressão real
      // Exemplos de bibliotecas:
      // - esc_pos_printer (para impressoras térmicas)
      // - esc_pos_utils (utilitários para ESC/POS)
      // - pdf (para gerar PDF e imprimir)
      // - printing (para impressão nativa)

      /*
      // Exemplo de integração futura com esc_pos_printer:

      if (impressora.tipo == 'termica') {
        final profile = await CapabilityProfile.load();
        final printer = NetworkPrinter(PaperSize.mm80, profile);

        final result = await printer.connect(
          impressora.caminhoRede ?? 'localhost',
          port: 9100,
        );

        if (result == PosPrintResult.success) {
          printer.text(conteudo);
          printer.feed(3);
          printer.cut();
          printer.disconnect();
        }
      }
      */

      return true;
    } catch (e) {
      print('❌ Erro ao enviar para impressora: $e');
      return false;
    }
  }

  // ========================================
  // MÉTODOS UTILITÁRIOS DE FORMATAÇÃO
  // ========================================

  /// Formata data e hora para impressão
  static String formatarDataHora(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  /// Formata apenas data para impressão
  static String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  /// Formata apenas hora para impressão
  static String formatarHora(DateTime data) {
    return DateFormat('HH:mm:ss').format(data);
  }

  /// Formata valor monetário
  static String formatarValor(double valor) {
    return NumberFormat.currency(symbol: 'MT ', decimalDigits: 2, locale: 'pt_MZ')
        .format(valor);
  }

  /// Centraliza texto em uma linha
  static String centralizarTexto(String texto, int largura) {
    if (texto.length >= largura) return texto;

    final espacos = (largura - texto.length) ~/ 2;
    return ' ' * espacos + texto;
  }

  /// Alinha texto à direita
  static String alinharDireita(String texto, int largura) {
    if (texto.length >= largura) return texto;

    final espacos = largura - texto.length;
    return ' ' * espacos + texto;
  }

  /// Cria uma linha de separação
  static String linha(int largura, [String caractere = '=']) {
    return caractere * largura;
  }

  /// Trunca texto se exceder tamanho
  static String truncar(String texto, int tamanho) {
    if (texto.length <= tamanho) return texto;
    return texto.substring(0, tamanho - 3) + '...';
  }

  /// Ajusta texto em colunas com larguras específicas
  /// Exemplo: ajustarColunas(['2x', 'Pizza', '100.00'], [4, 20, 10], 34)
  static String ajustarColunas(List<String> valores, List<int> larguras, int larguraTotal) {
    final buffer = StringBuffer();

    for (int i = 0; i < valores.length; i++) {
      final valor = valores[i];
      final largura = larguras[i];

      if (i == valores.length - 1) {
        // Última coluna: alinha à direita
        buffer.write(alinharDireita(truncar(valor, largura), largura));
      } else {
        // Outras colunas: alinha à esquerda
        final textoTruncado = truncar(valor, largura);
        buffer.write(textoTruncado.padRight(largura));
        buffer.write(' '); // Espaço entre colunas
      }
    }

    return buffer.toString();
  }

  /// Quebra texto longo em múltiplas linhas
  static List<String> quebrarTexto(String texto, int larguraMaxima) {
    final linhas = <String>[];
    final palavras = texto.split(' ');
    String linhaAtual = '';

    for (final palavra in palavras) {
      if ((linhaAtual + palavra).length <= larguraMaxima) {
        linhaAtual += (linhaAtual.isEmpty ? '' : ' ') + palavra;
      } else {
        if (linhaAtual.isNotEmpty) {
          linhas.add(linhaAtual);
        }
        linhaAtual = palavra;
      }
    }

    if (linhaAtual.isNotEmpty) {
      linhas.add(linhaAtual);
    }

    return linhas;
  }

  /// Adiciona espaçamento vertical (linhas em branco)
  static String espaco(int linhas) {
    return '\n' * linhas;
  }

  /// Formata cabeçalho padrão
  static String formatarCabecalho({
    required String titulo,
    String? subtitulo,
    int largura = 32,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(centralizarTexto(titulo.toUpperCase(), largura));
    if (subtitulo != null) {
      buffer.writeln(centralizarTexto(subtitulo, largura));
    }
    buffer.writeln(linha(largura));
    return buffer.toString();
  }

  /// Formata rodapé padrão
  static String formatarRodape({
    String? mensagem,
    int largura = 32,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(linha(largura));
    if (mensagem != null) {
      buffer.writeln(centralizarTexto(mensagem, largura));
    }
    buffer.writeln(espaco(3));
    return buffer.toString();
  }
}
