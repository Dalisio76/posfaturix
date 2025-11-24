class LocalMesaModel {
  final int? id;
  final String nome;
  final String? descricao;
  final int ordem;
  final bool ativo;
  final DateTime? createdAt;

  LocalMesaModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ordem = 0,
    this.ativo = true,
    this.createdAt,
  });

  factory LocalMesaModel.fromMap(Map<String, dynamic> map) {
    return LocalMesaModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ordem: map['ordem'] ?? 0,
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
      'ordem': ordem,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'LocalMesa(id: $id, nome: $nome)';
}
