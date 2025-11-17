import 'package:get/get.dart';
import 'package:postgres/postgres.dart';
import '../../../core/database/database_service.dart';
import '../models/caixa_model.dart';
import '../models/caixa_detalhe_model.dart';
import '../models/conferencia_model.dart';

class CaixaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Buscar caixa atual (aberto)
  Future<CaixaModel?> buscarCaixaAtual() async {
    try {
      final result = await _db.query('SELECT * FROM v_caixa_atual');

      if (result.isEmpty) {
        return null;
      }

      return CaixaModel.fromMap(result.first);
    } catch (e) {
      print('Erro ao buscar caixa atual: $e');
      rethrow;
    }
  }

  /// Abrir um novo caixa
  Future<int> abrirCaixa({
    String terminal = 'TERMINAL-01',
    String usuario = 'Sistema',
  }) async {
    try {
      final result = await _db.query(
        'SELECT abrir_caixa(@terminal, @usuario) as caixa_id',
        parameters: {
          'terminal': terminal,
          'usuario': usuario,
        },
      );

      if (result.isEmpty) {
        throw Exception('Nenhum resultado retornado ao abrir caixa');
      }

      final row = result.first;

      // Tentar acessar por nome da coluna
      if (row.containsKey('caixa_id')) {
        return int.parse(row['caixa_id'].toString());
      }

      // Tentar acessar o primeiro valor
      if (row.values.isNotEmpty) {
        final valor = row.values.first;
        if (valor != null) {
          return int.parse(valor.toString());
        }
      }

      throw Exception('Não foi possível extrair o ID do caixa do resultado');
    } catch (e) {
      print('Erro ao abrir caixa: $e');
      rethrow;
    }
  }

  /// Calcular totais do caixa (pode ser chamado a qualquer momento)
  Future<void> calcularTotais(int caixaId) async {
    try {
      await _db.query(
        'SELECT calcular_totais_caixa(@caixa_id)',
        parameters: {'caixa_id': caixaId},
      );
    } catch (e) {
      print('Erro ao calcular totais: $e');
      rethrow;
    }
  }

  /// Fechar o caixa
  Future<Map<String, dynamic>> fecharCaixa(
    int caixaId, {
    String? observacoes,
  }) async {
    try {
      final result = await _db.query(
        'SELECT * FROM fechar_caixa(@caixa_id, @observacoes)',
        parameters: {
          'caixa_id': caixaId,
          'observacoes': observacoes,
        },
      );

      if (result.isEmpty) {
        throw Exception('Erro ao fechar caixa');
      }

      final row = result.first;
      return {
        'sucesso': row[0],
        'numero_caixa': row[1],
        'saldo_final': double.tryParse(row[2]?.toString() ?? '0') ?? 0.0,
        'total_entradas': double.tryParse(row[3]?.toString() ?? '0') ?? 0.0,
        'total_saidas': double.tryParse(row[4]?.toString() ?? '0') ?? 0.0,
      };
    } catch (e) {
      print('Erro ao fechar caixa: $e');
      rethrow;
    }
  }

  /// Buscar caixa por ID
  Future<CaixaModel?> buscarPorId(int id) async {
    try {
      final result = await _db.query(
        'SELECT * FROM v_resumo_caixa WHERE id = @id',
        parameters: {'id': id},
      );

      if (result.isEmpty) {
        return null;
      }

      return CaixaModel.fromMap(result.first);
    } catch (e) {
      print('Erro ao buscar caixa: $e');
      rethrow;
    }
  }

  /// Listar histórico de caixas
  Future<List<CaixaModel>> listarCaixas({
    int limit = 50,
    String? status, // 'ABERTO' ou 'FECHADO'
  }) async {
    try {
      String sql = 'SELECT * FROM v_resumo_caixa WHERE 1=1';
      Map<String, dynamic> params = {};

      if (status != null) {
        sql += ' AND status = @status';
        params['status'] = status;
      }

      sql += ' ORDER BY data_abertura DESC LIMIT @limit';
      params['limit'] = limit;

      final result = await _db.query(sql, parameters: params);
      return result.map((map) => CaixaModel.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao listar caixas: $e');
      rethrow;
    }
  }

  /// Verificar se existe caixa aberto
  Future<bool> existeCaixaAberto() async {
    try {
      final result = await _db.query(
        'SELECT COUNT(*) FROM caixas WHERE status = @status',
        parameters: {'status': 'ABERTO'},
      );

      return (result.first[0] as int) > 0;
    } catch (e) {
      print('Erro ao verificar caixa aberto: $e');
      rethrow;
    }
  }

  /// Buscar resumo do caixa com validação
  Future<CaixaModel?> buscarResumo(int caixaId) async {
    try {
      // Primeiro calcular os totais
      await calcularTotais(caixaId);

      // Depois buscar o resumo
      final result = await _db.query(
        'SELECT * FROM v_resumo_caixa WHERE id = @id',
        parameters: {'id': caixaId},
      );

      if (result.isEmpty) {
        return null;
      }

      return CaixaModel.fromMap(result.first);
    } catch (e) {
      print('Erro ao buscar resumo: $e');
      rethrow;
    }
  }

  /// Buscar despesas do caixa
  Future<List<DespesaDetalhe>> buscarDespesas(int caixaId) async {
    try {
      final result = await _db.query(
        'SELECT * FROM v_despesas_caixa WHERE caixa_id = @caixa_id ORDER BY data_despesa DESC',
        parameters: {'caixa_id': caixaId},
      );

      return result.map((map) => DespesaDetalhe.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar despesas: $e');
      rethrow;
    }
  }

  /// Buscar pagamentos de dívidas do caixa
  Future<List<PagamentoDividaDetalhe>> buscarPagamentosDividas(int caixaId) async {
    try {
      final result = await _db.query(
        'SELECT * FROM v_pagamentos_divida_caixa WHERE caixa_id = @caixa_id ORDER BY data_pagamento DESC',
        parameters: {'caixa_id': caixaId},
      );

      return result.map((map) => PagamentoDividaDetalhe.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar pagamentos de dívidas: $e');
      rethrow;
    }
  }

  /// Buscar produtos vendidos (resumo agregado)
  Future<List<ResumoProdutoVendido>> buscarProdutosVendidos(int caixaId) async {
    try {
      final result = await _db.query(
        'SELECT * FROM v_resumo_produtos_caixa WHERE caixa_id = @caixa_id ORDER BY quantidade_total DESC',
        parameters: {'caixa_id': caixaId},
      );

      return result.map((map) => ResumoProdutoVendido.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar produtos vendidos: $e');
      rethrow;
    }
  }

  /// Buscar produtos vendidos detalhados (por venda)
  Future<List<ProdutoVendidoDetalhe>> buscarProdutosVendidosDetalhados(int caixaId) async {
    try {
      final result = await _db.query(
        'SELECT * FROM v_produtos_vendidos_caixa WHERE caixa_id = @caixa_id ORDER BY data_venda DESC, produto_nome',
        parameters: {'caixa_id': caixaId},
      );

      return result.map((map) => ProdutoVendidoDetalhe.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar produtos vendidos detalhados: $e');
      rethrow;
    }
  }

  /// Registrar conferência manual do caixa (FASE 1)
  Future<int> registrarConferencia({
    required int caixaId,
    required double contadoCash,
    required double contadoEmola,
    required double contadoMpesa,
    required double contadoPos,
    String? observacoes,
  }) async {
    try {
      final result = await _db.query(
        'SELECT registrar_conferencia_caixa(@caixa_id, @contado_cash, @contado_emola, @contado_mpesa, @contado_pos, @observacoes) as conferencia_id',
        parameters: {
          'caixa_id': caixaId,
          'contado_cash': contadoCash,
          'contado_emola': contadoEmola,
          'contado_mpesa': contadoMpesa,
          'contado_pos': contadoPos,
          'observacoes': observacoes,
        },
      );

      if (result.isEmpty) {
        throw Exception('Nenhum resultado retornado ao registrar conferência');
      }

      final row = result.first;

      // Tentar acessar por nome da coluna
      if (row.containsKey('conferencia_id')) {
        return int.parse(row['conferencia_id'].toString());
      }

      // Tentar acessar o primeiro valor
      if (row.values.isNotEmpty) {
        final valor = row.values.first;
        if (valor != null) {
          return int.parse(valor.toString());
        }
      }

      throw Exception('Não foi possível extrair o ID da conferência do resultado');
    } catch (e) {
      print('Erro ao registrar conferência: $e');
      rethrow;
    }
  }

  /// Buscar conferência do caixa (FASE 1)
  Future<ConferenciaModel?> buscarConferencia(int caixaId) async {
    try {
      final result = await _db.query(
        'SELECT * FROM conferencias_caixa WHERE caixa_id = @caixa_id ORDER BY created_at DESC LIMIT 1',
        parameters: {'caixa_id': caixaId},
      );

      if (result.isEmpty) {
        return null;
      }

      return ConferenciaModel.fromMap(result.first);
    } catch (e) {
      print('Erro ao buscar conferência: $e');
      rethrow;
    }
  }
}
