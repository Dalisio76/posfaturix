class MesaModel {
  final int? id;
  final int numero;
  final int localId;
  final int capacidade;
  final bool ativo;
  final DateTime? createdAt;

  // Campos adicionais da view v_mesas_completo
  final String? localNome;
  final int? pedidoId;
  final String? pedidoNumero;
  final int? usuarioId;
  final String? usuarioNome;
  final double? pedidoTotal;
  final DateTime? dataAbertura;
  final String? status; // livre, ocupada, inativa

  MesaModel({
    this.id,
    required this.numero,
    required this.localId,
    this.capacidade = 4,
    this.ativo = true,
    this.createdAt,
    this.localNome,
    this.pedidoId,
    this.pedidoNumero,
    this.usuarioId,
    this.usuarioNome,
    this.pedidoTotal,
    this.dataAbertura,
    this.status,
  });

  factory MesaModel.fromMap(Map<String, dynamic> map) {
    return MesaModel(
      id: map['id'],
      numero: map['numero'],
      localId: map['local_id'],
      capacidade: map['capacidade'] ?? 4,
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      localNome: map['local_nome'],
      pedidoId: map['pedido_id'],
      pedidoNumero: map['pedido_numero'],
      usuarioId: map['usuario_id'],
      usuarioNome: map['usuario_nome'],
      pedidoTotal: map['pedido_total'] != null
          ? double.parse(map['pedido_total'].toString())
          : null,
      dataAbertura: map['data_abertura'] != null
          ? DateTime.parse(map['data_abertura'].toString())
          : null,
      status: map['status'] ?? 'livre',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'local_id': localId,
      'capacidade': capacidade,
      'ativo': ativo,
    };
  }

  bool get isLivre => status == 'livre';
  bool get isOcupada => status == 'ocupada';
  bool get isInativa => status == 'inativa';

  @override
  String toString() =>
      'Mesa(numero: $numero, local: $localNome, status: $status)';
}
