import 'package:get/get.dart';
import '../../../data/repositories/usuario_repository.dart';
import '../../../data/models/usuario_model.dart';
import '../../../../core/services/auth_service.dart';

class LoginController extends GetxController {
  final UsuarioRepository _usuarioRepo = Get.put(UsuarioRepository());
  final AuthService _authService = Get.find<AuthService>();

  final RxList<UsuarioModel> usuarios = <UsuarioModel>[].obs;
  final Rxn<UsuarioModel> usuarioSelecionado = Rxn<UsuarioModel>();
  final RxString senha = ''.obs;
  final RxBool carregando = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarUsuarios();
  }

  Future<void> carregarUsuarios() async {
    try {
      carregando.value = true;
      usuarios.value = await _usuarioRepo.listarAtivos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar usuários: $e');
    } finally {
      carregando.value = false;
    }
  }

  void selecionarUsuario(UsuarioModel usuario) {
    usuarioSelecionado.value = usuario;
    senha.value = '';
  }

  void adicionarDigito(String digito) {
    if (senha.value.length < 8) {
      senha.value += digito;
    }
  }

  void limparSenha() {
    senha.value = '';
  }

  Future<void> fazerLogin() async {
    if (usuarioSelecionado.value == null) {
      Get.snackbar('Erro', 'Selecione um usuário');
      return;
    }

    if (senha.value.isEmpty) {
      Get.snackbar('Erro', 'Digite o código');
      return;
    }

    try {
      carregando.value = true;

      final usuario = await _usuarioRepo.buscarPorCodigo(senha.value);

      if (usuario == null) {
        Get.snackbar('Erro', 'Código inválido');
        senha.value = '';
        return;
      }

      if (usuario.id != usuarioSelecionado.value!.id) {
        Get.snackbar('Erro', 'Código não corresponde ao usuário selecionado');
        senha.value = '';
        return;
      }

      // Login bem-sucedido - salvar usuário no AuthService
      _authService.login(usuario);
      Get.back(result: usuario);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao fazer login: $e');
      senha.value = '';
    } finally {
      carregando.value = false;
    }
  }

  void cancelar() {
    Get.back();
  }
}
