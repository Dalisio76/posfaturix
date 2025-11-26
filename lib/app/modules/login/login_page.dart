import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controllers/login_controller.dart';
import '../../data/models/usuario_model.dart';

class LoginPage extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());

  LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            // Lado esquerdo - Usuários
            Expanded(
              flex: 2,
              child: _buildUserGrid(),
            ),

            // Lado direito - Senha e teclado
            Expanded(
              flex: 1,
              child: _buildPasswordPanel(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildUserGrid() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Obx(() => GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1,
            ),
            itemCount: controller.usuarios.length,
            itemBuilder: (context, index) {
              final usuario = controller.usuarios[index];
              return _buildUserAvatar(usuario);
            },
          )),
    );
  }

  Widget _buildUserAvatar(UsuarioModel usuario) {
    return Obx(() {
      final isSelected = controller.usuarioSelecionado.value?.id == usuario.id;

      return InkWell(
        onTap: () => controller.selecionarUsuario(usuario),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[600]!,
                  width: isSelected ? 4 : 3,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 70,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              usuario.nome.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPasswordPanel() {
    return Focus(
      autofocus: true,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          final key = event.logicalKey;

          // Lista de teclas numéricas do teclado principal
          final mainDigits = [
            LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5,
            LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7, LogicalKeyboardKey.digit8,
            LogicalKeyboardKey.digit9
          ];

          // Lista de teclas numéricas do numpad
          final numpadDigits = [
            LogicalKeyboardKey.numpad0, LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2,
            LogicalKeyboardKey.numpad3, LogicalKeyboardKey.numpad4, LogicalKeyboardKey.numpad5,
            LogicalKeyboardKey.numpad6, LogicalKeyboardKey.numpad7, LogicalKeyboardKey.numpad8,
            LogicalKeyboardKey.numpad9
          ];

          // Números do teclado principal
          if (mainDigits.contains(key)) {
            controller.adicionarDigito(key.keyLabel);
            return KeyEventResult.handled;
          }
          // Números do numpad
          else if (numpadDigits.contains(key)) {
            controller.adicionarDigito(key.keyLabel);
            return KeyEventResult.handled;
          }
          // Backspace ou Delete
          else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
            if (controller.senha.value.isNotEmpty) {
              controller.senha.value = controller.senha.value.substring(0, controller.senha.value.length - 1);
            }
            return KeyEventResult.handled;
          }
          // Enter
          else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
            controller.fazerLogin();
            return KeyEventResult.handled;
          }
          // Escape para limpar
          else if (key == LogicalKeyboardKey.escape) {
            controller.limparSenha();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
        children: [
          // Botões superiores
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: Implementar alteração de senha
                  Get.snackbar('Info', 'Funcionalidade em desenvolvimento');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('ALTERAR SENHA'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: controller.cancelar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('CANCELAR'),
              ),
            ],
          ),

          const Spacer(),

          // Campo de senha
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SENHA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '*' * controller.senha.value.length,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Teclado numérico
          _buildNumericKeypad(),

          const SizedBox(height: 24),

          // Botão OK
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: controller.fazerLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    ),
    );
  }

  Widget _buildNumericKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 8),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildKeypadRow(['C', '0', '.']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeypadButton(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          if (key == 'C') {
            controller.limparSenha();
          } else if (key == '.') {
            // Ignorar ponto decimal para código numérico
          } else {
            controller.adicionarDigito(key);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
