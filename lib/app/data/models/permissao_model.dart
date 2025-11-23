class PermissaoModel {
  final int? id;
  final String codigo;
  final String nome;
  final String? descricao;
  final String? categoria;
  final bool ativo;
  final DateTime? createdAt;

  PermissaoModel({
    this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    this.categoria,
    this.ativo = true,
    this.createdAt,
  });

  factory PermissaoModel.fromMap(Map<String, dynamic> map) {
    return PermissaoModel(
      id: map['id'],
      codigo: map['codigo'],
      nome: map['nome'],
      descricao: map['descricao'],
      categoria: map['categoria'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'ativo': ativo,
    };
  }

  PermissaoModel copyWith({
    int? id,
    String? codigo,
    String? nome,
    String? descricao,
    String? categoria,
    bool? ativo,
    DateTime? createdAt,
  }) {
    return PermissaoModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
