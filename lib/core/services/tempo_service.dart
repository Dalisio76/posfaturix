import 'package:get/get.dart';
import '../database/database_service.dart';

/// Serviço de Controle de Tempo
/// Protege contra alteração de data do sistema e vendas retroativas
class TempoService {
  static final _db = Get.find<DatabaseService>();

  /// Verifica se pode vender hoje (data do sistema está OK)
  static Future<TempoValidacao> podeVenderHoje() async {
    try {
      final resultado = await _db.query('SELECT * FROM pode_vender_hoje()');

      if (resultado.isEmpty) {
        return TempoValidacao(
          podeVender: false,
          mensagem: 'Erro ao verificar data do sistema',
          dataSistema: DateTime.now(),
        );
      }

      final row = resultado.first;

      return TempoValidacao(
        podeVender: row['pode_vender'] as bool,
        mensagem: row['mensagem'] as String,
        dataSistema: row['data_sistema'] != null
            ? DateTime.parse(row['data_sistema'].toString())
            : DateTime.now(),
        dataUltimoFecho: row['data_ultimo_fecho'] != null
            ? DateTime.parse(row['data_ultimo_fecho'].toString())
            : null,
        diferencaDias: row['diferenca_dias'] as int?,
      );
    } catch (e) {
      print('Erro ao verificar data: $e');
      return TempoValidacao(
        podeVender: false,
        mensagem: 'Erro ao verificar data: $e',
        dataSistema: DateTime.now(),
      );
    }
  }

  /// Registra fecho de caixa
  static Future<int?> registrarFechoCaixa({
    required DateTime dataFecho,
    required int usuarioId,
    required double valorTotal,
  }) async {
    try {
      final resultado = await _db.query(
        '''
        SELECT registrar_fecho_caixa(@data_fecho, @usuario_id, @valor_total) as fecho_id
        ''',
        parameters: {
          'data_fecho': dataFecho.toIso8601String().split('T')[0],
          'usuario_id': usuarioId,
          'valor_total': valorTotal,
        },
      );

      if (resultado.isEmpty) return null;
      return resultado.first['fecho_id'] as int;
    } catch (e) {
      print('Erro ao registrar fecho: $e');
      rethrow;
    }
  }

  /// Verifica anomalias de data (vendas com datas suspeitas)
  static Future<List<AnomaliaData>> verificarAnomalias() async {
    try {
      final resultado = await _db.query('SELECT * FROM vw_anomalias_data');

      return resultado.map((row) {
        return AnomaliaData(
          vendaId: row['venda_id'] as int,
          vendaNumero: row['venda_numero'] as String,
          dataVenda: DateTime.parse(row['data_venda'].toString()),
          vendaAnterior: row['venda_anterior'] != null
              ? DateTime.parse(row['venda_anterior'].toString())
              : null,
          status: row['status'] as String,
        );
      }).toList();
    } catch (e) {
      print('Erro ao verificar anomalias: $e');
      return [];
    }
  }

  /// Obtém data do servidor PostgreSQL (confiável, não pode ser alterada pelo usuário)
  static Future<DateTime> obterDataServidor() async {
    try {
      final resultado = await _db.query('SELECT CURRENT_TIMESTAMP as data_servidor');
      if (resultado.isEmpty) return DateTime.now();

      return DateTime.parse(resultado.first['data_servidor'].toString());
    } catch (e) {
      print('Erro ao obter data do servidor: $e');
      return DateTime.now();
    }
  }

  /// Verifica se há diferença significativa entre data do sistema e do servidor
  static Future<DiferencaTempo> verificarDiferencaTempo() async {
    try {
      final dataServidor = await obterDataServidor();
      final dataSistema = DateTime.now();

      final diferenca = dataSistema.difference(dataServidor);

      return DiferencaTempo(
        dataSistema: dataSistema,
        dataServidor: dataServidor,
        diferencaMinutos: diferenca.inMinutes,
        sincronizado: diferenca.inMinutes.abs() < 5, // Tolerância de 5 minutos
      );
    } catch (e) {
      print('Erro ao verificar diferença de tempo: $e');
      return DiferencaTempo(
        dataSistema: DateTime.now(),
        dataServidor: DateTime.now(),
        diferencaMinutos: 0,
        sincronizado: false,
      );
    }
  }

  /// Limpa registros antigos de tempo (manutenção)
  static Future<int> limparRegistrosAntigos() async {
    try {
      final resultado = await _db.query('SELECT limpar_servidor_tempo() as linhas');
      if (resultado.isEmpty) return 0;
      return resultado.first['linhas'] as int;
    } catch (e) {
      print('Erro ao limpar registros: $e');
      return 0;
    }
  }
}

/// Modelo de validação de tempo
class TempoValidacao {
  final bool podeVender;
  final String mensagem;
  final DateTime dataSistema;
  final DateTime? dataUltimoFecho;
  final int? diferencaDias;

  TempoValidacao({
    required this.podeVender,
    required this.mensagem,
    required this.dataSistema,
    this.dataUltimoFecho,
    this.diferencaDias,
  });

  bool get temAlerta => !podeVender || (diferencaDias != null && diferencaDias! > 1);
}

/// Modelo de anomalia de data
class AnomaliaData {
  final int vendaId;
  final String vendaNumero;
  final DateTime dataVenda;
  final DateTime? vendaAnterior;
  final String status;

  AnomaliaData({
    required this.vendaId,
    required this.vendaNumero,
    required this.dataVenda,
    this.vendaAnterior,
    required this.status,
  });

  bool get temProblema =>
      status == 'RETROCESSO DETECTADO' || status == 'SALTO GRANDE';
}

/// Modelo de diferença de tempo
class DiferencaTempo {
  final DateTime dataSistema;
  final DateTime dataServidor;
  final int diferencaMinutos;
  final bool sincronizado;

  DiferencaTempo({
    required this.dataSistema,
    required this.dataServidor,
    required this.diferencaMinutos,
    required this.sincronizado,
  });

  String get mensagem {
    if (sincronizado) {
      return 'Data e hora sincronizadas';
    }

    if (diferencaMinutos > 0) {
      return 'Relógio do sistema está $diferencaMinutos minutos ADIANTADO';
    } else {
      return 'Relógio do sistema está ${diferencaMinutos.abs()} minutos ATRASADO';
    }
  }
}
