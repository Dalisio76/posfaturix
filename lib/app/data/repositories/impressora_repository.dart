import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/impressora_model.dart';

class ImpressoraRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  // ==========================================
  // IMPRESSORAS
  // ==========================================

  Future<List<ImpressoraModel>> listarTodas() async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM impressoras ORDER BY nome',
      );
      return resultado.map((r) => ImpressoraModel.fromMap(r)).toList();
    } catch (e) {
      print('Erro ao listar impressoras: $e');
      rethrow;
    }
  }

  Future<List<ImpressoraModel>> listarAtivas() async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM impressoras WHERE ativo = true ORDER BY nome',
      );
      return resultado.map((r) => ImpressoraModel.fromMap(r)).toList();
    } catch (e) {
      print('Erro ao listar impressoras ativas: $e');
      rethrow;
    }
  }

  Future<ImpressoraModel?> buscarPorId(int id) async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM impressoras WHERE id = @id',
        parameters: {'id': id},
      );
      if (resultado.isEmpty) return null;
      return ImpressoraModel.fromMap(resultado.first);
    } catch (e) {
      print('Erro ao buscar impressora: $e');
      rethrow;
    }
  }

  Future<ImpressoraModel?> buscarPorNome(String nome) async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM impressoras WHERE nome = @nome',
        parameters: {'nome': nome},
      );
      if (resultado.isEmpty) return null;
      return ImpressoraModel.fromMap(resultado.first);
    } catch (e) {
      print('Erro ao buscar impressora por nome: $e');
      rethrow;
    }
  }

  Future<int> criar(ImpressoraModel impressora) async {
    try {
      final resultado = await _db.query(
        '''
        INSERT INTO impressoras (nome, tipo, descricao, largura_papel, ativo, caminho_rede)
        VALUES (@nome, @tipo, @descricao, @largura_papel, @ativo, @caminho_rede)
        RETURNING id
        ''',
        parameters: {
          'nome': impressora.nome,
          'tipo': impressora.tipo,
          'descricao': impressora.descricao,
          'largura_papel': impressora.larguraPapel,
          'ativo': impressora.ativo,
          'caminho_rede': impressora.caminhoRede,
        },
      );
      return resultado.first['id'] as int;
    } catch (e) {
      print('Erro ao criar impressora: $e');
      rethrow;
    }
  }

  Future<void> atualizar(ImpressoraModel impressora) async {
    try {
      await _db.execute(
        '''
        UPDATE impressoras
        SET nome = @nome,
            tipo = @tipo,
            descricao = @descricao,
            largura_papel = @largura_papel,
            ativo = @ativo,
            caminho_rede = @caminho_rede
        WHERE id = @id
        ''',
        parameters: {
          'id': impressora.id,
          'nome': impressora.nome,
          'tipo': impressora.tipo,
          'descricao': impressora.descricao,
          'largura_papel': impressora.larguraPapel,
          'ativo': impressora.ativo,
          'caminho_rede': impressora.caminhoRede,
        },
      );
    } catch (e) {
      print('Erro ao atualizar impressora: $e');
      rethrow;
    }
  }

  Future<void> deletar(int id) async {
    try {
      await _db.execute(
        'DELETE FROM impressoras WHERE id = @id',
        parameters: {'id': id},
      );
    } catch (e) {
      print('Erro ao deletar impressora: $e');
      rethrow;
    }
  }

  // ==========================================
  // TIPOS DE DOCUMENTO
  // ==========================================

  Future<List<TipoDocumentoModel>> listarTiposDocumento() async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM tipos_documento WHERE ativo = true ORDER BY nome',
      );
      return resultado.map((r) => TipoDocumentoModel.fromMap(r)).toList();
    } catch (e) {
      print('Erro ao listar tipos de documento: $e');
      rethrow;
    }
  }

  Future<TipoDocumentoModel?> buscarTipoDocumentoPorCodigo(String codigo) async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM tipos_documento WHERE codigo = @codigo',
        parameters: {'codigo': codigo},
      );
      if (resultado.isEmpty) return null;
      return TipoDocumentoModel.fromMap(resultado.first);
    } catch (e) {
      print('Erro ao buscar tipo de documento: $e');
      rethrow;
    }
  }

  // ==========================================
  // MAPEAMENTO DOCUMENTO-IMPRESSORA
  // ==========================================

  Future<List<DocumentoImpressoraModel>> listarMapeamentos() async {
    try {
      final resultado = await _db.query(
        'SELECT * FROM vw_mapeamento_impressao',
      );
      return resultado.map((r) => DocumentoImpressoraModel.fromMap(r)).toList();
    } catch (e) {
      print('Erro ao listar mapeamentos: $e');
      rethrow;
    }
  }

  Future<ImpressoraModel?> buscarImpressoraPorDocumento(String codigoDocumento) async {
    try {
      final resultado = await _db.query(
        '''
        SELECT i.*
        FROM tipos_documento td
        JOIN documento_impressora di ON di.tipo_documento_id = td.id
        JOIN impressoras i ON i.id = di.impressora_id
        WHERE td.codigo = @codigo AND i.ativo = true
        ORDER BY di.prioridade
        LIMIT 1
        ''',
        parameters: {'codigo': codigoDocumento},
      );
      if (resultado.isEmpty) return null;
      return ImpressoraModel.fromMap(resultado.first);
    } catch (e) {
      print('Erro ao buscar impressora por documento: $e');
      rethrow;
    }
  }

  Future<void> associarDocumentoImpressora({
    required int tipoDocumentoId,
    required int impressoraId,
    int prioridade = 1,
  }) async {
    try {
      await _db.execute(
        '''
        INSERT INTO documento_impressora (tipo_documento_id, impressora_id, prioridade)
        VALUES (@tipo_documento_id, @impressora_id, @prioridade)
        ON CONFLICT (tipo_documento_id, impressora_id)
        DO UPDATE SET prioridade = @prioridade
        ''',
        parameters: {
          'tipo_documento_id': tipoDocumentoId,
          'impressora_id': impressoraId,
          'prioridade': prioridade,
        },
      );
    } catch (e) {
      print('Erro ao associar documento à impressora: $e');
      rethrow;
    }
  }

  Future<void> removerAssociacaoDocumentoImpressora({
    required int tipoDocumentoId,
    required int impressoraId,
  }) async {
    try {
      await _db.execute(
        '''
        DELETE FROM documento_impressora
        WHERE tipo_documento_id = @tipo_documento_id
          AND impressora_id = @impressora_id
        ''',
        parameters: {
          'tipo_documento_id': tipoDocumentoId,
          'impressora_id': impressoraId,
        },
      );
    } catch (e) {
      print('Erro ao remover associação: $e');
      rethrow;
    }
  }

  // ==========================================
  // IMPRESSORA POR ÁREA
  // ==========================================

  Future<ImpressoraModel?> buscarImpressoraPorArea(int areaId) async {
    try {
      final resultado = await _db.query(
        '''
        SELECT i.*
        FROM areas a
        JOIN impressoras i ON i.id = a.impressora_id
        WHERE a.id = @area_id AND i.ativo = true
        ''',
        parameters: {'area_id': areaId},
      );
      if (resultado.isEmpty) return null;
      return ImpressoraModel.fromMap(resultado.first);
    } catch (e) {
      print('Erro ao buscar impressora por área: $e');
      rethrow;
    }
  }

  Future<void> associarImpressoraArea({
    required int areaId,
    required int impressoraId,
  }) async {
    try {
      await _db.execute(
        '''
        UPDATE areas
        SET impressora_id = @impressora_id
        WHERE id = @area_id
        ''',
        parameters: {
          'area_id': areaId,
          'impressora_id': impressoraId,
        },
      );
    } catch (e) {
      print('Erro ao associar impressora à área: $e');
      rethrow;
    }
  }

  Future<void> removerImpressoraArea(int areaId) async {
    try {
      await _db.execute(
        '''
        UPDATE areas
        SET impressora_id = NULL
        WHERE id = @area_id
        ''',
        parameters: {'area_id': areaId},
      );
    } catch (e) {
      print('Erro ao remover impressora da área: $e');
      rethrow;
    }
  }
}
