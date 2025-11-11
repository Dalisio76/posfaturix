import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<ProdutoModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT p.*, f.nome as familia_nome
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE p.ativo = true
      ORDER BY p.nome
    ''');

    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<List<ProdutoModel>> listarPorFamilia(int familiaId) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as familia_nome
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE p.familia_id = @familia_id AND p.ativo = true
      ORDER BY p.nome
    ''', parameters: {'familia_id': familiaId});

    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<ProdutoModel?> buscarPorCodigo(String codigo) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as familia_nome
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE p.codigo = @codigo AND p.ativo = true
    ''', parameters: {'codigo': codigo});

    if (result.isEmpty) return null;
    return ProdutoModel.fromMap(result.first);
  }

  Future<int> inserir(ProdutoModel produto) async {
    return await _db.insert('''
      INSERT INTO produtos (codigo, nome, familia_id, preco, estoque, ativo)
      VALUES (@codigo, @nome, @familia_id, @preco, @estoque, @ativo)
    ''', parameters: produto.toMap());
  }

  Future<void> atualizar(int id, ProdutoModel produto) async {
    await _db.execute('''
      UPDATE produtos
      SET codigo = @codigo,
          nome = @nome,
          familia_id = @familia_id,
          preco = @preco,
          estoque = @estoque,
          ativo = @ativo,
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
