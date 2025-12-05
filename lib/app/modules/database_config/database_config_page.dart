import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'database_config_controller.dart';

class DatabaseConfigPage extends StatelessWidget {
  const DatabaseConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DatabaseConfigController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ícone e título
                    Icon(
                      Icons.storage,
                      size: 64,
                      color: Colors.red[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Configuração do Banco de Dados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      controller.isConnected.value
                          ? '✅ Conectado com sucesso!'
                          : '❌ Não foi possível conectar ao PostgreSQL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: controller.isConnected.value
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                    const SizedBox(height: 32),

                    // Campo Host
                    TextField(
                      controller: controller.hostController,
                      decoration: InputDecoration(
                        labelText: 'Servidor (Host)',
                        hintText: 'localhost ou 192.168.1.10',
                        prefixIcon: const Icon(Icons.dns),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Porta
                    TextField(
                      controller: controller.portController,
                      decoration: InputDecoration(
                        labelText: 'Porta',
                        hintText: '5432',
                        prefixIcon: const Icon(Icons.settings_ethernet),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Campo Database
                    TextField(
                      controller: controller.databaseController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Banco',
                        hintText: 'pdv_system',
                        prefixIcon: const Icon(Icons.storage),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Username
                    TextField(
                      controller: controller.usernameController,
                      decoration: InputDecoration(
                        labelText: 'Usuário',
                        hintText: 'postgres',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Password
                    Obx(() => TextField(
                      controller: controller.passwordController,
                      obscureText: !controller.showPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Dica de configuração
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Se este é o servidor principal, use "localhost".\nSe é um terminal, use o IP do servidor (ex: 192.168.1.10).',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Testar Conexão
                    Obx(() => ElevatedButton.icon(
                      onPressed: controller.isTesting.value
                          ? null
                          : controller.testConnection,
                      icon: controller.isTesting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.link),
                      label: Text(
                        controller.isTesting.value
                            ? 'Testando...'
                            : 'Testar Conexão',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),

                    // Botão Salvar e Continuar
                    Obx(() => ElevatedButton.icon(
                      onPressed: controller.isConnected.value
                          ? controller.saveAndContinue
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Salvar e Continuar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Mensagem de erro
                    Obx(() {
                      if (controller.errorMessage.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
