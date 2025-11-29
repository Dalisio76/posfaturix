/// Modelo de Definições/Configurações do sistema
class DefinicaoModel {
  // Impressão
  final bool perguntarAntesDeImprimir;
  final String? impressoraPadrao;
  final bool imprimirAutomaticamente;

  // Segurança
  final bool timeoutAtivo;
  final int timeoutSegundos;

  // Vendas
  final bool mostrarBotaoPedidos;

  DefinicaoModel({
    this.perguntarAntesDeImprimir = true,
    this.impressoraPadrao,
    this.imprimirAutomaticamente = false,
    this.timeoutAtivo = true,
    this.timeoutSegundos = 30,
    this.mostrarBotaoPedidos = true,
  });

  factory DefinicaoModel.fromJson(Map<String, dynamic> json) {
    return DefinicaoModel(
      perguntarAntesDeImprimir: json['perguntarAntesDeImprimir'] ?? true,
      impressoraPadrao: json['impressoraPadrao'],
      imprimirAutomaticamente: json['imprimirAutomaticamente'] ?? false,
      timeoutAtivo: json['timeoutAtivo'] ?? true,
      timeoutSegundos: json['timeoutSegundos'] ?? 30,
      mostrarBotaoPedidos: json['mostrarBotaoPedidos'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perguntarAntesDeImprimir': perguntarAntesDeImprimir,
      'impressoraPadrao': impressoraPadrao,
      'imprimirAutomaticamente': imprimirAutomaticamente,
      'timeoutAtivo': timeoutAtivo,
      'timeoutSegundos': timeoutSegundos,
      'mostrarBotaoPedidos': mostrarBotaoPedidos,
    };
  }

  DefinicaoModel copyWith({
    bool? perguntarAntesDeImprimir,
    String? impressoraPadrao,
    bool? imprimirAutomaticamente,
    bool? timeoutAtivo,
    int? timeoutSegundos,
    bool? mostrarBotaoPedidos,
  }) {
    return DefinicaoModel(
      perguntarAntesDeImprimir: perguntarAntesDeImprimir ?? this.perguntarAntesDeImprimir,
      impressoraPadrao: impressoraPadrao ?? this.impressoraPadrao,
      imprimirAutomaticamente: imprimirAutomaticamente ?? this.imprimirAutomaticamente,
      timeoutAtivo: timeoutAtivo ?? this.timeoutAtivo,
      timeoutSegundos: timeoutSegundos ?? this.timeoutSegundos,
      mostrarBotaoPedidos: mostrarBotaoPedidos ?? this.mostrarBotaoPedidos,
    );
  }
}
