class PagamentoVendaModel {
  final int? id;
  final int vendaId;
  final int formaPagamentoId;
  final double valor;
  final DateTime? createdAt;

  // Campos adicionais para joins
  final String? formaPagamentoNome;

  PagamentoVendaModel({
    this.id,
    required this.vendaId,
    required this.formaPagamentoId,
    required this.valor,
    this.createdAt,
    this.formaPagamentoNome,
  });

  factory PagamentoVendaModel.fromMap(Map<String, dynamic> map) {
    return PagamentoVendaModel(
      id: map['id'],
      vendaId: map['venda_id'],
      formaPagamentoId: map['forma_pagamento_id'],
      valor: double.parse(map['valor'].toString()),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      formaPagamentoNome: map['forma_pagamento_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venda_id': vendaId,
      'forma_pagamento_id': formaPagamentoId,
      'valor': valor,
    };
  }

  @override
  String toString() =>
      'PagamentoVenda(id: $id, formaPagamento: $formaPagamentoNome, valor: $valor)';
}
