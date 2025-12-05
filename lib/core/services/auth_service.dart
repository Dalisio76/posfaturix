import 'package:get/get.dart';
import '../../app/data/models/usuario_model.dart';
import '../../app/data/repositories/permissao_repository.dart';

class AuthService extends GetxService {
  final Rxn<UsuarioModel> usuarioLogado = Rxn<UsuarioModel>();
  late final PermissaoRepository _permissaoRepo;

  @override
  void onInit() {
    super.onInit();
    _permissaoRepo = Get.put(PermissaoRepository());
  }

  void login(UsuarioModel usuario) {
    usuarioLogado.value = usuario;
  }

  void logout() {
    usuarioLogado.value = null;
  }

  bool get isLogado => usuarioLogado.value != null;

  UsuarioModel? get usuario => usuarioLogado.value;

  String get nomeUsuario => usuarioLogado.value?.nome ?? 'Desconhecido';

  String get perfilUsuario => usuarioLogado.value?.perfilNome ?? 'Sem perfil';

  int? get usuarioId => usuarioLogado.value?.id;

  /// Verificar se usuário tem uma permissão específica
  Future<bool> temPermissao(String codigoPermissao) async {
    if (usuarioLogado.value == null) return false;
    if (usuarioLogado.value!.id == null) return false;

    // BYPASS: Administradores e Super Administradores têm acesso total
    final perfilNome = usuarioLogado.value!.perfilNome?.toLowerCase() ?? '';
    if (perfilNome.contains('administrador')) {
      return true;
    }

    return await _permissaoRepo.usuarioTemPermissao(
      usuarioLogado.value!.id!,
      codigoPermissao,
    );
  }

  /// Verificar permissão e mostrar mensagem se não tiver
  Future<bool> verificarPermissao(String codigoPermissao, {String? mensagem}) async {
    final tem = await temPermissao(codigoPermissao);

    if (!tem) {
      Get.snackbar(
        'Acesso Negado',
        mensagem ?? 'Você não tem permissão para esta operação',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }

    return tem;
  }

  /// Verificar se tem pelo menos uma das permissões da lista
  Future<bool> temAlgumaPermissao(List<String> codigosPermissao) async {
    if (usuarioLogado.value == null) return false;

    for (final codigo in codigosPermissao) {
      if (await temPermissao(codigo)) return true;
    }

    return false;
  }

  /// Verificar se tem todas as permissões da lista
  Future<bool> temTodasPermissoes(List<String> codigosPermissao) async {
    if (usuarioLogado.value == null) return false;

    for (final codigo in codigosPermissao) {
      if (!await temPermissao(codigo)) return false;
    }

    return true;
  }
}
