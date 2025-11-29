class AreaModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int? impressoraId;
  final String? impressoraNome;
  final DateTime? createdAt;

  AreaModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.impressoraId,
    this.impressoraNome,
    this.createdAt,
  });

  factory AreaModel.fromMap(Map<String, dynamic> map) {
    return AreaModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      impressoraId: map['impressora_id'],
      impressoraNome: map['impressora_nome'],
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
      'impressora_id': impressoraId,
    };
  }

  AreaModel copyWith({
    int? id,
    String? nome,
    String? descricao,
    bool? ativo,
    int? impressoraId,
    String? impressoraNome,
    DateTime? createdAt,
  }) {
    return AreaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      impressoraId: impressoraId ?? this.impressoraId,
      impressoraNome: impressoraNome ?? this.impressoraNome,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Area(id: $id, nome: $nome, impressora: $impressoraNome)';
}
