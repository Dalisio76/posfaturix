import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/fornecedor_model.dart';

class FornecedorRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<FornecedorModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM fornecedores
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => FornecedorModel.fromMap(map)).toList();
  }

  Future<List<FornecedorModel>> listarTodosIncluindoInativos() async {
    final result = await _db.query('''
      SELECT * FROM fornecedores
      ORDER BY nome
    ''');

    return result.map((map) => FornecedorModel.fromMap(map)).toList();
  }

  Future<FornecedorModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM fornecedores
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return FornecedorModel.fromMap(result.first);
  }

  Future<FornecedorModel?> buscarPorNif(String nif) async {
    final result = await _db.query('''
      SELECT * FROM fornecedores
      WHERE nif = @nif
    ''', parameters: {'nif': nif});

    if (result.isEmpty) return null;
    return FornecedorModel.fromMap(result.first);
  }

  Future<int> inserir(FornecedorModel fornecedor) async {
    return await _db.insert('''
      INSERT INTO fornecedores (
        nome, nif, email, telefone, morada, cidade, codigo_postal,
        pais, contacto, observacoes, ativo
      ) VALUES (
        @nome, @nif, @email, @telefone, @morada, @cidade, @codigo_postal,
        @pais, @contacto, @observacoes, @ativo
      )
    ''', parameters: {
      'nome': fornecedor.nome,
      'nif': fornecedor.nif,
      'email': fornecedor.email,
      'telefone': fornecedor.telefone,
      'morada': fornecedor.morada,
      'cidade': fornecedor.cidade,
      'codigo_postal': fornecedor.codigoPostal,
      'pais': fornecedor.pais,
      'contacto': fornecedor.contacto,
      'observacoes': fornecedor.observacoes,
      'ativo': fornecedor.ativo,
    });
  }

  Future<void> atualizar(int id, FornecedorModel fornecedor) async {
    await _db.execute('''
      UPDATE fornecedores
      SET nome = @nome,
          nif = @nif,
          email = @email,
          telefone = @telefone,
          morada = @morada,
          cidade = @cidade,
          codigo_postal = @codigo_postal,
          pais = @pais,
          contacto = @contacto,
          observacoes = @observacoes,
          ativo = @ativo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      'id': id,
      'nome': fornecedor.nome,
      'nif': fornecedor.nif,
      'email': fornecedor.email,
      'telefone': fornecedor.telefone,
      'morada': fornecedor.morada,
      'cidade': fornecedor.cidade,
      'codigo_postal': fornecedor.codigoPostal,
      'pais': fornecedor.pais,
      'contacto': fornecedor.contacto,
      'observacoes': fornecedor.observacoes,
      'ativo': fornecedor.ativo,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      DELETE FROM fornecedores
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  Future<void> desativar(int id) async {
    await _db.execute('''
      UPDATE fornecedores
      SET ativo = false,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  Future<void> ativar(int id) async {
    await _db.execute('''
      UPDATE fornecedores
      SET ativo = true,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  Future<List<FornecedorModel>> pesquisar(String termo) async {
    final result = await _db.query('''
      SELECT * FROM fornecedores
      WHERE ativo = true
      AND (
        nome ILIKE @termo
        OR nif ILIKE @termo
        OR email ILIKE @termo
        OR telefone ILIKE @termo
        OR cidade ILIKE @termo
      )
      ORDER BY nome
    ''', parameters: {'termo': '%$termo%'});

    return result.map((map) => FornecedorModel.fromMap(map)).toList();
  }
}
