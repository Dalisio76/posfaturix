class ImpressoraModel {
  final int? id;
  final String nome;
  final String tipo;
  final String? descricao;
  final int larguraPapel;
  final bool ativo;
  final String? caminhoRede;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ImpressoraModel({
    this.id,
    required this.nome,
    this.tipo = 'termica',
    this.descricao,
    this.larguraPapel = 80,
    this.ativo = true,
    this.caminhoRede,
    this.createdAt,
    this.updatedAt,
  });

  factory ImpressoraModel.fromMap(Map<String, dynamic> map) {
    return ImpressoraModel(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      tipo: map['tipo'] as String? ?? 'termica',
      descricao: map['descricao'] as String?,
      larguraPapel: map['largura_papel'] as int? ?? 80,
      ativo: map['ativo'] as bool? ?? true,
      caminhoRede: map['caminho_rede'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'descricao': descricao,
      'largura_papel': larguraPapel,
      'ativo': ativo,
      'caminho_rede': caminhoRede,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ImpressoraModel copyWith({
    int? id,
    String? nome,
    String? tipo,
    String? descricao,
    int? larguraPapel,
    bool? ativo,
    String? caminhoRede,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImpressoraModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      larguraPapel: larguraPapel ?? this.larguraPapel,
      ativo: ativo ?? this.ativo,
      caminhoRede: caminhoRede ?? this.caminhoRede,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ImpressoraModel(id: $id, nome: $nome, tipo: $tipo, largura: ${larguraPapel}mm)';
  }
}

// Modelo para tipos de documento
class TipoDocumentoModel {
  final int? id;
  final String codigo;
  final String nome;
  final String? descricao;
  final bool ativo;

  TipoDocumentoModel({
    this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    this.ativo = true,
  });

  factory TipoDocumentoModel.fromMap(Map<String, dynamic> map) {
    return TipoDocumentoModel(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      ativo: map['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }
}

// Modelo para mapeamento documento-impressora
class DocumentoImpressoraModel {
  final int? id;
  final int tipoDocumentoId;
  final int impressoraId;
  final int prioridade;

  // Campos extras da view
  final String? documentoCodigo;
  final String? documentoNome;
  final String? impressoraNome;
  final String? impressoraTipo;

  DocumentoImpressoraModel({
    this.id,
    required this.tipoDocumentoId,
    required this.impressoraId,
    this.prioridade = 1,
    this.documentoCodigo,
    this.documentoNome,
    this.impressoraNome,
    this.impressoraTipo,
  });

  factory DocumentoImpressoraModel.fromMap(Map<String, dynamic> map) {
    return DocumentoImpressoraModel(
      id: map['id'] as int?,
      tipoDocumentoId: map['tipo_documento_id'] as int,
      impressoraId: map['impressora_id'] as int,
      prioridade: map['prioridade'] as int? ?? 1,
      documentoCodigo: map['documento_codigo'] as String?,
      documentoNome: map['documento_nome'] as String?,
      impressoraNome: map['impressora_nome'] as String?,
      impressoraTipo: map['impressora_tipo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo_documento_id': tipoDocumentoId,
      'impressora_id': impressoraId,
      'prioridade': prioridade,
    };
  }
}
