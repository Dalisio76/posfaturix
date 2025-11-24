class PedidoModel {
  final int? id;
  final String numero;
  final int mesaId;
  final int usuarioId;
  final String status; // aberto, fechado, cancelado
  final double total;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String? observacoes;

  // Campos adicionais da view
  final int? mesaNumero;
  final String? localNome;
  final String? usuarioNome;
  final int? totalItens;

  PedidoModel({
    this.id,
    required this.numero,
    required this.mesaId,
    required this.usuarioId,
    this.status = 'aberto',
    this.total = 0,
    DateTime? dataAbertura,
    this.dataFechamento,
    this.observacoes,
    this.mesaNumero,
    this.localNome,
    this.usuarioNome,
    this.totalItens,
  }) : dataAbertura = dataAbertura ?? DateTime.now();

  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      id: map['id'],
      numero: map['numero'],
      mesaId: map['mesa_id'],
      usuarioId: map['usuario_id'],
      status: map['status'] ?? 'aberto',
      total: map['total'] != null
          ? double.parse(map['total'].toString())
          : 0,
      dataAbertura: map['data_abertura'] != null
          ? DateTime.parse(map['data_abertura'].toString())
          : DateTime.now(),
      dataFechamento: map['data_fechamento'] != null
          ? DateTime.parse(map['data_fechamento'].toString())
          : null,
      observacoes: map['observacoes'],
      mesaNumero: map['mesa_numero'],
      localNome: map['local_nome'],
      usuarioNome: map['usuario_nome'],
      totalItens: map['total_itens'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'mesa_id': mesaId,
      'usuario_id': usuarioId,
      'status': status,
      'total': total,
      'data_abertura': dataAbertura.toIso8601String(),
      'data_fechamento': dataFechamento?.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  bool get isAberto => status == 'aberto';
  bool get isFechado => status == 'fechado';
  bool get isCancelado => status == 'cancelado';

  @override
  String toString() =>
      'Pedido(numero: $numero, mesa: $mesaNumero, status: $status, total: $total)';
}
