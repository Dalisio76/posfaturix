import 'package:get/get.dart';
import '../../app/data/repositories/impressora_repository.dart';
import '../../app/data/models/impressora_model.dart';
import '../utils/windows_printer_service.dart';

/// Serviço centralizado para gerenciar impressão automática
class ImpressaoService {
  static final ImpressoraRepository _repo = ImpressoraRepository();

  /// Imprime um pedido na impressora da área
  ///
  /// Exemplo de uso:
  /// ```dart
  /// await ImpressaoService.imprimirPedidoArea(
  ///   areaId: 1,
  ///   nomeMesa: 'Mesa 5',
  ///   nomeArea: 'Bar',
  ///   itens: [{'quantidade': 2, 'nome': 'Coca-Cola', 'observacoes': ''}],
  ///   nomeUsuario: 'João Silva',
  /// );
  /// ```
  static Future<bool> imprimirPedidoArea({
    required int areaId,
    required String nomeMesa,
    required String nomeArea,
    required List<Map<String, dynamic>> itens,
    String? nomeUsuario,
    String? observacoes,
  }) async {
    try {
      print('🔍 Buscando impressora para área $areaId...');

      // Buscar impressora da área
      final impressora = await _repo.buscarImpressoraPorArea(areaId);

      if (impressora == null) {
        print('⚠️ Área $areaId não possui impressora configurada');
        return false;
      }

      if (!impressora.ativo) {
        print('⚠️ Impressora ${impressora.nome} está inativa');
        return false;
      }

      // Usar caminhoRede se existir, senão usar nome
      final nomeImpressora = impressora.caminhoRede ?? impressora.nome;

      print('✅ Impressora encontrada: $nomeImpressora');
      print('📝 Imprimindo ${itens.length} itens para $nomeArea');
      if (nomeUsuario != null) {
        print('👤 Usuario: $nomeUsuario');
      }

      // Imprimir usando WindowsPrinterService
      final sucesso = await WindowsPrinterService.imprimirPedidoArea(
        nomeImpressora: nomeImpressora,
        nomeMesa: nomeMesa,
        nomeArea: nomeArea,
        itens: itens,
        nomeUsuario: nomeUsuario,
        observacoes: observacoes,
      );

      return sucesso;
    } catch (e) {
      print('❌ Erro ao imprimir pedido na área $areaId: $e');
      return false;
    }
  }

  /// Imprime um documento usando o mapeamento configurado
  ///
  /// Exemplo de uso:
  /// ```dart
  /// await ImpressaoService.imprimirDocumento(
  ///   tipoDocumento: 'RECIBO_VENDA',
  ///   conteudo: 'RECIBO #456\n\nTotal: 150.00 MT',
  /// );
  /// ```
  static Future<bool> imprimirDocumento({
    required String tipoDocumento,
    required String conteudo,
  }) async {
    try {
      // Buscar impressora mapeada para este tipo de documento
      final impressora = await _repo.buscarImpressoraPorDocumento(tipoDocumento);

      if (impressora == null) {
        print('Tipo de documento "$tipoDocumento" não possui impressora configurada');
        return false;
      }

      if (!impressora.ativo) {
        print('Impressora ${impressora.nome} está inativa');
        return false;
      }

      // Imprimir
      print('📄 Imprimindo documento $tipoDocumento na impressora: ${impressora.nome}');
      print('Largura: ${impressora.larguraPapel}mm');
      print('Tipo: ${impressora.tipo}');
      print('Conteúdo:\n$conteudo');

      // TODO: Integrar com biblioteca de impressão real

      return true;
    } catch (e) {
      print('Erro ao imprimir documento $tipoDocumento: $e');
      return false;
    }
  }

  /// Imprime diretamente em uma impressora específica (sem usar mapeamentos)
  ///
  /// Exemplo de uso:
  /// ```dart
  /// await ImpressaoService.imprimirNaImpressora(
  ///   impressoraNome: 'Impressora Cozinha',
  ///   conteudo: 'Pedido urgente!',
  /// );
  /// ```
  static Future<bool> imprimirNaImpressora({
    required String impressoraNome,
    required String conteudo,
  }) async {
    try {
      final impressora = await _repo.buscarPorNome(impressoraNome);

      if (impressora == null) {
        print('Impressora "$impressoraNome" não encontrada');
        return false;
      }

      if (!impressora.ativo) {
        print('Impressora ${impressora.nome} está inativa');
        return false;
      }

      // Imprimir
      print('📄 Imprimindo na impressora: ${impressora.nome}');
      print('Largura: ${impressora.larguraPapel}mm');
      print('Tipo: ${impressora.tipo}');
      print('Conteúdo:\n$conteudo');

      // TODO: Integrar com biblioteca de impressão real

      return true;
    } catch (e) {
      print('Erro ao imprimir na impressora $impressoraNome: $e');
      return false;
    }
  }

  /// Formata um pedido para impressão na cozinha/bar
  /// Retorna o texto formatado pronto para impressão
  static String formatarPedidoArea({
    required String nomeMesa,
    required String nomeArea,
    required List<Map<String, dynamic>> itens,
    String? observacoes,
  }) {
    final buffer = StringBuffer();

    // Cabeçalho
    buffer.writeln('================================');
    buffer.writeln('      PEDIDO - ${nomeArea.toUpperCase()}');
    buffer.writeln('================================');
    buffer.writeln();
    buffer.writeln('Mesa: $nomeMesa');
    buffer.writeln('Data: ${DateTime.now().toString().substring(0, 16)}');
    buffer.writeln('--------------------------------');
    buffer.writeln();

    // Itens
    for (final item in itens) {
      final qtd = item['quantidade'] ?? 0;
      final nome = item['nome'] ?? '';
      final obs = item['observacoes'];

      buffer.writeln('${qtd}x $nome');
      if (obs != null && obs.toString().isNotEmpty) {
        buffer.writeln('   OBS: $obs');
      }
    }

    buffer.writeln();
    buffer.writeln('--------------------------------');

    // Observações gerais
    if (observacoes != null && observacoes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('OBSERVAÇÕES:');
      buffer.writeln(observacoes);
      buffer.writeln();
    }

    buffer.writeln('================================');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }

  /// Verifica se uma área possui impressora configurada
  static Future<bool> areaTemImpressora(int areaId) async {
    try {
      final impressora = await _repo.buscarImpressoraPorArea(areaId);
      return impressora != null && impressora.ativo;
    } catch (e) {
      print('Erro ao verificar impressora da área $areaId: $e');
      return false;
    }
  }

  /// Lista todas as impressoras ativas
  static Future<List<ImpressoraModel>> listarImpressorasAtivas() async {
    try {
      return await _repo.listarAtivas();
    } catch (e) {
      print('Erro ao listar impressoras ativas: $e');
      return [];
    }
  }
}
