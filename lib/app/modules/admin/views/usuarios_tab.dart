import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/repositories/usuario_repository.dart';
import '../../../data/repositories/perfil_usuario_repository.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/models/perfil_usuario_model.dart';

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({Key? key}) : super(key: key);

  @override
  _UsuariosTabState createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  final UsuarioRepository _usuarioRepo = Get.put(UsuarioRepository());
  final PerfilUsuarioRepository _perfilRepo = Get.put(PerfilUsuarioRepository());

  final RxList<UsuarioModel> usuarios = <UsuarioModel>[].obs;
  final RxList<PerfilUsuarioModel> perfis = <PerfilUsuarioModel>[].obs;
  final RxInt linhaSelecionada = (-1).obs;

  final TextEditingController pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      usuarios.value = await _usuarioRepo.listarTodos();
      perfis.value = await _perfilRepo.listarAtivos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    }
  }

  Future<void> pesquisar() async {
    try {
      if (pesquisaController.text.isEmpty) {
        await carregarDados();
      } else {
        usuarios.value = await _usuarioRepo.pesquisar(pesquisaController.text);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar: $e');
    }
  }

  void adicionarUsuario() {
    _mostrarDialog(null);
  }

  void editarUsuario(UsuarioModel usuario) {
    _mostrarDialog(usuario);
  }

  void _mostrarDialog(UsuarioModel? usuario) {
    final nomeController = TextEditingController(text: usuario?.nome ?? '');
    final codigoController = TextEditingController(text: usuario?.codigo ?? '');
    final RxnInt perfilSelecionadoId = RxnInt(usuario?.perfilId);
    final RxBool ativo = (usuario?.ativo ?? true).obs;

    Get.dialog(
      AlertDialog(
        title: Text(usuario == null ? 'Novo Usuário' : 'Editar Usuário'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Perfil *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<int>(
                      value: perfilSelecionadoId.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: perfis.map((perfil) {
                        return DropdownMenuItem(
                          value: perfil.id,
                          child: Text(perfil.nome),
                        );
                      }).toList(),
                      onChanged: (value) => perfilSelecionadoId.value = value,
                    )),
                const SizedBox(height: 16),

                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código (1-8 dígitos) *',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 1234',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                const SizedBox(height: 16),

                Obx(() => CheckboxListTile(
                      title: const Text('Ativo'),
                      value: ativo.value,
                      onChanged: (value) => ativo.value = value ?? true,
                      contentPadding: EdgeInsets.zero,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }
              if (perfilSelecionadoId.value == null) {
                Get.snackbar('Erro', 'Selecione um perfil');
                return;
              }
              if (codigoController.text.isEmpty) {
                Get.snackbar('Erro', 'Código é obrigatório');
                return;
              }
              if (codigoController.text.length < 1 || codigoController.text.length > 8) {
                Get.snackbar('Erro', 'Código deve ter de 1 a 8 dígitos');
                return;
              }

              // Verificar se nome já existe
              final nomeExiste = await _usuarioRepo.nomeExiste(
                nomeController.text,
                excluirId: usuario?.id
              );
              if (nomeExiste) {
                Get.snackbar('Erro', 'Este nome já está em uso por outro usuário');
                return;
              }

              try {
                final usuarioData = UsuarioModel(
                  id: usuario?.id,
                  nome: nomeController.text,
                  perfilId: perfilSelecionadoId.value!,
                  codigo: codigoController.text,
                  ativo: ativo.value,
                );

                if (usuario == null) {
                  await _usuarioRepo.inserir(usuarioData);
                  Get.snackbar('Sucesso', 'Usuário criado com sucesso');
                } else {
                  await _usuarioRepo.atualizar(usuarioData);
                  Get.snackbar('Sucesso', 'Usuário atualizado com sucesso');
                }

                Get.back();
                await carregarDados();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao salvar usuário: $e');
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void redefinirSenha(UsuarioModel usuario) {
    final codigoController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Redefinir Senha - ${usuario.nome}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite o novo código para este usuário:'),
              const SizedBox(height: 16),
              TextField(
                controller: codigoController,
                decoration: const InputDecoration(
                  labelText: 'Novo Código (1-8 dígitos) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 1234',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codigoController.text.isEmpty) {
                Get.snackbar('Erro', 'Código é obrigatório');
                return;
              }
              if (codigoController.text.length < 1 || codigoController.text.length > 8) {
                Get.snackbar('Erro', 'Código deve ter de 1 a 8 dígitos');
                return;
              }

              try {
                await _usuarioRepo.redefinirSenha(usuario.id!, codigoController.text);
                Get.back();
                Get.snackbar('Sucesso', 'Senha redefinida com sucesso');
                await carregarDados();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao redefinir senha: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('REDEFINIR'),
          ),
        ],
      ),
    );
  }

  void deletarUsuario(UsuarioModel usuario) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente deletar o usuário "${usuario.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _usuarioRepo.deletar(usuario.id!);
                Get.back();
                Get.snackbar('Sucesso', 'Usuário deletado com sucesso');
                await carregarDados();
              } catch (e) {
                Get.back();
                Get.snackbar('Erro', 'Erro ao deletar usuário: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pesquisaController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar usuário...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => pesquisar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: pesquisar,
                  icon: const Icon(Icons.search),
                  label: const Text('PESQUISAR'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: adicionarUsuario,
                  icon: const Icon(Icons.add),
                  label: const Text('NOVO'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),

          // Tabela
          Expanded(
            child: Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('NOME')),
                        DataColumn(label: Text('PERFIL')),
                        DataColumn(label: Text('CÓDIGO')),
                        DataColumn(label: Text('ATIVO')),
                        DataColumn(label: Text('AÇÕES')),
                      ],
                      rows: usuarios.asMap().entries.map((entry) {
                        final index = entry.key;
                        final usuario = entry.value;

                        return DataRow(
                          selected: linhaSelecionada.value == index,
                          onSelectChanged: (_) => linhaSelecionada.value = index,
                          cells: [
                            DataCell(Text(usuario.id.toString())),
                            DataCell(Text(usuario.nome)),
                            DataCell(Text(usuario.perfilNome ?? '')),
                            DataCell(Text('*' * usuario.codigo.length)),
                            DataCell(
                              Icon(
                                usuario.ativo ? Icons.check_circle : Icons.cancel,
                                color: usuario.ativo ? Colors.green : Colors.red,
                              ),
                            ),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => editarUsuario(usuario),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.lock_reset, color: Colors.orange),
                                  onPressed: () => redefinirSenha(usuario),
                                  tooltip: 'Redefinir Senha',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deletarUsuario(usuario),
                                  tooltip: 'Deletar',
                                ),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }
}
