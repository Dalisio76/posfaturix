class DividaModel {
  final int? id;
  final int clienteId;
  final int? vendaId;
  final double valorTotal;
  final double valorPago;
  final double valorRestante;
  final String status;
  final String? observacoes;
  final DateTime dataDivida;
  final DateTime? dataVencimento;
  final DateTime? createdAt;

  // Campos adicionais de views
  final String? clienteNome;
  final String? clienteContacto;
  final String? vendaNumero;
  final DateTime? dataVenda;

  DividaModel({
    this.id,
    required this.clienteId,
    this.vendaId,
    required this.valorTotal,
    this.valorPago = 0,
    required this.valorRestante,
    this.status = 'PENDENTE',
    this.observacoes,
    required this.dataDivida,
    this.dataVencimento,
    this.createdAt,
    this.clienteNome,
    this.clienteContacto,
    this.vendaNumero,
    this.dataVenda,
  });

  factory DividaModel.fromMap(Map<String, dynamic> map) {
    return DividaModel(
      id: map['id'],
      clienteId: map['cliente_id'],
      vendaId: map['venda_id'],
      valorTotal: double.parse(map['valor_total'].toString()),
      valorPago: double.parse(map['valor_pago'].toString()),
      valorRestante: double.parse(map['valor_restante'].toString()),
      status: map['status'] ?? 'PENDENTE',
      observacoes: map['observacoes'],
      dataDivida: DateTime.parse(map['data_divida'].toString()),
      dataVencimento: map['data_vencimento'] != null
          ? DateTime.parse(map['data_vencimento'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      clienteNome: map['cliente_nome'],
      clienteContacto: map['cliente_contacto'],
      vendaNumero: map['venda_numero'],
      dataVenda: map['data_venda'] != null
          ? DateTime.parse(map['data_venda'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cliente_id': clienteId,
      'venda_id': vendaId,
      'valor_total': valorTotal,
      'valor_pago': valorPago,
      'valor_restante': valorRestante,
      'status': status,
      'observacoes': observacoes,
      'data_divida': dataDivida.toIso8601String(),
      'data_vencimento': dataVencimento?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Divida(id: $id, cliente: $clienteNome, total: $valorTotal, restante: $valorRestante)';
}
