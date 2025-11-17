/// Modelo de Definições/Configurações do sistema
class DefinicaoModel {
  // Impressão
  final bool perguntarAntesDeImprimir;

  // Outras configurações futuras podem ser adicionadas aqui
  final String? impressoraPadrao;
  final bool imprimirAutomaticamente;

  DefinicaoModel({
    this.perguntarAntesDeImprimir = true, // Por padrão, pergunta
    this.impressoraPadrao,
    this.imprimirAutomaticamente = false,
  });

  factory DefinicaoModel.fromJson(Map<String, dynamic> json) {
    return DefinicaoModel(
      perguntarAntesDeImprimir: json['perguntarAntesDeImprimir'] ?? true,
      impressoraPadrao: json['impressoraPadrao'],
      imprimirAutomaticamente: json['imprimirAutomaticamente'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perguntarAntesDeImprimir': perguntarAntesDeImprimir,
      'impressoraPadrao': impressoraPadrao,
      'imprimirAutomaticamente': imprimirAutomaticamente,
    };
  }

  DefinicaoModel copyWith({
    bool? perguntarAntesDeImprimir,
    String? impressoraPadrao,
    bool? imprimirAutomaticamente,
  }) {
    return DefinicaoModel(
      perguntarAntesDeImprimir: perguntarAntesDeImprimir ?? this.perguntarAntesDeImprimir,
      impressoraPadrao: impressoraPadrao ?? this.impressoraPadrao,
      imprimirAutomaticamente: imprimirAutomaticamente ?? this.imprimirAutomaticamente,
    );
  }
}
