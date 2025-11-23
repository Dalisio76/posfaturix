class AcertoStockModel {
  final int? id;
  final int produtoId;
  final int estoqueAnterior;
  final int estoqueNovo;
  final int diferenca;
  final String motivo;
  final String? observacao;
  final int? setorId;
  final int? areaId;
  final String? usuario;
  final DateTime data;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos adicionais para joins
  final String? produtoCodigo;
  final String? produtoNome;
  final double? produtoPreco;
  final String? setorNome;
  final String? areaNome;
  final String? familiaNome;
  final double? valorDiferenca;

  AcertoStockModel({
    this.id,
    required this.produtoId,
    required this.estoqueAnterior,
    required this.estoqueNovo,
    required this.diferenca,
    required this.motivo,
    this.observacao,
    this.setorId,
    this.areaId,
    this.usuario,
    required this.data,
    this.createdAt,
    this.updatedAt,
    this.produtoCodigo,
    this.produtoNome,
    this.produtoPreco,
    this.setorNome,
    this.areaNome,
    this.familiaNome,
    this.valorDiferenca,
  });

  factory AcertoStockModel.fromMap(Map<String, dynamic> map) {
    return AcertoStockModel(
      id: map['id'],
      produtoId: map['produto_id'],
      estoqueAnterior: map['estoque_anterior'] ?? 0,
      estoqueNovo: map['estoque_novo'] ?? 0,
      diferenca: map['diferenca'] ?? 0,
      motivo: map['motivo'] ?? '',
      observacao: map['observacao'],
      setorId: map['setor_id'],
      areaId: map['area_id'],
      usuario: map['usuario'],
      data: map['data'] != null
          ? DateTime.parse(map['data'].toString())
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      produtoCodigo: map['produto_codigo'],
      produtoNome: map['produto_nome'],
      produtoPreco: map['produto_preco'] != null
          ? double.parse(map['produto_preco'].toString())
          : null,
      setorNome: map['setor_nome'],
      areaNome: map['area_nome'],
      familiaNome: map['familia_nome'],
      valorDiferenca: map['valor_diferenca'] != null
          ? double.parse(map['valor_diferenca'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto_id': produtoId,
      'estoque_anterior': estoqueAnterior,
      'estoque_novo': estoqueNovo,
      'diferenca': diferenca,
      'motivo': motivo,
      'observacao': observacao,
      'setor_id': setorId,
      'area_id': areaId,
      'usuario': usuario,
      'data': data.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AcertoStockModel copyWith({
    int? id,
    int? produtoId,
    int? estoqueAnterior,
    int? estoqueNovo,
    int? diferenca,
    String? motivo,
    String? observacao,
    int? setorId,
    int? areaId,
    String? usuario,
    DateTime? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? produtoCodigo,
    String? produtoNome,
    double? produtoPreco,
    String? setorNome,
    String? areaNome,
    String? familiaNome,
    double? valorDiferenca,
  }) {
    return AcertoStockModel(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      estoqueAnterior: estoqueAnterior ?? this.estoqueAnterior,
      estoqueNovo: estoqueNovo ?? this.estoqueNovo,
      diferenca: diferenca ?? this.diferenca,
      motivo: motivo ?? this.motivo,
      observacao: observacao ?? this.observacao,
      setorId: setorId ?? this.setorId,
      areaId: areaId ?? this.areaId,
      usuario: usuario ?? this.usuario,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      produtoCodigo: produtoCodigo ?? this.produtoCodigo,
      produtoNome: produtoNome ?? this.produtoNome,
      produtoPreco: produtoPreco ?? this.produtoPreco,
      setorNome: setorNome ?? this.setorNome,
      areaNome: areaNome ?? this.areaNome,
      familiaNome: familiaNome ?? this.familiaNome,
      valorDiferenca: valorDiferenca ?? this.valorDiferenca,
    );
  }
}
