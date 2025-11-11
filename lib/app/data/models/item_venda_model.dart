class ItemVendaModel {
  final int? id;
  final int? vendaId;
  final int produtoId;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  // Campo adicional
  final String? produtoNome;

  ItemVendaModel({
    this.id,
    this.vendaId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.produtoNome,
  });

  factory ItemVendaModel.fromMap(Map<String, dynamic> map) {
    return ItemVendaModel(
      id: map['id'],
      vendaId: map['venda_id'],
      produtoId: map['produto_id'],
      quantidade: map['quantidade'],
      precoUnitario: double.parse(map['preco_unitario'].toString()),
      subtotal: double.parse(map['subtotal'].toString()),
      produtoNome: map['produto_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venda_id': vendaId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'subtotal': subtotal,
    };
  }
}
