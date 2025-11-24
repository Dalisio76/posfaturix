import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/mesa_model.dart';

class MesaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Lista todas as mesas com informações completas (via view)
  Future<List<MesaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM v_mesas_completo
      ORDER BY numero
    ''');

    return result.map((map) => MesaModel.fromMap(map)).toList();
  }

  /// Lista mesas filtradas por usuário
  /// Admin (tem permissão gestao_mesas) vê todas
  /// Usuários normais veem apenas suas mesas ocupadas e todas as livres
  Future<List<MesaModel>> listarPorUsuario(int usuarioId, bool isAdmin) async {
    final result = await _db.query('''
      SELECT * FROM v_mesas_completo
      WHERE
        CASE
          WHEN @is_admin THEN true  -- Admin vê tudo
          WHEN status = 'livre' THEN true  -- Todos veem mesas livres
          WHEN usuario_id = @usuario_id THEN true  -- Vê suas próprias mesas
          ELSE false
        END
      ORDER BY numero
    ''', parameters: {
      'usuario_id': usuarioId,
      'is_admin': isAdmin,
    });

    return result.map((map) => MesaModel.fromMap(map)).toList();
  }

  /// Lista mesas livres
  Future<List<MesaModel>> listarLivres() async {
    final result = await _db.query('''
      SELECT * FROM v_mesas_completo
      WHERE status = 'livre'
      ORDER BY numero
    ''');

    return result.map((map) => MesaModel.fromMap(map)).toList();
  }

  /// Lista mesas ocupadas
  Future<List<MesaModel>> listarOcupadas() async {
    final result = await _db.query('''
      SELECT * FROM v_mesas_completo
      WHERE status = 'ocupada'
      ORDER BY numero
    ''');

    return result.map((map) => MesaModel.fromMap(map)).toList();
  }

  /// Busca mesa por ID
  Future<MesaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_mesas_completo WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return MesaModel.fromMap(result.first);
  }

  /// Busca mesa por número
  Future<MesaModel?> buscarPorNumero(int numero) async {
    final result = await _db.query('''
      SELECT * FROM v_mesas_completo WHERE numero = @numero
    ''', parameters: {'numero': numero});

    if (result.isEmpty) return null;
    return MesaModel.fromMap(result.first);
  }

  /// Insere nova mesa
  Future<int> inserir(MesaModel mesa) async {
    return await _db.insert('''
      INSERT INTO mesas (numero, local_id, capacidade, ativo)
      VALUES (@numero, @local_id, @capacidade, @ativo)
    ''', parameters: mesa.toMap());
  }

  /// Atualiza mesa
  Future<void> atualizar(int id, MesaModel mesa) async {
    await _db.execute('''
      UPDATE mesas
      SET numero = @numero,
          local_id = @local_id,
          capacidade = @capacidade,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...mesa.toMap(),
      'id': id,
    });
  }

  /// Deleta mesa (soft delete)
  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE mesas SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }

  /// Cria mesas em lote para um local
  Future<void> criarMesasLote({
    required int localId,
    required int quantidadeMesas,
    int numeroInicial = 1,
  }) async {
    for (int i = 0; i < quantidadeMesas; i++) {
      final numero = numeroInicial + i;
      await _db.execute('''
        INSERT INTO mesas (numero, local_id)
        VALUES (@numero, @local_id)
        ON CONFLICT (numero) DO NOTHING
      ''', parameters: {
        'numero': numero,
        'local_id': localId,
      });
    }
  }

  /// Verifica se mesa está livre
  Future<bool> isLivre(int mesaId) async {
    final result = await _db.query('''
      SELECT status FROM v_mesas_completo WHERE id = @id
    ''', parameters: {'id': mesaId});

    if (result.isEmpty) return false;
    return result.first['status'] == 'livre';
  }
}
