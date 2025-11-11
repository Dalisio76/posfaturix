class ClienteModel {
  final int? id;
  final String nome;
  final String? contacto;
  final String? contacto2;
  final String? email;
  final String? endereco;
  final String? bairro;
  final String? cidade;
  final String? nuit;
  final String? observacoes;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos adicionais de views
  final int? totalDividas;
  final double? totalDevendo;
  final DateTime? ultimaDivida;

  ClienteModel({
    this.id,
    required this.nome,
    this.contacto,
    this.contacto2,
    this.email,
    this.endereco,
    this.bairro,
    this.cidade,
    this.nuit,
    this.observacoes,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
    this.totalDividas,
    this.totalDevendo,
    this.ultimaDivida,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'],
      nome: map['nome'],
      contacto: map['contacto'],
      contacto2: map['contacto2'],
      email: map['email'],
      endereco: map['endereco'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      nuit: map['nuit'],
      observacoes: map['observacoes'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      totalDividas: map['total_dividas'],
      totalDevendo: map['total_devendo'] != null
          ? double.parse(map['total_devendo'].toString())
          : null,
      ultimaDivida: map['ultima_divida'] != null
          ? DateTime.parse(map['ultima_divida'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'contacto': contacto,
      'contacto2': contacto2,
      'email': email,
      'endereco': endereco,
      'bairro': bairro,
      'cidade': cidade,
      'nuit': nuit,
      'observacoes': observacoes,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Cliente(id: $id, nome: $nome, contacto: $contacto)';
}
