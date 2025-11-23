class UsuarioModel {
  final int? id;
  final String nome;
  final int perfilId;
  final String? perfilNome;
  final String codigo;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UsuarioModel({
    this.id,
    required this.nome,
    required this.perfilId,
    this.perfilNome,
    required this.codigo,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'],
      nome: map['nome'],
      perfilId: map['perfil_id'],
      perfilNome: map['perfil_nome'],
      codigo: map['codigo'],
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
      'perfil_id': perfilId,
      'codigo': codigo,
      'ativo': ativo,
    };
  }

  UsuarioModel copyWith({
    int? id,
    String? nome,
    int? perfilId,
    String? perfilNome,
    String? codigo,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      perfilId: perfilId ?? this.perfilId,
      perfilNome: perfilNome ?? this.perfilNome,
      codigo: codigo ?? this.codigo,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
