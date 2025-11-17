/// Modelo para conferência manual de valores do caixa
class ConferenciaModel {
  final int? id;
  final int caixaId;

  // Valores do Sistema
  final double sistemaCash;
  final double sistemaEmola;
  final double sistemaMpesa;
  final double sistemaPos;
  final double sistemaTotal;

  // Valores Contados Manualmente
  final double contadoCash;
  final double contadoEmola;
  final double contadoMpesa;
  final double contadoPos;
  final double contadoTotal;

  // Diferenças
  final double diferencaCash;
  final double diferencaEmola;
  final double diferencaMpesa;
  final double diferencaPos;
  final double diferencaTotal;

  // Status
  final bool conferenciaOk;
  final String? observacoes;
  final DateTime? createdAt;

  ConferenciaModel({
    this.id,
    required this.caixaId,
    this.sistemaCash = 0,
    this.sistemaEmola = 0,
    this.sistemaMpesa = 0,
    this.sistemaPos = 0,
    this.sistemaTotal = 0,
    this.contadoCash = 0,
    this.contadoEmola = 0,
    this.contadoMpesa = 0,
    this.contadoPos = 0,
    this.contadoTotal = 0,
    this.diferencaCash = 0,
    this.diferencaEmola = 0,
    this.diferencaMpesa = 0,
    this.diferencaPos = 0,
    this.diferencaTotal = 0,
    this.conferenciaOk = false,
    this.observacoes,
    this.createdAt,
  });

  factory ConferenciaModel.fromMap(Map<String, dynamic> map) {
    return ConferenciaModel(
      id: map['id'],
      caixaId: map['caixa_id'],
      sistemaCash: double.tryParse(map['sistema_cash']?.toString() ?? '0') ?? 0.0,
      sistemaEmola: double.tryParse(map['sistema_emola']?.toString() ?? '0') ?? 0.0,
      sistemaMpesa: double.tryParse(map['sistema_mpesa']?.toString() ?? '0') ?? 0.0,
      sistemaPos: double.tryParse(map['sistema_pos']?.toString() ?? '0') ?? 0.0,
      sistemaTotal: double.tryParse(map['sistema_total']?.toString() ?? '0') ?? 0.0,
      contadoCash: double.tryParse(map['contado_cash']?.toString() ?? '0') ?? 0.0,
      contadoEmola: double.tryParse(map['contado_emola']?.toString() ?? '0') ?? 0.0,
      contadoMpesa: double.tryParse(map['contado_mpesa']?.toString() ?? '0') ?? 0.0,
      contadoPos: double.tryParse(map['contado_pos']?.toString() ?? '0') ?? 0.0,
      contadoTotal: double.tryParse(map['contado_total']?.toString() ?? '0') ?? 0.0,
      diferencaCash: double.tryParse(map['diferenca_cash']?.toString() ?? '0') ?? 0.0,
      diferencaEmola: double.tryParse(map['diferenca_emola']?.toString() ?? '0') ?? 0.0,
      diferencaMpesa: double.tryParse(map['diferenca_mpesa']?.toString() ?? '0') ?? 0.0,
      diferencaPos: double.tryParse(map['diferenca_pos']?.toString() ?? '0') ?? 0.0,
      diferencaTotal: double.tryParse(map['diferenca_total']?.toString() ?? '0') ?? 0.0,
      conferenciaOk: map['conferencia_ok'] ?? false,
      observacoes: map['observacoes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caixa_id': caixaId,
      'sistema_cash': sistemaCash,
      'sistema_emola': sistemaEmola,
      'sistema_mpesa': sistemaMpesa,
      'sistema_pos': sistemaPos,
      'sistema_total': sistemaTotal,
      'contado_cash': contadoCash,
      'contado_emola': contadoEmola,
      'contado_mpesa': contadoMpesa,
      'contado_pos': contadoPos,
      'contado_total': contadoTotal,
      'diferenca_cash': diferencaCash,
      'diferenca_emola': diferencaEmola,
      'diferenca_mpesa': diferencaMpesa,
      'diferenca_pos': diferencaPos,
      'diferenca_total': diferencaTotal,
      'conferencia_ok': conferenciaOk,
      'observacoes': observacoes,
    };
  }

  /// Verifica se alguma forma de pagamento tem diferença
  bool get temDiferenca => diferencaTotal != 0;

  /// Retorna lista de formas com diferença
  List<String> get formasComDiferenca {
    List<String> formas = [];
    if (diferencaCash != 0) formas.add('CASH');
    if (diferencaEmola != 0) formas.add('E-MOLA');
    if (diferencaMpesa != 0) formas.add('M-PESA');
    if (diferencaPos != 0) formas.add('POS');
    return formas;
  }
}
