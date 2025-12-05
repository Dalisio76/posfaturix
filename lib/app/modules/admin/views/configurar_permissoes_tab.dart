import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/permissao_repository.dart';
import '../../../data/repositories/perfil_usuario_repository.dart';
import '../../../data/models/perfil_usuario_model.dart';
import '../../../data/models/permissao_model.dart';

class ConfigurarPermissoesTab extends StatefulWidget {
  const ConfigurarPermissoesTab({Key? key}) : super(key: key);

  @override
  State<ConfigurarPermissoesTab> createState() =>
      _ConfigurarPermissoesTabState();
}

class _ConfigurarPermissoesTabState extends State<ConfigurarPermissoesTab> {
  final PermissaoRepository _permissaoRepo = Get.put(PermissaoRepository());
  final PerfilUsuarioRepository _perfilRepo = Get.put(PerfilUsuarioRepository());

  final RxList<PermissaoModel> permissoes = <PermissaoModel>[].obs;
  final RxList<PerfilUsuarioModel> perfis = <PerfilUsuarioModel>[].obs;
  final RxBool carregando = false.obs;
  final Rxn<PerfilUsuarioModel> perfilSelecionado = Rxn<PerfilUsuarioModel>();
  final RxMap<int, bool> permissoesPerfil = <int, bool>{}.obs;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      carregando.value = true;
      permissoes.value = await _permissaoRepo.listarTodas();
      perfis.value = await _perfilRepo.listarAtivos();

      // Seleciona primeiro perfil por padrão
      if (perfis.isNotEmpty) {
        perfilSelecionado.value = perfis.first;
        await _carregarPermissoesDoPerfil(perfis.first);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _carregarPermissoesDoPerfil(PerfilUsuarioModel perfil) async {
    try {
      carregando.value = true;
      permissoesPerfil.clear();

      final permissoesDoPerfil = await _permissaoRepo.listarPermissoesPerfil(perfil.id!);

      for (final permissao in permissoes) {
        permissoesPerfil[permissao.id!] = permissoesDoPerfil.any((p) => p.id == permissao.id);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar permissões do perfil: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _salvarPermissoes() async {
    if (perfilSelecionado.value == null) {
      Get.snackbar(
        'Atenção',
        'Selecione um perfil',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      carregando.value = true;

      for (final permissao in permissoes) {
        final temPermissao = permissoesPerfil[permissao.id!] ?? false;

        if (temPermissao) {
          await _permissaoRepo.atribuirPermissao(
            perfilSelecionado.value!.id!,
            permissao.id!,
          );
        } else {
          await _permissaoRepo.removerPermissao(
            perfilSelecionado.value!.id!,
            permissao.id!,
          );
        }
      }

      Get.snackbar(
        'Sucesso',
        'Permissões salvas com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar permissões: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Map<String, List<PermissaoModel>> _agruparPermissoesPorCategoria() {
    final Map<String, List<PermissaoModel>> grupos = {};

    for (final permissao in permissoes) {
      final categoria = (permissao.categoria ?? 'DIVERSOS').toUpperCase();
      if (!grupos.containsKey(categoria)) {
        grupos[categoria] = [];
      }
      grupos[categoria]!.add(permissao);
    }

    return grupos;
  }

  void _toggleTodasPermissoes(bool valor) {
    for (final permissao in permissoes) {
      permissoesPerfil[permissao.id!] = valor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Obx(() {
        if (carregando.value && permissoes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildWindowsToolbar(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        );
      }),
    );
  }

  /// Barra de ferramentas estilo Windows
  Widget _buildWindowsToolbar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Dropdown de Perfil
            Obx(() => Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(2),
              ),
              child: DropdownButton<PerfilUsuarioModel>(
                value: perfilSelecionado.value,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[700]),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                ),
                items: perfis.map((perfil) {
                  return DropdownMenuItem(
                    value: perfil,
                    child: Text(perfil.nome),
                  );
                }).toList(),
                onChanged: (perfil) async {
                  if (perfil != null) {
                    perfilSelecionado.value = perfil;
                    await _carregarPermissoesDoPerfil(perfil);
                  }
                },
              ),
            )),
            const SizedBox(width: 8),
            // Separador
            Container(
              width: 1,
              height: 24,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 8),
            // Botão Selecionar Todas
            _buildToolbarButton(
              icon: Icons.check_box,
              label: 'Selecionar Todas',
              onPressed: () => _toggleTodasPermissoes(true),
            ),
            const SizedBox(width: 4),
            // Botão Desmarcar Todas
            _buildToolbarButton(
              icon: Icons.check_box_outline_blank,
              label: 'Desmarcar Todas',
              onPressed: () => _toggleTodasPermissoes(false),
            ),
            const Spacer(),
            // Contador de permissões
            Obx(() {
              final total = permissoes.length;
              final ativas = permissoesPerfil.values.where((v) => v).length;
              return Text(
                '$ativas de $total permissões selecionadas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              );
            }),
            const SizedBox(width: 12),
            // Separador
            Container(
              width: 1,
              height: 24,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            // Botão Salvar
            Obx(() => _buildSaveButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(2),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: carregando.value ? null : _salvarPermissoes,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: carregando.value ? Colors.grey[300] : const Color(0xFF0078D4),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: carregando.value ? Colors.grey[400]! : const Color(0xFF005A9E),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (carregando.value)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.save, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              carregando.value ? 'Salvando...' : 'Salvar',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Conteúdo principal - Grid de permissões
  Widget _buildMainContent() {
    return Obx(() {
      if (perfilSelecionado.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Selecione um perfil para configurar permissões',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      final permissoesAgrupadas = _agruparPermissoesPorCategoria();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: permissoesAgrupadas.entries.map((entry) {
            return _buildCategoriaGroup(entry.key, entry.value);
          }).toList(),
        ),
      );
    });
  }

  /// Grupo de categoria estilo Windows (GroupBox)
  Widget _buildCategoriaGroup(String categoria, List<PermissaoModel> permissoesCategoria) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da categoria
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              border: Border(
                bottom: BorderSide(color: Colors.grey[400]!),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoriaIcon(categoria),
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  categoria,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Obx(() {
                  final total = permissoesCategoria.length;
                  final ativas = permissoesCategoria.where((p) => permissoesPerfil[p.id!] ?? false).length;
                  return Text(
                    '($ativas/$total)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  );
                }),
              ],
            ),
          ),
          // Grid de permissões
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildPermissoesGrid(permissoesCategoria),
          ),
        ],
      ),
    );
  }

  /// Grid de checkboxes estilo Windows
  Widget _buildPermissoesGrid(List<PermissaoModel> permissoesCategoria) {
    // Organiza em 3 colunas
    final int colunas = 3;
    final List<List<PermissaoModel>> linhas = [];

    for (int i = 0; i < permissoesCategoria.length; i += colunas) {
      final end = (i + colunas < permissoesCategoria.length)
          ? i + colunas
          : permissoesCategoria.length;
      linhas.add(permissoesCategoria.sublist(i, end));
    }

    return Column(
      children: linhas.map((linha) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: linha.map((permissao) {
              return Expanded(
                child: _buildWindowsCheckbox(permissao),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Checkbox estilo Windows (compacto)
  Widget _buildWindowsCheckbox(PermissaoModel permissao) {
    return Obx(() {
      final ativa = permissoesPerfil[permissao.id!] ?? false;

      return InkWell(
        onTap: () {
          permissoesPerfil[permissao.id!] = !ativa;
        },
        borderRadius: BorderRadius.circular(2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: ativa,
                  onChanged: (valor) {
                    if (valor != null) {
                      permissoesPerfil[permissao.id!] = valor;
                    }
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: const Color(0xFF0078D4),
                  side: BorderSide(
                    color: Colors.grey[600]!,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permissao.nome,
                        style: TextStyle(
                          fontSize: 12,
                          color: ativa ? Colors.black87 : Colors.grey[700],
                          fontWeight: ativa ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (permissao.descricao != null && permissao.descricao!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          permissao.descricao!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'VENDAS':
        return Icons.point_of_sale;
      case 'STOCK':
        return Icons.inventory_2_outlined;
      case 'CADASTROS':
        return Icons.app_registration;
      case 'FINANCEIRO':
        return Icons.attach_money;
      case 'RELATORIOS':
        return Icons.assessment;
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'NOTIFICACOES':
        return Icons.notifications_outlined;
      default:
        return Icons.settings;
    }
  }
}
