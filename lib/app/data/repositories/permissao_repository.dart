import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/permissao_model.dart';

class PermissaoRepository extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  // Listar todas as permissões
  Future<List<PermissaoModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM permissoes
      WHERE ativo = true
      ORDER BY categoria, nome
    ''');

    return result.map((row) => PermissaoModel.fromMap(row)).toList();
  }

  // Listar permissões por categoria
  Future<List<PermissaoModel>> listarPorCategoria(String categoria) async {
    final result = await _db.query(
      'SELECT * FROM permissoes WHERE categoria = @categoria AND ativo = true ORDER BY nome',
      parameters: {'categoria': categoria},
    );

    return result.map((row) => PermissaoModel.fromMap(row)).toList();
  }

  // Listar categorias distintas
  Future<List<String>> listarCategorias() async {
    final result = await _db.query('''
      SELECT DISTINCT categoria
      FROM permissoes
      WHERE ativo = true AND categoria IS NOT NULL
      ORDER BY categoria
    ''');

    return result.map((row) => row['categoria'].toString()).toList();
  }

  // Buscar permissão por código
  Future<PermissaoModel?> buscarPorCodigo(String codigo) async {
    final result = await _db.query(
      'SELECT * FROM permissoes WHERE codigo = @codigo',
      parameters: {'codigo': codigo},
    );

    if (result.isEmpty) return null;
    return PermissaoModel.fromMap(result.first);
  }

  // Listar permissões de um perfil
  Future<List<PermissaoModel>> listarPermissoesPerfil(int perfilId) async {
    final result = await _db.query('''
      SELECT p.*
      FROM permissoes p
      INNER JOIN perfil_permissoes pp ON pp.permissao_id = p.id
      WHERE pp.perfil_id = @perfilId AND p.ativo = true
      ORDER BY p.categoria, p.nome
    ''', parameters: {'perfilId': perfilId});

    return result.map((row) => PermissaoModel.fromMap(row)).toList();
  }

  // Listar todas as permissões com indicação se o perfil tem ou não
  Future<List<Map<String, dynamic>>> listarPermissoesComStatus(
      int perfilId) async {
    final result = await _db.query('''
      SELECT
        perm.id,
        perm.codigo,
        perm.nome,
        perm.categoria,
        perm.descricao,
        CASE WHEN pp.id IS NOT NULL THEN true ELSE false END as tem_permissao
      FROM permissoes perm
      LEFT JOIN perfil_permissoes pp ON pp.permissao_id = perm.id AND pp.perfil_id = @perfilId
      WHERE perm.ativo = true
      ORDER BY perm.categoria, perm.nome
    ''', parameters: {'perfilId': perfilId});

    return result;
  }

  // Atribuir permissão a um perfil
  Future<void> atribuirPermissao(int perfilId, int permissaoId) async {
    await _db.query('''
      INSERT INTO perfil_permissoes (perfil_id, permissao_id)
      VALUES (@perfilId, @permissaoId)
      ON CONFLICT (perfil_id, permissao_id) DO NOTHING
    ''', parameters: {
      'perfilId': perfilId,
      'permissaoId': permissaoId,
    });
  }

  // Remover permissão de um perfil
  Future<void> removerPermissao(int perfilId, int permissaoId) async {
    await _db.query('''
      DELETE FROM perfil_permissoes
      WHERE perfil_id = @perfilId AND permissao_id = @permissaoId
    ''', parameters: {
      'perfilId': perfilId,
      'permissaoId': permissaoId,
    });
  }

  // Atualizar todas as permissões de um perfil (remove antigas e adiciona novas)
  Future<void> atualizarPermissoesPerfil(
      int perfilId, List<int> permissaoIds) async {
    // Remover todas as permissões atuais
    await _db.query(
      'DELETE FROM perfil_permissoes WHERE perfil_id = @perfilId',
      parameters: {'perfilId': perfilId},
    );

    // Adicionar as novas permissões
    for (final permissaoId in permissaoIds) {
      await atribuirPermissao(perfilId, permissaoId);
    }
  }

  // Verificar se usuário tem permissão
  Future<bool> usuarioTemPermissao(int usuarioId, String codigoPermissao) async {
    final result = await _db.query('''
      SELECT usuario_tem_permissao(@usuarioId, @codigoPermissao) as tem_permissao
    ''', parameters: {
      'usuarioId': usuarioId,
      'codigoPermissao': codigoPermissao,
    });

    if (result.isEmpty) return false;
    return result.first['tem_permissao'] == true;
  }

  // Atribuir todas as permissões a um perfil
  Future<void> atribuirTodasPermissoes(int perfilId) async {
    await _db.query('''
      INSERT INTO perfil_permissoes (perfil_id, permissao_id)
      SELECT @perfilId, id FROM permissoes WHERE ativo = true
      ON CONFLICT (perfil_id, permissao_id) DO NOTHING
    ''', parameters: {'perfilId': perfilId});
  }

  // Remover todas as permissões de um perfil
  Future<void> removerTodasPermissoes(int perfilId) async {
    await _db.query(
      'DELETE FROM perfil_permissoes WHERE perfil_id = @perfilId',
      parameters: {'perfilId': perfilId},
    );
  }
}
