import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<ProdutoModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM v_produtos_completo
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<List<ProdutoModel>> listarPorFamilia(int familiaId) async {
    final result = await _db.query('''
      SELECT * FROM v_produtos_completo
      WHERE familia_id = @familia_id AND ativo = true
      ORDER BY nome
    ''', parameters: {'familia_id': familiaId});

    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<List<ProdutoModel>> listarPorSetor(int setorId) async {
    final result = await _db.query('''
      SELECT * FROM v_produtos_completo
      WHERE setor_id = @setor_id AND ativo = true
      ORDER BY nome
    ''', parameters: {'setor_id': setorId});

    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<List<ProdutoModel>> listarPorArea(int areaId) async {
    final result = await _db.query('''
      SELECT * FROM v_produtos_completo
      WHERE area_id = @area_id AND ativo = true
      ORDER BY nome
    ''', parameters: {'area_id': areaId});

    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<ProdutoModel?> buscarPorCodigo(String codigo) async {
    final result = await _db.query('''
      SELECT * FROM v_produtos_completo
      WHERE codigo = @codigo AND ativo = true
    ''', parameters: {'codigo': codigo});

    if (result.isEmpty) return null;
    return ProdutoModel.fromMap(result.first);
  }

  Future<int> inserir(ProdutoModel produto) async {
    return await _db.insert('''
      INSERT INTO produtos (nome, familia_id, preco, preco_compra, estoque, ativo, contavel, iva, setor_id, area_id, codigo_barras)
      VALUES (@nome, @familia_id, @preco, @preco_compra, @estoque, @ativo, @contavel, @iva, @setor_id, @area_id, @codigo_barras)
    ''', parameters: produto.toMap());
  }

  Future<void> atualizar(int id, ProdutoModel produto) async {
    await _db.execute('''
      UPDATE produtos
      SET nome = @nome,
          familia_id = @familia_id,
          preco = @preco,
          preco_compra = @preco_compra,
          estoque = @estoque,
          ativo = @ativo,
          contavel = @contavel,
          iva = @iva,
          setor_id = @setor_id,
          area_id = @area_id,
          codigo_barras = @codigo_barras,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...produto.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE produtos SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }

  Future<void> atualizarEstoque(int produtoId, int quantidade) async {
    await _db.execute('''
      UPDATE produtos
      SET estoque = estoque - @quantidade,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      'quantidade': quantidade,
      'id': produtoId,
    });
  }
}
