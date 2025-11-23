import 'package:get/get.dart';
import '../../../core/database/database_service.dart';

class RelatorioStockRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Buscar produtos com stock
  Future<List<Map<String, dynamic>>> buscarProdutosComStock({
    int? setorId,
    String? produtoNome,
  }) async {
    // Construir WHERE clause
    final whereConditions = <String>['p.ativo = true', 'p.contavel = true'];
    final parameters = <String, dynamic>{};

    if (setorId != null) {
      whereConditions.add('p.setor_id = @setor_id');
      parameters['setor_id'] = setorId;
    }

    if (produtoNome != null && produtoNome.isNotEmpty) {
      whereConditions.add('p.nome ILIKE @produto_nome');
      parameters['produto_nome'] = '%$produtoNome%';
    }

    final whereClause = whereConditions.join(' AND ');

    final result = await _db.query('''
      SELECT
        p.id,
        p.codigo,
        p.nome as produto_nome,
        f.nome as familia_nome,
        s.nome as setor_nome,
        p.estoque as quantidade,
        p.preco,
        p.preco_compra,
        (p.estoque * p.preco) as valor_venda,
        (p.estoque * p.preco_compra) as valor_compra
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      LEFT JOIN setores s ON p.setor_id = s.id
      WHERE $whereClause
      AND p.estoque > 0
      ORDER BY s.nome, f.nome, p.nome
    ''', parameters: parameters);

    return result;
  }

  /// Buscar totais
  Future<Map<String, dynamic>> buscarTotais({
    int? setorId,
    String? produtoNome,
  }) async {
    final whereConditions = <String>['p.ativo = true', 'p.contavel = true'];
    final parameters = <String, dynamic>{};

    if (setorId != null) {
      whereConditions.add('p.setor_id = @setor_id');
      parameters['setor_id'] = setorId;
    }

    if (produtoNome != null && produtoNome.isNotEmpty) {
      whereConditions.add('p.nome ILIKE @produto_nome');
      parameters['produto_nome'] = '%$produtoNome%';
    }

    final whereClause = whereConditions.join(' AND ');

    final result = await _db.query('''
      SELECT
        COUNT(*) as total_produtos,
        SUM(p.estoque) as total_quantidade,
        SUM(p.estoque * p.preco) as total_valor_venda,
        SUM(p.estoque * p.preco_compra) as total_valor_compra
      FROM produtos p
      WHERE $whereClause
      AND p.estoque > 0
    ''', parameters: parameters);

    return result.isNotEmpty ? result.first : {
      'total_produtos': 0,
      'total_quantidade': 0,
      'total_valor_venda': 0,
      'total_valor_compra': 0,
    };
  }
}
