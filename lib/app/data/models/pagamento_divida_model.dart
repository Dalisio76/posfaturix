class PagamentoDividaModel {
  final int? id;
  final int dividaId;
  final double valor;
  final int? formaPagamentoId;
  final DateTime dataPagamento;
  final String? observacoes;
  final String? usuario;
  final DateTime? createdAt;

  // Campo adicional de view
  final String? formaPagamentoNome;

  PagamentoDividaModel({
    this.id,
    required this.dividaId,
    required this.valor,
    this.formaPagamentoId,
    required this.dataPagamento,
    this.observacoes,
    this.usuario,
    this.createdAt,
    this.formaPagamentoNome,
  });

  factory PagamentoDividaModel.fromMap(Map<String, dynamic> map) {
    return PagamentoDividaModel(
      id: map['id'],
      dividaId: map['divida_id'],
      valor: double.parse(map['valor'].toString()),
      formaPagamentoId: map['forma_pagamento_id'],
      dataPagamento: DateTime.parse(map['data_pagamento'].toString()),
      observacoes: map['observacoes'],
      usuario: map['usuario'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      formaPagamentoNome: map['forma_pagamento_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'divida_id': dividaId,
      'valor': valor,
      'forma_pagamento_id': formaPagamentoId,
      'data_pagamento': dataPagamento.toIso8601String(),
      'observacoes': observacoes,
      'usuario': usuario,
    };
  }

  @override
  String toString() =>
      'PagamentoDivida(id: $id, divida_id: $dividaId, valor: $valor)';
}
