import 'package:get/get.dart';
import '../../../core/database/database_service.dart';

class ConfiguracaoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Buscar valor de configuração por chave
  Future<String?> buscarValor(String chave) async {
    try {
      final result = await _db.query('''
        SELECT valor FROM configuracoes WHERE chave = @chave LIMIT 1
      ''', parameters: {'chave': chave});

      if (result.isEmpty) return null;
      return result.first['valor'] as String?;
    } catch (e) {
      print('Erro ao buscar configuração $chave: $e');
      return null;
    }
  }

  /// Buscar valor booleano
  Future<bool> buscarBoolean(String chave, {bool defaultValue = false}) async {
    try {
      final valor = await buscarValor(chave);
      if (valor == null) return defaultValue;
      return valor.toLowerCase() == 'true';
    } catch (e) {
      print('Erro ao buscar boolean $chave: $e');
      return defaultValue;
    }
  }

  /// Buscar valor inteiro
  Future<int> buscarInt(String chave, {int defaultValue = 0}) async {
    try {
      final valor = await buscarValor(chave);
      if (valor == null) return defaultValue;
      return int.tryParse(valor) ?? defaultValue;
    } catch (e) {
      print('Erro ao buscar int $chave: $e');
      return defaultValue;
    }
  }

  /// Buscar valor decimal
  Future<double> buscarDouble(String chave, {double defaultValue = 0.0}) async {
    try {
      final valor = await buscarValor(chave);
      if (valor == null) return defaultValue;
      return double.tryParse(valor) ?? defaultValue;
    } catch (e) {
      print('Erro ao buscar double $chave: $e');
      return defaultValue;
    }
  }

  /// Atualizar valor de configuração
  Future<bool> atualizarValor(String chave, String valor) async {
    try {
      await _db.execute('''
        UPDATE configuracoes
        SET valor = @valor
        WHERE chave = @chave
      ''', parameters: {
        'chave': chave,
        'valor': valor,
      });
      return true;
    } catch (e) {
      print('Erro ao atualizar configuração $chave: $e');
      return false;
    }
  }

  /// Atualizar valor booleano
  Future<bool> atualizarBoolean(String chave, bool valor) async {
    return await atualizarValor(chave, valor.toString());
  }

  /// Listar todas configurações por categoria
  Future<Map<String, String>> listarPorCategoria(String categoria) async {
    try {
      final result = await _db.query('''
        SELECT chave, valor FROM configuracoes
        WHERE categoria = @categoria
      ''', parameters: {'categoria': categoria});

      final configs = <String, String>{};
      for (final row in result) {
        configs[row['chave'] as String] = row['valor'] as String;
      }
      return configs;
    } catch (e) {
      print('Erro ao listar configurações da categoria $categoria: $e');
      return {};
    }
  }

  /// Buscar todas as configurações com detalhes
  Future<List<Map<String, dynamic>>> listarTodas() async {
    try {
      final result = await _db.query('''
        SELECT id, chave, valor, tipo, descricao, categoria
        FROM configuracoes
        ORDER BY categoria, chave
      ''');
      return result;
    } catch (e) {
      print('Erro ao listar todas configurações: $e');
      return [];
    }
  }
}
