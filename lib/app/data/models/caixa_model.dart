class CaixaModel {
  final int? id;
  final String numero;
  final String? terminal;
  final String? usuario;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String status;

  // Vendas pagas (dinheiro entrou no caixa)
  final double totalVendasPagas;
  final int qtdVendasPagas;

  // Totais por forma de pagamento (vendas + pagamentos de dívidas)
  final double totalCash;
  final int qtdTransacoesCash;

  final double totalEmola;
  final int qtdTransacoesEmola;

  final double totalMpesa;
  final int qtdTransacoesMpesa;

  final double totalPos;
  final int qtdTransacoesPos;

  // Vendas a crédito (dinheiro NÃO entrou ainda)
  final double totalVendasCredito;
  final int qtdVendasCredito;

  // Pagamentos de dívidas antigas (dinheiro entrou)
  final double totalDividasPagas;
  final int qtdDividasPagas;

  // Despesas (dinheiro saiu)
  final double totalDespesas;
  final int qtdDespesas;

  // Saldo final
  final double totalEntradas;
  final double totalSaidas;
  final double saldoFinal;

  final String? observacoes;
  final DateTime? createdAt;

  // Campos adicionais da view
  final double? somaFormasValidacao;
  final String? statusValidacao;
  final bool? totaisCorretos;

  CaixaModel({
    this.id,
    required this.numero,
    this.terminal,
    this.usuario,
    required this.dataAbertura,
    this.dataFechamento,
    this.status = 'ABERTO',
    this.totalVendasPagas = 0,
    this.qtdVendasPagas = 0,
    this.totalCash = 0,
    this.qtdTransacoesCash = 0,
    this.totalEmola = 0,
    this.qtdTransacoesEmola = 0,
    this.totalMpesa = 0,
    this.qtdTransacoesMpesa = 0,
    this.totalPos = 0,
    this.qtdTransacoesPos = 0,
    this.totalVendasCredito = 0,
    this.qtdVendasCredito = 0,
    this.totalDividasPagas = 0,
    this.qtdDividasPagas = 0,
    this.totalDespesas = 0,
    this.qtdDespesas = 0,
    this.totalEntradas = 0,
    this.totalSaidas = 0,
    this.saldoFinal = 0,
    this.observacoes,
    this.createdAt,
    this.somaFormasValidacao,
    this.statusValidacao,
    this.totaisCorretos,
  });

  factory CaixaModel.fromMap(Map<String, dynamic> map) {
    return CaixaModel(
      id: map['id'],
      numero: map['numero'],
      terminal: map['terminal'],
      usuario: map['usuario'],
      dataAbertura: DateTime.parse(map['data_abertura'].toString()),
      dataFechamento: map['data_fechamento'] != null
          ? DateTime.parse(map['data_fechamento'].toString())
          : null,
      status: map['status'] ?? 'ABERTO',
      totalVendasPagas: double.tryParse(map['total_vendas_pagas']?.toString() ?? '0') ?? 0.0,
      qtdVendasPagas: map['qtd_vendas_pagas'] ?? 0,
      totalCash: double.tryParse(map['total_cash']?.toString() ?? '0') ?? 0.0,
      qtdTransacoesCash: map['qtd_transacoes_cash'] ?? 0,
      totalEmola: double.tryParse(map['total_emola']?.toString() ?? '0') ?? 0.0,
      qtdTransacoesEmola: map['qtd_transacoes_emola'] ?? 0,
      totalMpesa: double.tryParse(map['total_mpesa']?.toString() ?? '0') ?? 0.0,
      qtdTransacoesMpesa: map['qtd_transacoes_mpesa'] ?? 0,
      totalPos: double.tryParse(map['total_pos']?.toString() ?? '0') ?? 0.0,
      qtdTransacoesPos: map['qtd_transacoes_pos'] ?? 0,
      totalVendasCredito: double.tryParse(map['total_vendas_credito']?.toString() ?? '0') ?? 0.0,
      qtdVendasCredito: map['qtd_vendas_credito'] ?? 0,
      totalDividasPagas: double.tryParse(map['total_dividas_pagas']?.toString() ?? '0') ?? 0.0,
      qtdDividasPagas: map['qtd_dividas_pagas'] ?? 0,
      totalDespesas: double.tryParse(map['total_despesas']?.toString() ?? '0') ?? 0.0,
      qtdDespesas: map['qtd_despesas'] ?? 0,
      totalEntradas: double.tryParse(map['total_entradas']?.toString() ?? '0') ?? 0.0,
      totalSaidas: double.tryParse(map['total_saidas']?.toString() ?? '0') ?? 0.0,
      saldoFinal: double.tryParse(map['saldo_final']?.toString() ?? '0') ?? 0.0,
      observacoes: map['observacoes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      somaFormasValidacao: map['soma_formas_validacao'] != null
          ? double.tryParse(map['soma_formas_validacao'].toString()) ?? 0.0
          : null,
      statusValidacao: map['status_validacao'],
      totaisCorretos: map['totais_corretos'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'terminal': terminal,
      'usuario': usuario,
      'data_abertura': dataAbertura.toIso8601String(),
      'data_fechamento': dataFechamento?.toIso8601String(),
      'status': status,
      'observacoes': observacoes,
    };
  }

  CaixaModel copyWith({
    int? id,
    String? numero,
    String? terminal,
    String? usuario,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    String? status,
    double? totalVendasPagas,
    int? qtdVendasPagas,
    double? totalCash,
    int? qtdTransacoesCash,
    double? totalEmola,
    int? qtdTransacoesEmola,
    double? totalMpesa,
    int? qtdTransacoesMpesa,
    double? totalPos,
    int? qtdTransacoesPos,
    double? totalVendasCredito,
    int? qtdVendasCredito,
    double? totalDividasPagas,
    int? qtdDividasPagas,
    double? totalDespesas,
    int? qtdDespesas,
    double? totalEntradas,
    double? totalSaidas,
    double? saldoFinal,
    String? observacoes,
    DateTime? createdAt,
    double? somaFormasValidacao,
    String? statusValidacao,
    bool? totaisCorretos,
  }) {
    return CaixaModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      terminal: terminal ?? this.terminal,
      usuario: usuario ?? this.usuario,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      status: status ?? this.status,
      totalVendasPagas: totalVendasPagas ?? this.totalVendasPagas,
      qtdVendasPagas: qtdVendasPagas ?? this.qtdVendasPagas,
      totalCash: totalCash ?? this.totalCash,
      qtdTransacoesCash: qtdTransacoesCash ?? this.qtdTransacoesCash,
      totalEmola: totalEmola ?? this.totalEmola,
      qtdTransacoesEmola: qtdTransacoesEmola ?? this.qtdTransacoesEmola,
      totalMpesa: totalMpesa ?? this.totalMpesa,
      qtdTransacoesMpesa: qtdTransacoesMpesa ?? this.qtdTransacoesMpesa,
      totalPos: totalPos ?? this.totalPos,
      qtdTransacoesPos: qtdTransacoesPos ?? this.qtdTransacoesPos,
      totalVendasCredito: totalVendasCredito ?? this.totalVendasCredito,
      qtdVendasCredito: qtdVendasCredito ?? this.qtdVendasCredito,
      totalDividasPagas: totalDividasPagas ?? this.totalDividasPagas,
      qtdDividasPagas: qtdDividasPagas ?? this.qtdDividasPagas,
      totalDespesas: totalDespesas ?? this.totalDespesas,
      qtdDespesas: qtdDespesas ?? this.qtdDespesas,
      totalEntradas: totalEntradas ?? this.totalEntradas,
      totalSaidas: totalSaidas ?? this.totalSaidas,
      saldoFinal: saldoFinal ?? this.saldoFinal,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      somaFormasValidacao: somaFormasValidacao ?? this.somaFormasValidacao,
      statusValidacao: statusValidacao ?? this.statusValidacao,
      totaisCorretos: totaisCorretos ?? this.totaisCorretos,
    );
  }
}
