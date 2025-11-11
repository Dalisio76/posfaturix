import 'item_venda_model.dart';

class VendaModel {
  final int? id;
  final String numero;
  final double total;
  final DateTime dataVenda;
  final String? terminal;
  final int? formaPagamentoId;

  // Itens da venda
  final List<ItemVendaModel>? itens;

  // Campo adicional para joins
  final String? formaPagamentoNome;

  VendaModel({
    this.id,
    required this.numero,
    required this.total,
    required this.dataVenda,
    this.terminal,
    this.formaPagamentoId,
    this.itens,
    this.formaPagamentoNome,
  });

  factory VendaModel.fromMap(Map<String, dynamic> map) {
    return VendaModel(
      id: map['id'],
      numero: map['numero'],
      total: double.parse(map['total'].toString()),
      dataVenda: DateTime.parse(map['data_venda'].toString()),
      terminal: map['terminal'],
      formaPagamentoId: map['forma_pagamento_id'],
      formaPagamentoNome: map['forma_pagamento_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'total': total,
      'data_venda': dataVenda.toIso8601String(),
      'terminal': terminal,
      'forma_pagamento_id': formaPagamentoId,
    };
  }
}
