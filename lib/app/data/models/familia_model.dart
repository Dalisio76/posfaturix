class FamiliaModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;

  FamiliaModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
  });

  factory FamiliaModel.fromMap(Map<String, dynamic> map) {
    return FamiliaModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
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

  @override
  String toString() => 'Familia(id: $id, nome: $nome)';
}
