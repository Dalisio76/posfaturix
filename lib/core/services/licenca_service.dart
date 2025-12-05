import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicencaService extends GetxService {
  // Estado da licença
  final RxBool licencaValida = true.obs;
  final RxInt diasRestantes = 365.obs;
  final RxString mensagemLicenca = ''.obs;
  final RxBool mostrarAlerta = false.obs;

  // Configurações
  static const String _keyDataInstalacao = 'data_instalacao';
  static const String _keyDataAtivacao = 'data_ativacao';
  static const String _keyUltimoAlerta = 'ultimo_alerta';
  static const int diasLicenca = 365; // 1 ano
  static const int diasAvisoAntecipado = 30; // Avisar 30 dias antes

  DateTime? _dataInstalacao;
  DateTime? _dataAtivacao;

  Future<LicencaService> init() async {
    await _carregarDatasLicenca();
    await verificarLicenca();
    return this;
  }

  /// Carregar datas de instalação e ativação
  Future<void> _carregarDatasLicenca() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Data de instalação
      final dataInstalacaoStr = prefs.getString(_keyDataInstalacao);
      if (dataInstalacaoStr != null) {
        _dataInstalacao = DateTime.parse(dataInstalacaoStr);
      } else {
        // Primeira vez - registrar data de instalação
        _dataInstalacao = DateTime.now();
        await prefs.setString(_keyDataInstalacao, _dataInstalacao!.toIso8601String());
        print('📅 Data de instalação registrada: $_dataInstalacao');
      }

      // Data de ativação (pode ser diferente da instalação)
      final dataAtivacaoStr = prefs.getString(_keyDataAtivacao);
      if (dataAtivacaoStr != null) {
        _dataAtivacao = DateTime.parse(dataAtivacaoStr);
      } else {
        // Se não tem ativação, usar data de instalação
        _dataAtivacao = _dataInstalacao;
        await prefs.setString(_keyDataAtivacao, _dataAtivacao!.toIso8601String());
        print('✅ Licença ativada em: $_dataAtivacao');
      }
    } catch (e) {
      print('❌ Erro ao carregar datas de licença: $e');
      // Em caso de erro, usar data atual
      _dataInstalacao = DateTime.now();
      _dataAtivacao = DateTime.now();
    }
  }

  /// Verificar status da licença
  Future<void> verificarLicenca() async {
    if (_dataAtivacao == null) {
      await _carregarDatasLicenca();
    }

    final agora = DateTime.now();
    final dataVencimento = _dataAtivacao!.add(Duration(days: diasLicenca));
    final diferenca = dataVencimento.difference(agora);

    diasRestantes.value = diferenca.inDays;

    print('📊 Status da Licença:');
    print('   Ativada em: ${_dataAtivacao!.toString().split('.')[0]}');
    print('   Vence em: ${dataVencimento.toString().split('.')[0]}');
    print('   Dias restantes: ${diasRestantes.value}');

    // Licença vencida
    if (diasRestantes.value <= 0) {
      licencaValida.value = false;
      mensagemLicenca.value = '''
🔴 LICENÇA VENCIDA

Sua licença do sistema expirou.

Para continuar usando o sistema, entre em contato com o suporte para renovar sua anuidade.

Telefone: [SEU TELEFONE]
Email: [SEU EMAIL]
      ''';
      mostrarAlerta.value = true;
      print('🔴 LICENÇA VENCIDA!');
      return;
    }

    // Avisar 30 dias antes
    if (diasRestantes.value <= diasAvisoAntecipado) {
      licencaValida.value = true; // Ainda válida, mas avisar
      mensagemLicenca.value = '''
⚠️ LICENÇA PRÓXIMA DO VENCIMENTO

Sua licença vence em ${diasRestantes.value} dia(s).

Para evitar interrupções, renove sua anuidade o quanto antes.

Telefone: [SEU TELEFONE]
Email: [SEU EMAIL]
      ''';

      // Verificar se deve mostrar alerta diário
      await _verificarAlertaDiario();

      print('⚠️ ATENÇÃO: Licença vence em ${diasRestantes.value} dias');
      return;
    }

    // Licença válida e com tempo suficiente
    licencaValida.value = true;
    mostrarAlerta.value = false;
    print('✅ Licença válida: ${diasRestantes.value} dias restantes');
  }

  /// Verificar se deve mostrar alerta diário
  Future<void> _verificarAlertaDiario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimoAlertaStr = prefs.getString(_keyUltimoAlerta);

      if (ultimoAlertaStr == null) {
        // Primeiro alerta
        mostrarAlerta.value = true;
        await _registrarAlertaMostrado();
        return;
      }

      final ultimoAlerta = DateTime.parse(ultimoAlertaStr);
      final agora = DateTime.now();
      final diferencaHoras = agora.difference(ultimoAlerta).inHours;

      // Mostrar alerta uma vez por dia (24 horas)
      if (diferencaHoras >= 24) {
        mostrarAlerta.value = true;
        await _registrarAlertaMostrado();
        print('📢 Mostrando alerta diário de vencimento');
      } else {
        mostrarAlerta.value = false;
        print('⏳ Próximo alerta em ${24 - diferencaHoras} horas');
      }
    } catch (e) {
      print('❌ Erro ao verificar alerta diário: $e');
      mostrarAlerta.value = true;
    }
  }

  /// Registrar que o alerta foi mostrado
  Future<void> _registrarAlertaMostrado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUltimoAlerta, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Erro ao registrar alerta: $e');
    }
  }

  /// Renovar licença (chamar após pagamento)
  Future<void> renovarLicenca() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novaDataAtivacao = DateTime.now();

      await prefs.setString(_keyDataAtivacao, novaDataAtivacao.toIso8601String());
      await prefs.remove(_keyUltimoAlerta); // Limpar alertas anteriores

      _dataAtivacao = novaDataAtivacao;

      await verificarLicenca();

      print('✅ Licença renovada com sucesso!');
      print('   Nova data de vencimento: ${_dataAtivacao!.add(Duration(days: diasLicenca))}');
    } catch (e) {
      print('❌ Erro ao renovar licença: $e');
    }
  }

  /// Inserir código de ativação (para renovação)
  Future<bool> ativarComCodigo(String codigoAtivacao) async {
    try {
      // Validar código de ativação
      // Formato sugerido: AAAA-MMDD-XXXX (ano-mesdia-hash)
      // Exemplo: 2026-0105-AB3F

      if (!_validarFormatoCodigo(codigoAtivacao)) {
        print('❌ Código de ativação inválido: formato incorreto');
        return false;
      }

      // Extrair ano e data do código
      final partes = codigoAtivacao.split('-');
      final ano = int.tryParse(partes[0]);
      final mesdia = partes[1];
      final mes = int.tryParse(mesdia.substring(0, 2));
      final dia = int.tryParse(mesdia.substring(2, 4));

      if (ano == null || mes == null || dia == null) {
        print('❌ Código de ativação inválido: data inválida');
        return false;
      }

      // Verificar hash (implementar validação real)
      final hashEsperado = _gerarHashCodigo(ano, mes, dia);
      if (partes[2] != hashEsperado) {
        print('❌ Código de ativação inválido: hash incorreto');
        return false;
      }

      // Calcular nova data de ativação baseada no código
      final novaDataAtivacao = DateTime(ano, mes, dia).subtract(Duration(days: diasLicenca));

      // Verificar se a data é válida (não pode ser no passado distante)
      final agoraMinusUmMes = DateTime.now().subtract(Duration(days: 30));
      if (novaDataAtivacao.isBefore(agoraMinusUmMes)) {
        print('❌ Código de ativação expirado');
        return false;
      }

      // Ativar licença
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDataAtivacao, novaDataAtivacao.toIso8601String());
      await prefs.remove(_keyUltimoAlerta);

      _dataAtivacao = novaDataAtivacao;
      await verificarLicenca();

      print('✅ Licença ativada com código!');
      print('   Data de ativação: $novaDataAtivacao');
      print('   Válida até: ${_dataAtivacao!.add(Duration(days: diasLicenca))}');

      return true;
    } catch (e) {
      print('❌ Erro ao ativar com código: $e');
      return false;
    }
  }

  /// Validar formato do código (AAAA-MMDD-XXXX)
  bool _validarFormatoCodigo(String codigo) {
    final regex = RegExp(r'^\d{4}-\d{4}-[A-F0-9]{4}$');
    return regex.hasMatch(codigo);
  }

  /// Gerar hash para código de ativação
  String _gerarHashCodigo(int ano, int mes, int dia) {
    // Implementação simples - VOCÊ DEVE USAR ALGO MAIS SEGURO EM PRODUÇÃO
    final chaveSecreta = 'FRENTEX_POS_2025'; // Mudar para algo único
    final dados = '$ano$mes$dia$chaveSecreta';

    // Hash simples (em produção, use crypto)
    int hash = 0;
    for (int i = 0; i < dados.length; i++) {
      hash = ((hash << 5) - hash) + dados.codeUnitAt(i);
      hash = hash & hash; // Converter para 32bit
    }

    return hash.abs().toRadixString(16).toUpperCase().substring(0, 4).padLeft(4, '0');
  }

  /// Gerar código de ativação (para você enviar ao cliente)
  String gerarCodigoAtivacao() {
    final dataVencimento = DateTime.now().add(Duration(days: diasLicenca));
    final ano = dataVencimento.year;
    final mes = dataVencimento.month.toString().padLeft(2, '0');
    final dia = dataVencimento.day.toString().padLeft(2, '0');
    final hash = _gerarHashCodigo(ano, int.parse(mes), int.parse(dia));

    final codigo = '$ano-$mes$dia-$hash';
    print('📝 Código de ativação gerado: $codigo');
    print('   Válido até: $dataVencimento');

    return codigo;
  }

  /// Resetar licença (apenas para desenvolvimento/teste)
  Future<void> resetarLicenca() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDataInstalacao);
      await prefs.remove(_keyDataAtivacao);
      await prefs.remove(_keyUltimoAlerta);

      await _carregarDatasLicenca();
      await verificarLicenca();

      print('🔄 Licença resetada');
    } catch (e) {
      print('❌ Erro ao resetar licença: $e');
    }
  }

  /// Obter informações da licença
  Map<String, dynamic> obterInfoLicenca() {
    return {
      'dataInstalacao': _dataInstalacao?.toIso8601String(),
      'dataAtivacao': _dataAtivacao?.toIso8601String(),
      'dataVencimento': _dataAtivacao?.add(Duration(days: diasLicenca)).toIso8601String(),
      'diasRestantes': diasRestantes.value,
      'licencaValida': licencaValida.value,
      'diasLicenca': diasLicenca,
      'diasAvisoAntecipado': diasAvisoAntecipado,
    };
  }
}
