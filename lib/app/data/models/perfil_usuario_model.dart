class PerfilUsuarioModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PerfilUsuarioModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PerfilUsuarioModel.fromMap(Map<String, dynamic> map) {
    return PerfilUsuarioModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
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
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  PerfilUsuarioModel copyWith({
    int? id,
    String? nome,
    String? descricao,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PerfilUsuarioModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
