class ProdutoModel {
  final int? id;
  final String codigo;
  final String nome;
  final int familiaId;
  final double preco;
  final int estoque;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campo adicional para joins
  final String? familiaNome;

  ProdutoModel({
    this.id,
    required this.codigo,
    required this.nome,
    required this.familiaId,
    required this.preco,
    this.estoque = 0,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
    this.familiaNome,
  });

  factory ProdutoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoModel(
      id: map['id'],
      codigo: map['codigo'],
      nome: map['nome'],
      familiaId: map['familia_id'],
      preco: double.parse(map['preco'].toString()),
      estoque: map['estoque'] ?? 0,
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      familiaNome: map['familia_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'familia_id': familiaId,
      'preco': preco,
      'estoque': estoque,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Produto(id: $id, codigo: $codigo, nome: $nome, preco: $preco)';
}
