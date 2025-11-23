class PerfilPermissaoModel {
  final int? id;
  final int perfilId;
  final int permissaoId;
  final String? perfilNome;
  final String? permissaoCodigo;
  final String? permissaoNome;
  final String? permissaoCategoria;
  final DateTime? createdAt;

  PerfilPermissaoModel({
    this.id,
    required this.perfilId,
    required this.permissaoId,
    this.perfilNome,
    this.permissaoCodigo,
    this.permissaoNome,
    this.permissaoCategoria,
    this.createdAt,
  });

  factory PerfilPermissaoModel.fromMap(Map<String, dynamic> map) {
    return PerfilPermissaoModel(
      id: map['id'],
      perfilId: map['perfil_id'],
      permissaoId: map['permissao_id'],
      perfilNome: map['perfil_nome'],
      permissaoCodigo: map['permissao_codigo'],
      permissaoNome: map['permissao_nome'],
      permissaoCategoria: map['permissao_categoria'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'perfil_id': perfilId,
      'permissao_id': permissaoId,
    };
  }
}
