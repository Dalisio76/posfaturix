class DespesaModel {
  final int? id;
  final String descricao;
  final double valor;
  final String? categoria;
  final DateTime dataDespesa;
  final int? formaPagamentoId;
  final String? observacoes;
  final String? usuario;
  final DateTime? createdAt;

  // Campo adicional de view
  final String? formaPagamentoNome;

  DespesaModel({
    this.id,
    required this.descricao,
    required this.valor,
    this.categoria,
    required this.dataDespesa,
    this.formaPagamentoId,
    this.observacoes,
    this.usuario,
    this.createdAt,
    this.formaPagamentoNome,
  });

  factory DespesaModel.fromMap(Map<String, dynamic> map) {
    return DespesaModel(
      id: map['id'],
      descricao: map['descricao'],
      valor: double.parse(map['valor'].toString()),
      categoria: map['categoria'],
      dataDespesa: DateTime.parse(map['data_despesa'].toString()),
      formaPagamentoId: map['forma_pagamento_id'],
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
      'descricao': descricao,
      'valor': valor,
      'categoria': categoria,
      'data_despesa': dataDespesa.toIso8601String(),
      'forma_pagamento_id': formaPagamentoId,
      'observacoes': observacoes,
      'usuario': usuario,
    };
  }

  @override
  String toString() =>
      'Despesa(id: $id, descricao: $descricao, valor: $valor, categoria: $categoria)';
}
