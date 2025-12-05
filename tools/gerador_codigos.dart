import 'dart:io';

/// GERADOR DE CÓDIGOS DE ATIVAÇÃO
/// Execute: dart run tools/gerador_codigos.dart

void main() {
  print('═══════════════════════════════════════════════════════════');
  print('          GERADOR DE CÓDIGOS DE ATIVAÇÃO                  ');
  print('                 PosFaturix - Frentex Software            ');
  print('═══════════════════════════════════════════════════════════');
  print('');

  // Perguntar quantos códigos gerar
  stdout.write('Quantos códigos deseja gerar? (1-10): ');
  final quantidadeStr = stdin.readLineSync() ?? '1';
  final quantidade = int.tryParse(quantidadeStr) ?? 1;

  if (quantidade < 1 || quantidade > 10) {
    print('❌ Quantidade inválida. Digite um número entre 1 e 10.');
    return;
  }

  print('');
  print('Gerando $quantidade código(s)...');
  print('');

  for (int i = 1; i <= quantidade; i++) {
    final codigo = gerarCodigoAtivacao();
    final dataVencimento = DateTime.now().add(Duration(days: 365));

    print('┌─────────────────────────────────────────┐');
    print('│ Código #$i                               │');
    print('├─────────────────────────────────────────┤');
    print('│  Código: $codigo           │');
    print('│  Válido até: ${_formatarData(dataVencimento)}                  │');
    print('│  Duração: 365 dias (1 ano)              │');
    print('└─────────────────────────────────────────┘');
    print('');
  }

  print('✅ Códigos gerados com sucesso!');
  print('');
  print('📋 INSTRUÇÕES PARA O CLIENTE:');
  print('   1. Abra o sistema PosFaturix');
  print('   2. Quando aparecer o alerta de vencimento');
  print('   3. Digite o código no campo "Código de Ativação"');
  print('   4. Clique em "ATIVAR"');
  print('');
  print('💡 IMPORTANTE:');
  print('   - Cada código renova a licença por 1 ano');
  print('   - O código só pode ser usado uma vez');
  print('   - Guarde este código em local seguro');
  print('');
}

/// Gerar código de ativação no formato AAAA-MMDD-XXXX
String gerarCodigoAtivacao() {
  final dataVencimento = DateTime.now().add(Duration(days: 365));
  final ano = dataVencimento.year;
  final mes = dataVencimento.month.toString().padLeft(2, '0');
  final dia = dataVencimento.day.toString().padLeft(2, '0');
  final hash = _gerarHashCodigo(ano, int.parse(mes), int.parse(dia));

  return '$ano-$mes$dia-$hash';
}

/// Gerar hash para código de ativação
String _gerarHashCodigo(int ano, int mes, int dia) {
  // IMPORTANTE: Esta é uma chave secreta - mantenha em segredo!
  final chaveSecreta = 'FRENTEX_POS_2025_SECRET_KEY';
  final dados = '$ano$mes$dia$chaveSecreta';

  // Hash simples (em produção, considere usar crypto)
  int hash = 0;
  for (int i = 0; i < dados.length; i++) {
    hash = ((hash << 5) - hash) + dados.codeUnitAt(i);
    hash = hash & hash; // Converter para 32bit
  }

  return hash.abs().toRadixString(16).toUpperCase().substring(0, 4).padLeft(4, '0');
}

/// Formatar data para exibição
String _formatarData(DateTime data) {
  return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
