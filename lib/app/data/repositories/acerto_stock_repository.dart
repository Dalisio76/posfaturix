import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/acerto_stock_model.dart';

class AcertoStockRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Registrar um acerto de stock
  Future<int> registrarAcerto({
    required int produtoId,
    required int estoqueNovo,
    required String motivo,
    String? observacao,
    String? usuario,
  }) async {
    try {
      // Tentar usar a função do banco (se existir)
      final result = await _db.query('''
        SELECT registrar_acerto_stock(
          p_produto_id := @produto_id,
          p_estoque_novo := @estoque_novo,
          p_motivo := @motivo,
          p_observacao := @observacao,
          p_usuario := @usuario
        ) as id
      ''', parameters: {
        'produto_id': produtoId,
        'estoque_novo': estoqueNovo,
        'motivo': motivo,
        'observacao': observacao,
        'usuario': usuario ?? 'Sistema',
      });

      return result.first['id'] as int;
    } catch (e) {
      // Se a função não existir, fazer INSERT direto
      print('Função registrar_acerto_stock não encontrada, usando INSERT direto: $e');

      // Buscar estoque anterior do produto
      final produtoResult = await _db.query('''
        SELECT estoque, setor_id, area_id
        FROM produtos
        WHERE id = @produto_id
      ''', parameters: {'produto_id': produtoId});

      if (produtoResult.isEmpty) {
        throw Exception('Produto com ID $produtoId não encontrado');
      }

      final estoqueAnterior = produtoResult.first['estoque'] ?? 0;
      final setorId = produtoResult.first['setor_id'];
      final areaId = produtoResult.first['area_id'];

      // Inserir acerto
      final acertoId = await _db.insert('''
        INSERT INTO acertos_stock (
          produto_id,
          estoque_anterior,
          estoque_novo,
          motivo,
          observacao,
          setor_id,
          area_id,
          usuario
        ) VALUES (
          @produto_id,
          @estoque_anterior,
          @estoque_novo,
          @motivo,
          @observacao,
          @setor_id,
          @area_id,
          @usuario
        )
      ''', parameters: {
        'produto_id': produtoId,
        'estoque_anterior': estoqueAnterior,
        'estoque_novo': estoqueNovo,
        'motivo': motivo,
        'observacao': observacao,
        'setor_id': setorId,
        'area_id': areaId,
        'usuario': usuario ?? 'Sistema',
      });

      // Atualizar estoque do produto manualmente
      await _db.execute('''
        UPDATE produtos
        SET estoque = @estoque_novo,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @produto_id
      ''', parameters: {
        'estoque_novo': estoqueNovo,
        'produto_id': produtoId,
      });

      return acertoId;
    }
  }

  /// Buscar acertos por período
  Future<List<AcertoStockModel>> buscarPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? produtoNome,
    int? setorId,
    int? areaId,
  }) async {
    // Construir WHERE clause dinamicamente
    final whereConditions = <String>[];
    final parameters = <String, dynamic>{
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    };

    whereConditions.add('data >= @data_inicio AND data <= @data_fim');

    if (produtoNome != null && produtoNome.isNotEmpty) {
      whereConditions.add('produto_nome ILIKE @produto_nome');
      parameters['produto_nome'] = '%$produtoNome%';
    }

    if (setorId != null) {
      whereConditions.add('setor_id = @setor_id');
      parameters['setor_id'] = setorId;
    }

    if (areaId != null) {
      whereConditions.add('area_id = @area_id');
      parameters['area_id'] = areaId;
    }

    final whereClause = whereConditions.join(' AND ');

    try {
      // Tentar usar a view (se existir)
      final result = await _db.query('''
        SELECT * FROM v_acertos_completo
        WHERE $whereClause
        ORDER BY data DESC
      ''', parameters: parameters);

      return result.map((map) => AcertoStockModel.fromMap(map)).toList();
    } catch (e) {
      // Se a view não existir, fazer JOIN manual
      print('View v_acertos_completo não encontrada, usando JOIN manual: $e');

      // Ajustar WHERE clause para usar p.nome em vez de produto_nome
      var joinWhereClause = whereClause.replaceAll('produto_nome', 'p.nome');

      final result = await _db.query('''
        SELECT
          a.id,
          a.produto_id,
          p.codigo as produto_codigo,
          p.nome as produto_nome,
          p.preco as produto_preco,
          a.estoque_anterior,
          a.estoque_novo,
          (a.estoque_novo - a.estoque_anterior) as diferenca,
          a.motivo,
          a.observacao,
          a.setor_id,
          s.nome as setor_nome,
          a.area_id,
          ar.nome as area_nome,
          f.id as familia_id,
          f.nome as familia_nome,
          a.usuario,
          a.data,
          a.created_at,
          a.updated_at,
          ((a.estoque_novo - a.estoque_anterior) * p.preco) as valor_diferenca
        FROM acertos_stock a
        INNER JOIN produtos p ON a.produto_id = p.id
        LEFT JOIN setores s ON a.setor_id = s.id
        LEFT JOIN areas ar ON a.area_id = ar.id
        LEFT JOIN familias f ON p.familia_id = f.id
        WHERE $joinWhereClause
        ORDER BY a.data DESC
      ''', parameters: parameters);

      return result.map((map) => AcertoStockModel.fromMap(map)).toList();
    }
  }

  /// Buscar todos os acertos
  Future<List<AcertoStockModel>> listarTodos({int? limit}) async {
    final limitClause = limit != null ? 'LIMIT $limit' : '';

    try {
      final result = await _db.query('''
        SELECT * FROM v_acertos_completo
        ORDER BY data DESC
        $limitClause
      ''');

      return result.map((map) => AcertoStockModel.fromMap(map)).toList();
    } catch (e) {
      print('View v_acertos_completo não encontrada, usando JOIN manual: $e');

      final result = await _db.query('''
        SELECT
          a.id,
          a.produto_id,
          p.codigo as produto_codigo,
          p.nome as produto_nome,
          p.preco as produto_preco,
          a.estoque_anterior,
          a.estoque_novo,
          (a.estoque_novo - a.estoque_anterior) as diferenca,
          a.motivo,
          a.observacao,
          a.setor_id,
          s.nome as setor_nome,
          a.area_id,
          ar.nome as area_nome,
          f.id as familia_id,
          f.nome as familia_nome,
          a.usuario,
          a.data,
          a.created_at,
          a.updated_at,
          ((a.estoque_novo - a.estoque_anterior) * p.preco) as valor_diferenca
        FROM acertos_stock a
        INNER JOIN produtos p ON a.produto_id = p.id
        LEFT JOIN setores s ON a.setor_id = s.id
        LEFT JOIN areas ar ON a.area_id = ar.id
        LEFT JOIN familias f ON p.familia_id = f.id
        ORDER BY a.data DESC
        $limitClause
      ''');

      return result.map((map) => AcertoStockModel.fromMap(map)).toList();
    }
  }

  /// Buscar acertos de um produto específico
  Future<List<AcertoStockModel>> buscarPorProduto(int produtoId) async {
    try {
      final result = await _db.query('''
        SELECT * FROM v_acertos_completo
        WHERE produto_id = @produto_id
        ORDER BY data DESC
      ''', parameters: {'produto_id': produtoId});

      return result.map((map) => AcertoStockModel.fromMap(map)).toList();
    } catch (e) {
      print('View v_acertos_completo não encontrada, usando JOIN manual: $e');

      final result = await _db.query('''
        SELECT
          a.id,
          a.produto_id,
          p.codigo as produto_codigo,
          p.nome as produto_nome,
          p.preco as produto_preco,
          a.estoque_anterior,
          a.estoque_novo,
          (a.estoque_novo - a.estoque_anterior) as diferenca,
          a.motivo,
          a.observacao,
          a.setor_id,
          s.nome as setor_nome,
          a.area_id,
          ar.nome as area_nome,
          f.id as familia_id,
          f.nome as familia_nome,
          a.usuario,
          a.data,
          a.created_at,
          a.updated_at,
          ((a.estoque_novo - a.estoque_anterior) * p.preco) as valor_diferenca
        FROM acertos_stock a
        INNER JOIN produtos p ON a.produto_id = p.id
        LEFT JOIN setores s ON a.setor_id = s.id
        LEFT JOIN areas ar ON a.area_id = ar.id
        LEFT JOIN familias f ON p.familia_id = f.id
        WHERE a.produto_id = @produto_id
        ORDER BY a.data DESC
      ''', parameters: {'produto_id': produtoId});

      return result.map((map) => AcertoStockModel.fromMap(map)).toList();
    }
  }

  /// Buscar resumo de acertos por período
  Future<Map<String, dynamic>> buscarResumoPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? produtoNome,
    int? setorId,
  }) async {
    // Construir WHERE clause dinamicamente
    final whereConditions = <String>[];
    final parameters = <String, dynamic>{
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    };

    whereConditions.add('data >= @data_inicio AND data <= @data_fim');

    if (produtoNome != null && produtoNome.isNotEmpty) {
      whereConditions.add('produto_nome ILIKE @produto_nome');
      parameters['produto_nome'] = '%$produtoNome%';
    }

    if (setorId != null) {
      whereConditions.add('setor_id = @setor_id');
      parameters['setor_id'] = setorId;
    }

    final whereClause = whereConditions.join(' AND ');

    try {
      final result = await _db.query('''
        SELECT
          COUNT(*) as total_acertos,
          SUM(CASE WHEN diferenca > 0 THEN 1 ELSE 0 END) as acertos_positivos,
          SUM(CASE WHEN diferenca < 0 THEN 1 ELSE 0 END) as acertos_negativos,
          SUM(ABS(diferenca)) as total_diferencas,
          SUM(valor_diferenca) as valor_total_diferenca
        FROM v_acertos_completo
        WHERE $whereClause
      ''', parameters: parameters);

      if (result.isEmpty) {
        return {
          'total_acertos': 0,
          'acertos_positivos': 0,
          'acertos_negativos': 0,
          'total_diferencas': 0,
          'valor_total_diferenca': 0.0,
        };
      }

      return result.first;
    } catch (e) {
      print('Erro ao buscar resumo: $e');
      return {
        'total_acertos': 0,
        'acertos_positivos': 0,
        'acertos_negativos': 0,
        'total_diferencas': 0,
        'valor_total_diferenca': 0.0,
      };
    }
  }

  /// Buscar acertos por motivo
  Future<List<Map<String, dynamic>>> buscarPorMotivo() async {
    final result = await _db.query('''
      SELECT * FROM v_acertos_por_motivo
      ORDER BY total_acertos DESC
    ''');

    return result;
  }

  /// Buscar acertos por setor
  Future<List<Map<String, dynamic>>> buscarPorSetor() async {
    final result = await _db.query('''
      SELECT * FROM v_acertos_por_setor
      ORDER BY setor_nome
    ''');

    return result;
  }

  /// Deletar um acerto (caso necessário)
  Future<void> deletar(int id) async {
    await _db.execute('''
      DELETE FROM acertos_stock
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  /// Buscar acerto por ID
  Future<AcertoStockModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_acertos_completo
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return AcertoStockModel.fromMap(result.first);
  }
}
