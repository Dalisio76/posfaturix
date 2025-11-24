class ItemPedidoModel {
  final int? id;
  final int pedidoId;
  final int produtoId;
  final String produtoNome;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;
  final String? observacoes;
  final DateTime? createdAt;

  ItemPedidoModel({
    this.id,
    required this.pedidoId,
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.observacoes,
    this.createdAt,
  });

  factory ItemPedidoModel.fromMap(Map<String, dynamic> map) {
    return ItemPedidoModel(
      id: map['id'],
      pedidoId: map['pedido_id'],
      produtoId: map['produto_id'],
      produtoNome: map['produto_nome'],
      quantidade: map['quantidade'],
      precoUnitario: double.parse(map['preco_unitario'].toString()),
      subtotal: double.parse(map['subtotal'].toString()),
      observacoes: map['observacoes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pedido_id': pedidoId,
      'produto_id': produtoId,
      'produto_nome': produtoNome,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'subtotal': subtotal,
      'observacoes': observacoes,
    };
  }

  @override
  String toString() =>
      'ItemPedido(produto: $produtoNome, qtd: $quantidade, subtotal: $subtotal)';
}
