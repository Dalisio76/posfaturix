import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/licenca_service.dart';

class LicencaDialog extends StatelessWidget {
  final bool bloqueado;

  const LicencaDialog({Key? key, this.bloqueado = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final licencaService = Get.find<LicencaService>();
    final codigoController = TextEditingController();

    return WillPopScope(
      onWillPop: () async => !bloqueado, // Só pode fechar se não estiver bloqueado
      child: Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone
              Icon(
                bloqueado ? Icons.lock : Icons.warning_amber,
                size: 64,
                color: bloqueado ? Colors.red[700] : Colors.orange[700],
              ),
              const SizedBox(height: 16),

              // Título
              Text(
                bloqueado ? 'LICENÇA VENCIDA' : 'AVISO DE VENCIMENTO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: bloqueado ? Colors.red[700] : Colors.orange[900],
                ),
              ),
              const SizedBox(height: 16),

              // Mensagem
              Obx(() => Text(
                licencaService.mensagemLicenca.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              )),
              const SizedBox(height: 24),

              // Informações da licença
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() {
                  final info = licencaService.obterInfoLicenca();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Data de Instalação:', _formatarData(info['dataInstalacao'])),
                      _buildInfoRow('Data de Ativação:', _formatarData(info['dataAtivacao'])),
                      _buildInfoRow('Data de Vencimento:', _formatarData(info['dataVencimento'])),
                      const Divider(),
                      _buildInfoRow(
                        'Dias Restantes:',
                        '${info['diasRestantes']} dia(s)',
                        cor: info['diasRestantes'] <= 0
                            ? Colors.red
                            : info['diasRestantes'] <= 30
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Campo para código de ativação
              TextField(
                controller: codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de Ativação',
                  hintText: 'AAAA-MMDD-XXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-F-]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    String text = newValue.text.toUpperCase();
                    // Auto-adicionar hífens
                    if (text.length == 4 && !text.contains('-')) {
                      text = '$text-';
                    } else if (text.length == 9 && text.split('-').length == 2) {
                      text = '$text-';
                    }
                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                  LengthLimitingTextInputFormatter(14), // AAAA-MMDD-XXXX
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botão Ativar
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (codigoController.text.isEmpty) {
                        Get.snackbar(
                          'Erro',
                          'Digite o código de ativação',
                          backgroundColor: Colors.red[100],
                          colorText: Colors.red[900],
                        );
                        return;
                      }

                      final sucesso = await licencaService.ativarComCodigo(codigoController.text);

                      if (sucesso) {
                        Get.back(); // Fechar dialog
                        Get.snackbar(
                          '✅ Sucesso',
                          'Licença ativada com sucesso!',
                          backgroundColor: Colors.green[100],
                          colorText: Colors.green[900],
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                        );
                      } else {
                        Get.snackbar(
                          '❌ Erro',
                          'Código de ativação inválido ou expirado',
                          backgroundColor: Colors.red[100],
                          colorText: Colors.red[900],
                          icon: const Icon(Icons.error, color: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('ATIVAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Botão Fechar (só se não estiver bloqueado)
                  if (!bloqueado)
                    TextButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                      label: const Text('FECHAR'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),

                  // Botão Sair (se estiver bloqueado)
                  if (bloqueado)
                    TextButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('SAIR DO SISTEMA'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Informações de contato
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Para renovar sua licença, entre em contato:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '📞 Telefone: [SEU TELEFONE]',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '📧 Email: [SEU EMAIL]',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '💬 WhatsApp: [SEU WHATSAPP]',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              color: cor ?? Colors.black,
              fontWeight: cor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return 'N/A';
    try {
      final data = DateTime.parse(dataIso);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
