class ProdutoModel {
  final int? id;
  final String codigo;
  final String nome;
  final int familiaId;
  final double preco;
  final double precoCompra;
  final int estoque;
  final bool ativo;
  final bool contavel;
  final String iva;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos adicionais para setor e área
  final int? setorId;
  final int? areaId;

  // Campos adicionais para joins
  final String? familiaNome;
  final String? setorNome;
  final String? areaNome;
  final double? margemLucroPercentual;
  final bool? temComposicao;

  ProdutoModel({
    this.id,
    this.codigo = '',
    required this.nome,
    required this.familiaId,
    required this.preco,
    this.precoCompra = 0,
    this.estoque = 0,
    this.ativo = true,
    this.contavel = true,
    this.iva = 'Incluso',
    this.createdAt,
    this.updatedAt,
    this.setorId,
    this.areaId,
    this.familiaNome,
    this.setorNome,
    this.areaNome,
    this.margemLucroPercentual,
    this.temComposicao,
  });

  factory ProdutoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoModel(
      id: map['id'],
      codigo: map['codigo']?.toString() ?? '',
      nome: map['nome'],
      familiaId: map['familia_id'],
      preco: double.parse(map['preco'].toString()),
      precoCompra: map['preco_compra'] != null
          ? double.parse(map['preco_compra'].toString())
          : 0,
      estoque: map['estoque'] ?? 0,
      ativo: map['ativo'] ?? true,
      contavel: map['contavel'] ?? true,
      iva: map['iva'] ?? 'Incluso',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      setorId: map['setor_id'],
      areaId: map['area_id'],
      familiaNome: map['familia_nome'],
      setorNome: map['setor_nome'],
      areaNome: map['area_nome'],
      margemLucroPercentual: map['margem_lucro_percentual'] != null
          ? double.parse(map['margem_lucro_percentual'].toString())
          : null,
      temComposicao: map['tem_composicao'],
    );
  }

  Map<String, dynamic> toMap({bool incluirCodigo = false}) {
    final map = <String, dynamic>{
      'nome': nome,
      'familia_id': familiaId,
      'preco': preco,
      'preco_compra': precoCompra,
      'estoque': estoque,
      'ativo': ativo,
      'contavel': contavel,
      'iva': iva,
      'setor_id': setorId,
      'area_id': areaId,
    };

    // Só adiciona código se solicitado e não for vazio
    if (incluirCodigo && codigo.isNotEmpty) {
      map['codigo'] = codigo;
    }

    return map;
  }

  @override
  String toString() => 'Produto(id: $id, codigo: $codigo, nome: $nome, preco: $preco, setor: $setorNome, area: $areaNome)';
}
