class ProdutoComposicaoModel {
  final int? id;
  final int produtoId;
  final int produtoComponenteId;
  final double quantidade;
  final DateTime? createdAt;

  // Campos adicionais para joins
  final String? componenteCodigo;
  final String? componenteNome;
  final int? componenteEstoque;

  ProdutoComposicaoModel({
    this.id,
    required this.produtoId,
    required this.produtoComponenteId,
    required this.quantidade,
    this.createdAt,
    this.componenteCodigo,
    this.componenteNome,
    this.componenteEstoque,
  });

  factory ProdutoComposicaoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoComposicaoModel(
      id: map['id'],
      produtoId: map['produto_id'],
      produtoComponenteId: map['produto_componente_id'],
      quantidade: double.parse(map['quantidade'].toString()),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      componenteCodigo: map['componente_codigo'],
      componenteNome: map['componente_nome'],
      componenteEstoque: map['componente_estoque'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produto_id': produtoId,
      'produto_componente_id': produtoComponenteId,
      'quantidade': quantidade,
    };
  }

  @override
  String toString() =>
      'ProdutoComposicao(produto: $produtoId, componente: $componenteNome, qtd: $quantidade)';
}
