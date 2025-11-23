import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/fatura_entrada_model.dart';

class FaturaEntradaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Inserir fatura completa (cabeçalho + itens + atualizar estoque)
  Future<int> inserirFatura({
    required FaturaEntradaModel fatura,
    required List<ItemFaturaEntradaModel> itens,
  }) async {
    try {
      // 1. Inserir cabeçalho da fatura
      final faturaId = await _db.insert('''
        INSERT INTO faturas_entrada (
          fornecedor_id, numero_fatura, data_fatura, total, observacoes, usuario
        ) VALUES (
          @fornecedor_id, @numero_fatura, @data_fatura, @total, @observacoes, @usuario
        )
      ''', parameters: {
        'fornecedor_id': fatura.fornecedorId,
        'numero_fatura': fatura.numeroFatura,
        'data_fatura': fatura.dataFatura.toIso8601String(),
        'total': fatura.total,
        'observacoes': fatura.observacoes,
        'usuario': fatura.usuario ?? 'Sistema',
      });

      // 2. Inserir itens da fatura
      for (var item in itens) {
        await _db.insert('''
          INSERT INTO itens_fatura_entrada (
            fatura_id, produto_id, quantidade, preco_unitario, subtotal
          ) VALUES (
            @fatura_id, @produto_id, @quantidade, @preco_unitario, @subtotal
          )
        ''', parameters: {
          'fatura_id': faturaId,
          'produto_id': item.produtoId,
          'quantidade': item.quantidade,
          'preco_unitario': item.precoUnitario,
          'subtotal': item.subtotal,
        });

        // 3. Atualizar estoque e preço de compra do produto
        await _db.execute('''
          UPDATE produtos
          SET estoque = estoque + @quantidade,
              preco_compra = @preco_compra,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = @produto_id
        ''', parameters: {
          'quantidade': item.quantidade,
          'preco_compra': item.precoUnitario,
          'produto_id': item.produtoId,
        });
      }

      return faturaId;
    } catch (e) {
      print('Erro ao inserir fatura: $e');
      rethrow;
    }
  }

  /// Listar todas as faturas
  Future<List<FaturaEntradaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT
        f.*,
        fo.nome as fornecedor_nome
      FROM faturas_entrada f
      INNER JOIN fornecedores fo ON f.fornecedor_id = fo.id
      ORDER BY f.data_fatura DESC, f.created_at DESC
    ''');

    return result.map((map) => FaturaEntradaModel.fromMap(map)).toList();
  }

  /// Buscar faturas por período
  Future<List<FaturaEntradaModel>> buscarPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    int? fornecedorId,
  }) async {
    final whereConditions = <String>[];
    final parameters = <String, dynamic>{
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    };

    whereConditions.add('f.data_fatura >= @data_inicio AND f.data_fatura <= @data_fim');

    if (fornecedorId != null) {
      whereConditions.add('f.fornecedor_id = @fornecedor_id');
      parameters['fornecedor_id'] = fornecedorId;
    }

    final whereClause = whereConditions.join(' AND ');

    final result = await _db.query('''
      SELECT
        f.*,
        fo.nome as fornecedor_nome
      FROM faturas_entrada f
      INNER JOIN fornecedores fo ON f.fornecedor_id = fo.id
      WHERE $whereClause
      ORDER BY f.data_fatura DESC, f.created_at DESC
    ''', parameters: parameters);

    return result.map((map) => FaturaEntradaModel.fromMap(map)).toList();
  }

  /// Buscar fatura por ID com seus itens
  Future<Map<String, dynamic>?> buscarPorId(int id) async {
    // Buscar cabeçalho
    final faturaResult = await _db.query('''
      SELECT
        f.*,
        fo.nome as fornecedor_nome
      FROM faturas_entrada f
      INNER JOIN fornecedores fo ON f.fornecedor_id = fo.id
      WHERE f.id = @id
    ''', parameters: {'id': id});

    if (faturaResult.isEmpty) return null;

    final fatura = FaturaEntradaModel.fromMap(faturaResult.first);

    // Buscar itens
    final itensResult = await _db.query('''
      SELECT
        i.*,
        p.codigo as produto_codigo,
        p.nome as produto_nome
      FROM itens_fatura_entrada i
      INNER JOIN produtos p ON i.produto_id = p.id
      WHERE i.fatura_id = @fatura_id
      ORDER BY i.id
    ''', parameters: {'fatura_id': id});

    final itens = itensResult.map((map) => ItemFaturaEntradaModel.fromMap(map)).toList();

    return {
      'fatura': fatura,
      'itens': itens,
    };
  }

  /// Deletar fatura (reverter estoque)
  Future<void> deletar(int id) async {
    try {
      // 1. Buscar itens para reverter estoque
      final itensResult = await _db.query('''
        SELECT produto_id, quantidade
        FROM itens_fatura_entrada
        WHERE fatura_id = @fatura_id
      ''', parameters: {'fatura_id': id});

      // 2. Reverter estoque
      for (var item in itensResult) {
        await _db.execute('''
          UPDATE produtos
          SET estoque = estoque - @quantidade,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = @produto_id
        ''', parameters: {
          'quantidade': item['quantidade'],
          'produto_id': item['produto_id'],
        });
      }

      // 3. Deletar itens
      await _db.execute('''
        DELETE FROM itens_fatura_entrada
        WHERE fatura_id = @fatura_id
      ''', parameters: {'fatura_id': id});

      // 4. Deletar fatura
      await _db.execute('''
        DELETE FROM faturas_entrada
        WHERE id = @id
      ''', parameters: {'id': id});
    } catch (e) {
      print('Erro ao deletar fatura: $e');
      rethrow;
    }
  }

  /// Buscar resumo por fornecedor
  Future<List<Map<String, dynamic>>> buscarResumoPorFornecedor({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final result = await _db.query('''
      SELECT
        fo.id as fornecedor_id,
        fo.nome as fornecedor_nome,
        COUNT(f.id) as total_faturas,
        SUM(f.total) as total_comprado
      FROM fornecedores fo
      LEFT JOIN faturas_entrada f ON fo.id = f.fornecedor_id
        AND f.data_fatura >= @data_inicio
        AND f.data_fatura <= @data_fim
      GROUP BY fo.id, fo.nome
      HAVING COUNT(f.id) > 0
      ORDER BY total_comprado DESC
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    return result;
  }
}
