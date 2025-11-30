import 'dart:convert';

/// Modelo para registro de auditoria
class AuditoriaModel {
  final int? id;
  final String tabela;
  final String operacao; // INSERT, UPDATE, DELETE
  final int? registroId;
  final int? usuarioId;
  final String? usuarioNome;
  final String? terminalNome;
  final Map<String, dynamic>? dadosAnteriores;
  final Map<String, dynamic>? dadosNovos;
  final String? ipAddress;
  final String? descricao;
  final DateTime dataOperacao;

  AuditoriaModel({
    this.id,
    required this.tabela,
    required this.operacao,
    this.registroId,
    this.usuarioId,
    this.usuarioNome,
    this.terminalNome,
    this.dadosAnteriores,
    this.dadosNovos,
    this.ipAddress,
    this.descricao,
    required this.dataOperacao,
  });

  factory AuditoriaModel.fromMap(Map<String, dynamic> map) {
    return AuditoriaModel(
      id: map['id'] as int?,
      tabela: map['tabela'] as String,
      operacao: map['operacao'] as String,
      registroId: map['registro_id'] as int?,
      usuarioId: map['usuario_id'] as int?,
      usuarioNome: map['usuario_nome'] as String?,
      terminalNome: map['terminal_nome'] as String?,
      dadosAnteriores: map['dados_anteriores'] != null
          ? (map['dados_anteriores'] is String
              ? jsonDecode(map['dados_anteriores'])
              : map['dados_anteriores'] as Map<String, dynamic>)
          : null,
      dadosNovos: map['dados_novos'] != null
          ? (map['dados_novos'] is String
              ? jsonDecode(map['dados_novos'])
              : map['dados_novos'] as Map<String, dynamic>)
          : null,
      ipAddress: map['ip_address'] as String?,
      descricao: map['descricao'] as String?,
      dataOperacao: DateTime.parse(map['data_operacao'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tabela': tabela,
      'operacao': operacao,
      'registro_id': registroId,
      'usuario_id': usuarioId,
      'terminal_nome': terminalNome,
      'dados_anteriores': dadosAnteriores != null ? jsonEncode(dadosAnteriores) : null,
      'dados_novos': dadosNovos != null ? jsonEncode(dadosNovos) : null,
      'ip_address': ipAddress,
      'descricao': descricao,
      'data_operacao': dataOperacao.toIso8601String(),
    };
  }

  /// Retorna a operação em português
  String get operacaoLegivel {
    switch (operacao) {
      case 'INSERT':
        return 'Criação';
      case 'UPDATE':
        return 'Atualização';
      case 'DELETE':
        return 'Exclusão';
      default:
        return operacao;
    }
  }

  /// Retorna o nome da tabela em português
  String get tabelaLegivel {
    switch (tabela) {
      case 'produtos':
        return 'Produtos';
      case 'vendas':
        return 'Vendas';
      case 'vendas_itens':
        return 'Itens de Venda';
      case 'usuarios':
        return 'Usuários';
      case 'usuario_permissoes':
        return 'Permissões';
      case 'clientes':
        return 'Clientes';
      case 'familias':
        return 'Famílias';
      case 'impressoras':
        return 'Impressoras';
      case 'areas':
        return 'Áreas';
      case 'mesas':
        return 'Mesas';
      default:
        return tabela;
    }
  }
}

/// Modelo para log de acesso (login/logout)
class LogAcessoModel {
  final int? id;
  final int? usuarioId;
  final String? usuarioNome;
  final String? usuarioCodigo;
  final String? terminalNome;
  final String? ipAddress;
  final String tipo; // LOGIN, LOGOUT, LOGIN_FALHOU
  final bool sucesso;
  final String? motivoFalha;
  final DateTime dataHora;
  final int? tentativasUltimaHora;

  LogAcessoModel({
    this.id,
    this.usuarioId,
    this.usuarioNome,
    this.usuarioCodigo,
    this.terminalNome,
    this.ipAddress,
    required this.tipo,
    this.sucesso = true,
    this.motivoFalha,
    required this.dataHora,
    this.tentativasUltimaHora,
  });

  factory LogAcessoModel.fromMap(Map<String, dynamic> map) {
    return LogAcessoModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int?,
      usuarioNome: map['usuario_nome'] as String?,
      usuarioCodigo: map['usuario_codigo'] as String?,
      terminalNome: map['terminal_nome'] as String?,
      ipAddress: map['ip_address'] as String?,
      tipo: map['tipo'] as String,
      sucesso: map['sucesso'] == true || map['sucesso'] == 1,
      motivoFalha: map['motivo_falha'] as String?,
      dataHora: DateTime.parse(map['data_hora'] as String),
      tentativasUltimaHora: map['tentativas_ultima_hora'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'terminal_nome': terminalNome,
      'ip_address': ipAddress,
      'tipo': tipo,
      'sucesso': sucesso,
      'motivo_falha': motivoFalha,
      'data_hora': dataHora.toIso8601String(),
    };
  }

  /// Retorna o tipo em português
  String get tipoLegivel {
    switch (tipo) {
      case 'LOGIN':
        return 'Login';
      case 'LOGOUT':
        return 'Logout';
      case 'LOGIN_FALHOU':
        return 'Login Falhou';
      default:
        return tipo;
    }
  }

  /// Retorna ícone baseado no tipo
  String get icone {
    switch (tipo) {
      case 'LOGIN':
        return '✅';
      case 'LOGOUT':
        return '🚪';
      case 'LOGIN_FALHOU':
        return '❌';
      default:
        return '📋';
    }
  }
}

/// Modelo para resumo de auditoria por usuário
class AuditoriaPorUsuarioModel {
  final int usuarioId;
  final String usuarioNome;
  final String tabela;
  final String operacao;
  final int totalOperacoes;
  final DateTime ultimaOperacao;

  AuditoriaPorUsuarioModel({
    required this.usuarioId,
    required this.usuarioNome,
    required this.tabela,
    required this.operacao,
    required this.totalOperacoes,
    required this.ultimaOperacao,
  });

  factory AuditoriaPorUsuarioModel.fromMap(Map<String, dynamic> map) {
    return AuditoriaPorUsuarioModel(
      usuarioId: map['usuario_id'] as int,
      usuarioNome: map['usuario_nome'] as String,
      tabela: map['tabela'] as String,
      operacao: map['operacao'] as String,
      totalOperacoes: map['total_operacoes'] as int,
      ultimaOperacao: DateTime.parse(map['ultima_operacao'] as String),
    );
  }
}

/// Modelo para histórico de alteração de preços
class HistoricoPrecoModel {
  final int id;
  final int produtoId;
  final String produtoNome;
  final double precoAnterior;
  final double precoNovo;
  final double diferenca;
  final int? usuarioId;
  final String? usuarioNome;
  final DateTime dataOperacao;

  HistoricoPrecoModel({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.precoAnterior,
    required this.precoNovo,
    required this.diferenca,
    this.usuarioId,
    this.usuarioNome,
    required this.dataOperacao,
  });

  factory HistoricoPrecoModel.fromMap(Map<String, dynamic> map) {
    return HistoricoPrecoModel(
      id: map['id'] as int,
      produtoId: map['produto_id'] as int,
      produtoNome: map['produto_nome'] as String,
      precoAnterior: (map['preco_anterior'] as num).toDouble(),
      precoNovo: (map['preco_novo'] as num).toDouble(),
      diferenca: (map['diferenca'] as num).toDouble(),
      usuarioId: map['usuario_id'] as int?,
      usuarioNome: map['usuario_nome'] as String?,
      dataOperacao: DateTime.parse(map['data_operacao'] as String),
    );
  }

  /// Retorna se houve aumento ou diminuição
  String get tipoAlteracao {
    return diferenca > 0 ? 'Aumento' : 'Diminuição';
  }

  /// Retorna percentual de alteração
  double get percentualAlteracao {
    if (precoAnterior == 0) return 0;
    return (diferenca / precoAnterior) * 100;
  }
}
