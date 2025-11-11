class EmpresaModel {
  final int? id;
  final String nome;
  final String? nuit;
  final String? endereco;
  final String? cidade;
  final String? email;
  final String? contacto;
  final String? logoUrl;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmpresaModel({
    this.id,
    required this.nome,
    this.nuit,
    this.endereco,
    this.cidade,
    this.email,
    this.contacto,
    this.logoUrl,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EmpresaModel.fromMap(Map<String, dynamic> map) {
    return EmpresaModel(
      id: map['id'],
      nome: map['nome'],
      nuit: map['nuit'],
      endereco: map['endereco'],
      cidade: map['cidade'],
      email: map['email'],
      contacto: map['contacto'],
      logoUrl: map['logo_url'],
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
      'nome': nome,
      'nuit': nuit,
      'endereco': endereco,
      'cidade': cidade,
      'email': email,
      'contacto': contacto,
      'logo_url': logoUrl,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Empresa(id: $id, nome: $nome, nuit: $nuit)';
}
