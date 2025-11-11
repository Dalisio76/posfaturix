import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<ClienteModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM clientes
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }

  Future<List<ClienteModel>> listarComDividas() async {
    final result = await _db.query('''
      SELECT * FROM v_clientes_dividas
      ORDER BY nome
    ''');

    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }

  Future<List<ClienteModel>> listarDevedores() async {
    final result = await _db.query('''
      SELECT * FROM v_devedores
      ORDER BY total_devendo DESC
    ''');

    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }

  Future<List<ClienteModel>> pesquisar(String termo) async {
    final result = await _db.query('''
      SELECT * FROM clientes
      WHERE ativo = true
        AND (nome ILIKE @termo OR contacto ILIKE @termo OR email ILIKE @termo)
      ORDER BY nome
    ''', parameters: {'termo': '%$termo%'});

    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }

  Future<ClienteModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM clientes
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return ClienteModel.fromMap(result.first);
  }

  Future<int> inserir(ClienteModel cliente) async {
    return await _db.insert('''
      INSERT INTO clientes (nome, contacto, contacto2, email, endereco, bairro, cidade, nuit, observacoes, ativo)
      VALUES (@nome, @contacto, @contacto2, @email, @endereco, @bairro, @cidade, @nuit, @observacoes, @ativo)
    ''', parameters: cliente.toMap());
  }

  Future<void> atualizar(int id, ClienteModel cliente) async {
    await _db.execute('''
      UPDATE clientes
      SET nome = @nome,
          contacto = @contacto,
          contacto2 = @contacto2,
          email = @email,
          endereco = @endereco,
          bairro = @bairro,
          cidade = @cidade,
          nuit = @nuit,
          observacoes = @observacoes,
          ativo = @ativo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...cliente.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE clientes SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
