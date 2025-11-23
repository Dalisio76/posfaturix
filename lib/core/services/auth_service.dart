import 'package:get/get.dart';
import '../../app/data/models/usuario_model.dart';

class AuthService extends GetxService {
  final Rxn<UsuarioModel> usuarioLogado = Rxn<UsuarioModel>();

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
}
