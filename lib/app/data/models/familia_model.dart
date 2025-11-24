class FamiliaModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;

  // Campos adicionais para relacionamento com setores
  final List<int>? setorIds;
  final List<String>? setorNomes;
  final String? setoresTexto;

  // Campos adicionais para relacionamento com áreas
  final List<int>? areaIds;
  final List<String>? areaNomes;
  final String? areasTexto;

  FamiliaModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
    this.setorIds,
    this.setorNomes,
    this.setoresTexto,
    this.areaIds,
    this.areaNomes,
    this.areasTexto,
  });

  factory FamiliaModel.fromMap(Map<String, dynamic> map) {
    // Processar array de IDs de setores
    List<int>? setorIds;
    if (map['setor_ids'] != null) {
      if (map['setor_ids'] is List) {
        setorIds = (map['setor_ids'] as List).map((e) => e as int).toList();
      } else if (map['setor_ids'] is String) {
        // PostgreSQL pode retornar array como string: "{1,2,3}"
        final arrayStr = (map['setor_ids'] as String)
            .replaceAll('{', '')
            .replaceAll('}', '');
        if (arrayStr.isNotEmpty) {
          setorIds = arrayStr.split(',').map((e) => int.parse(e.trim())).toList();
        }
      }
    }

    // Processar array de nomes de setores
    List<String>? setorNomes;
    if (map['setor_nomes'] != null) {
      if (map['setor_nomes'] is List) {
        setorNomes = (map['setor_nomes'] as List).map((e) => e.toString()).toList();
      } else if (map['setor_nomes'] is String) {
        // PostgreSQL pode retornar array como string: "{RESTAURANTE,ARMAZEM}"
        final arrayStr = (map['setor_nomes'] as String)
            .replaceAll('{', '')
            .replaceAll('}', '');
        if (arrayStr.isNotEmpty) {
          setorNomes = arrayStr.split(',').map((e) => e.trim()).toList();
        }
      }
    }

    // Processar array de IDs de áreas
    List<int>? areaIds;
    if (map['area_ids'] != null) {
      if (map['area_ids'] is List) {
        areaIds = (map['area_ids'] as List).map((e) => e as int).toList();
      } else if (map['area_ids'] is String) {
        // PostgreSQL pode retornar array como string: "{1,2,3}"
        final arrayStr = (map['area_ids'] as String)
            .replaceAll('{', '')
            .replaceAll('}', '');
        if (arrayStr.isNotEmpty) {
          areaIds = arrayStr.split(',').map((e) => int.parse(e.trim())).toList();
        }
      }
    }

    // Processar array de nomes de áreas
    List<String>? areaNomes;
    if (map['area_nomes'] != null) {
      if (map['area_nomes'] is List) {
        areaNomes = (map['area_nomes'] as List).map((e) => e.toString()).toList();
      } else if (map['area_nomes'] is String) {
        // PostgreSQL pode retornar array como string: "{BAR,COZINHA}"
        final arrayStr = (map['area_nomes'] as String)
            .replaceAll('{', '')
            .replaceAll('}', '');
        if (arrayStr.isNotEmpty) {
          areaNomes = arrayStr.split(',').map((e) => e.trim()).toList();
        }
      }
    }

    return FamiliaModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      setorIds: setorIds,
      setorNomes: setorNomes,
      setoresTexto: map['setores_texto'],
      areaIds: areaIds,
      areaNomes: areaNomes,
      areasTexto: map['areas_texto'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Familia(id: $id, nome: $nome, setores: $setoresTexto)';
}
