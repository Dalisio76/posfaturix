class FaturaEntradaModel {
  final int? id;
  final int fornecedorId;
  final String numeroFatura;
  final DateTime dataFatura;
  final double total;
  final String? observacoes;
  final String? usuario;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos adicionais para joins
  final String? fornecedorNome;

  FaturaEntradaModel({
    this.id,
    required this.fornecedorId,
    required this.numeroFatura,
    required this.dataFatura,
    required this.total,
    this.observacoes,
    this.usuario,
    this.createdAt,
    this.updatedAt,
    this.fornecedorNome,
  });

  factory FaturaEntradaModel.fromMap(Map<String, dynamic> map) {
    return FaturaEntradaModel(
      id: map['id'],
      fornecedorId: map['fornecedor_id'],
      numeroFatura: map['numero_fatura'],
      dataFatura: DateTime.parse(map['data_fatura'].toString()),
      total: double.parse(map['total'].toString()),
      observacoes: map['observacoes'],
      usuario: map['usuario'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      fornecedorNome: map['fornecedor_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fornecedor_id': fornecedorId,
      'numero_fatura': numeroFatura,
      'data_fatura': dataFatura.toIso8601String(),
      'total': total,
      'observacoes': observacoes,
      'usuario': usuario,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ItemFaturaEntradaModel {
  final int? id;
  final int faturaId;
  final int produtoId;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  // Campos adicionais para joins
  final String? produtoCodigo;
  final String? produtoNome;

  ItemFaturaEntradaModel({
    this.id,
    required this.faturaId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.produtoCodigo,
    this.produtoNome,
  });

  factory ItemFaturaEntradaModel.fromMap(Map<String, dynamic> map) {
    return ItemFaturaEntradaModel(
      id: map['id'],
      faturaId: map['fatura_id'],
      produtoId: map['produto_id'],
      quantidade: map['quantidade'],
      precoUnitario: double.parse(map['preco_unitario'].toString()),
      subtotal: double.parse(map['subtotal'].toString()),
      produtoCodigo: map['produto_codigo'],
      produtoNome: map['produto_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fatura_id': faturaId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'subtotal': subtotal,
    };
  }
}
