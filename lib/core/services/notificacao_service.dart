import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../app/data/repositories/empresa_repository.dart';

/// Serviço de notificações por email/WhatsApp (opcional - requer internet)
/// Sistema funciona 100% offline, notificações são extras quando há internet
class NotificacaoService extends GetxService {
  // URL da sua API de notificações (opcional)
  static const String apiUrl = 'https://seudominio.com/api/notificacoes';
  static const String apiKey = 'SUA_CHAVE_API_AQUI';

  final EmpresaRepository _empresaRepo = EmpresaRepository();

  // Configurações (email vem dos dados da empresa)
  String? telefoneCliente;
  bool notificacoesAtivas = false;

  /// Obter email da empresa
  Future<String?> _obterEmailEmpresa() async {
    try {
      final empresa = await _empresaRepo.buscarDados();
      return empresa?.email;
    } catch (e) {
      print('⚠️ Erro ao buscar email da empresa: $e');
      return null;
    }
  }

  /// Verificar se tem internet
  Future<bool> temInternet() async {
    try {
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(Duration(seconds: 3));
      return result.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Enviar notificação de fecho de caixa
  Future<void> notificarFechoCaixa({
    required String numeroCaixa,
    required double saldoFinal,
    required double totalEntradas,
    required double totalSaidas,
    required DateTime dataAbertura,
    required DateTime dataFechamento,
  }) async {
    // Funciona offline - apenas tenta enviar se tiver internet
    if (!notificacoesAtivas) return;
    if (!await temInternet()) {
      print('⚠️ Sem internet - notificação não enviada (sistema continua funcionando)');
      return;
    }

    try {
      final mensagem = '''
🔴 CAIXA FECHADO

Caixa: $numeroCaixa
Abertura: ${_formatarDataHora(dataAbertura)}
Fechamento: ${_formatarDataHora(dataFechamento)}

💰 RESUMO:
Entradas: ${_formatarMoeda(totalEntradas)}
Saídas: ${_formatarMoeda(totalSaidas)}
Saldo Final: ${_formatarMoeda(saldoFinal)}
''';

      // Enviar para sua API
      await _enviarParaAPI(
        tipo: 'fecho_caixa',
        assunto: 'Fecho de Caixa - $numeroCaixa',
        mensagem: mensagem,
      );

      print('✅ Notificação de fecho enviada');
    } catch (e) {
      print('⚠️ Erro ao enviar notificação (não afeta funcionamento): $e');
    }
  }

  /// Enviar notificação de margens de lucro
  Future<void> notificarMargens({
    required double margemDia,
    required double margemMes,
    required double lucroTotal,
    required DateTime periodo,
  }) async {
    if (!notificacoesAtivas) return;
    if (!await temInternet()) return;

    try {
      final mensagem = '''
📊 RELATÓRIO DE MARGENS

Período: ${_formatarData(periodo)}

Margem do Dia: ${margemDia.toStringAsFixed(2)}%
Margem do Mês: ${margemMes.toStringAsFixed(2)}%
Lucro Total: ${_formatarMoeda(lucroTotal)}
''';

      await _enviarParaAPI(
        tipo: 'margens',
        assunto: 'Relatório de Margens - ${_formatarData(periodo)}',
        mensagem: mensagem,
      );

      print('✅ Notificação de margens enviada');
    } catch (e) {
      print('⚠️ Erro ao enviar notificação: $e');
    }
  }

  /// Enviar notificação de stock baixo
  Future<void> notificarStockBaixo({
    required List<Map<String, dynamic>> produtosBaixos,
  }) async {
    if (!notificacoesAtivas) return;
    if (!await temInternet()) return;
    if (produtosBaixos.isEmpty) return;

    try {
      String listaProdutos = '';
      for (var produto in produtosBaixos.take(10)) {
        // Primeiros 10
        listaProdutos +=
            '• ${produto['nome']}: ${produto['estoque']} unidades\n';
      }

      final mensagem = '''
⚠️ ALERTA DE STOCK BAIXO

${produtosBaixos.length} produto(s) com stock abaixo do mínimo:

$listaProdutos
${produtosBaixos.length > 10 ? '\n... e mais ${produtosBaixos.length - 10} produtos' : ''}

Verificar reposição urgente!
''';

      await _enviarParaAPI(
        tipo: 'stock_baixo',
        assunto: 'ALERTA: Stock Baixo',
        mensagem: mensagem,
      );

      print('✅ Notificação de stock baixo enviada');
    } catch (e) {
      print('⚠️ Erro ao enviar notificação: $e');
    }
  }

  /// Enviar notificação genérica
  Future<void> enviarNotificacao({
    required String assunto,
    required String mensagem,
  }) async {
    if (!notificacoesAtivas) return;
    if (!await temInternet()) return;

    try {
      await _enviarParaAPI(
        tipo: 'geral',
        assunto: assunto,
        mensagem: mensagem,
      );

      print('✅ Notificação enviada');
    } catch (e) {
      print('⚠️ Erro ao enviar notificação: $e');
    }
  }

  /// Enviar para API (você implementa sua API)
  Future<void> _enviarParaAPI({
    required String tipo,
    required String assunto,
    required String mensagem,
  }) async {
    // Buscar email da empresa
    final emailEmpresa = await _obterEmailEmpresa();

    if (emailEmpresa == null || emailEmpresa.isEmpty) {
      print('⚠️ Email da empresa não configurado - notificação não enviada');
      return;
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'tipo': tipo,
        'assunto': assunto,
        'mensagem': mensagem,
        'email': emailEmpresa,  // Email da empresa
        'telefone': telefoneCliente,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ).timeout(Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro na API: ${response.statusCode}');
    }
  }

  // Utilitários de formatação
  String _formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarMoeda(double valor) {
    return 'MT ${valor.toStringAsFixed(2)}';
  }
}
