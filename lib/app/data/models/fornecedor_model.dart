class FornecedorModel {
  final int? id;
  final String nome;
  final String? nif;
  final String? email;
  final String? telefone;
  final String? morada;
  final String? cidade;
  final String? codigoPostal;
  final String? pais;
  final String? contacto;
  final String? observacoes;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FornecedorModel({
    this.id,
    required this.nome,
    this.nif,
    this.email,
    this.telefone,
    this.morada,
    this.cidade,
    this.codigoPostal,
    this.pais = 'Portugal',
    this.contacto,
    this.observacoes,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FornecedorModel.fromMap(Map<String, dynamic> map) {
    return FornecedorModel(
      id: map['id'],
      nome: map['nome'],
      nif: map['nif'],
      email: map['email'],
      telefone: map['telefone'],
      morada: map['morada'],
      cidade: map['cidade'],
      codigoPostal: map['codigo_postal'],
      pais: map['pais'] ?? 'Portugal',
      contacto: map['contacto'],
      observacoes: map['observacoes'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'nif': nif,
      'email': email,
      'telefone': telefone,
      'morada': morada,
      'cidade': cidade,
      'codigo_postal': codigoPostal,
      'pais': pais,
      'contacto': contacto,
      'observacoes': observacoes,
      'ativo': ativo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  FornecedorModel copyWith({
    int? id,
    String? nome,
    String? nif,
    String? email,
    String? telefone,
    String? morada,
    String? cidade,
    String? codigoPostal,
    String? pais,
    String? contacto,
    String? observacoes,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FornecedorModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      nif: nif ?? this.nif,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      morada: morada ?? this.morada,
      cidade: cidade ?? this.cidade,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      pais: pais ?? this.pais,
      contacto: contacto ?? this.contacto,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
