import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/impressora_model.dart';
import '../../../data/repositories/impressora_repository.dart';

class ImpressorasTab extends StatefulWidget {
  const ImpressorasTab({Key? key}) : super(key: key);

  @override
  State<ImpressorasTab> createState() => _ImpressorasTabState();
}

class _ImpressorasTabState extends State<ImpressorasTab> {
  late final ImpressoraRepository _repo;
  final RxList<ImpressoraModel> impressoras = <ImpressoraModel>[].obs;
  final RxBool carregando = false.obs;

  @override
  void initState() {
    super.initState();
    _repo = ImpressoraRepository();
    _carregarImpressoras();
  }

  Future<void> _carregarImpressoras() async {
    try {
      carregando.value = true;
      impressoras.value = await _repo.listarTodas();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar impressoras: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              if (carregando.value && impressoras.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (impressoras.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print_disabled, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma impressora cadastrada',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialogImpressora(null),
                        icon: const Icon(Icons.add),
                        label: const Text('ADICIONAR PRIMEIRA IMPRESSORA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildLista();
            }),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.print, color: Colors.blue[700], size: 28),
          ),
          const SizedBox(width: 16),
          const Text(
            'GESTÃO DE IMPRESSORAS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${impressoras.length} impressoras',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: impressoras.map((impressora) => _buildCard(impressora)).toList(),
    );
  }

  Widget _buildCard(ImpressoraModel impressora) {
    final Color statusColor = impressora.ativo ? Colors.green : Colors.grey;
    final IconData tipoIcon = _getTipoIcon(impressora.tipo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: impressora.ativo ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tipoIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          impressora.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          impressora.ativo ? 'ATIVA' : 'INATIVA',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Tipo: ${impressora.tipo.toUpperCase()}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Largura: ${impressora.larguraPapel}mm',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (impressora.descricao != null && impressora.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      impressora.descricao!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (impressora.caminhoRede != null && impressora.caminhoRede!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.share, size: 14, color: Colors.purple[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Rede: ${impressora.caminhoRede}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[700],
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Ações
            Column(
              children: [
                IconButton(
                  onPressed: () => _mostrarDialogImpressora(impressora),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () => _confirmarDelete(impressora.id!),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Deletar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'termica':
        return Icons.receipt_long;
      case 'matricial':
        return Icons.print;
      case 'laser':
        return Icons.print_outlined;
      default:
        return Icons.print;
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogImpressora(null),
            icon: const Icon(Icons.add),
            label: const Text('ADICIONAR IMPRESSORA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: _carregarImpressoras,
            icon: const Icon(Icons.refresh),
            label: const Text('ATUALIZAR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              side: BorderSide(color: Colors.blue[300]!),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogImpressora(ImpressoraModel? impressora) {
    final nomeController = TextEditingController(text: impressora?.nome ?? '');
    final descricaoController = TextEditingController(text: impressora?.descricao ?? '');
    final caminhoRedeController = TextEditingController(text: impressora?.caminhoRede ?? '');
    final RxString tipoSelecionado = (impressora?.tipo ?? 'termica').obs;
    final RxInt larguraSelecionada = (impressora?.larguraPapel ?? 80).obs;
    final RxBool ativo = (impressora?.ativo ?? true).obs;

    final tipos = ['termica', 'matricial', 'laser'];
    final larguras = [58, 80];

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Text(impressora == null ? 'Nova Impressora' : 'Editar Impressora'),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Impressora *',
                    hintText: 'Ex: Impressora Cozinha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.print),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Tipo de Impressora', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      children: tipos.map((tipo) {
                        final selecionado = tipoSelecionado.value == tipo;
                        return ChoiceChip(
                          label: Text(tipo.toUpperCase()),
                          selected: selecionado,
                          onSelected: (selected) {
                            if (selected) tipoSelecionado.value = tipo;
                          },
                          selectedColor: Colors.blue[200],
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 16),
                const Text('Largura do Papel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      children: larguras.map((largura) {
                        final selecionado = larguraSelecionada.value == largura;
                        return ChoiceChip(
                          label: Text('${largura}mm'),
                          selected: selecionado,
                          onSelected: (selected) {
                            if (selected) larguraSelecionada.value = largura;
                          },
                          selectedColor: Colors.blue[200],
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 16),
                TextField(
                  controller: descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (Opcional)',
                    hintText: 'Ex: Impressora térmica da cozinha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: caminhoRedeController,
                  decoration: const InputDecoration(
                    labelText: 'Caminho de Rede (Opcional)',
                    hintText: r'Ex: \\ComputadorX\ImpressoraCozinha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.share),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Use caminho de rede para impressoras compartilhadas entre computadores',
                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => SwitchListTile(
                      title: const Text('Impressora Ativa'),
                      subtitle: Text(
                        ativo.value
                            ? 'Impressora disponível para uso'
                            : 'Impressora desativada',
                      ),
                      value: ativo.value,
                      onChanged: (valor) => ativo.value = valor,
                      activeColor: Colors.green,
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
          ElevatedButton.icon(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) {
                Get.snackbar(
                  'Atenção',
                  'Informe o nome da impressora',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              try {
                final caminhoRede = caminhoRedeController.text.trim();
                final novaImpressora = ImpressoraModel(
                  id: impressora?.id,
                  nome: nome,
                  tipo: tipoSelecionado.value,
                  descricao: descricaoController.text.trim(),
                  larguraPapel: larguraSelecionada.value,
                  ativo: ativo.value,
                  caminhoRede: caminhoRede.isEmpty ? null : caminhoRede,
                );

                if (impressora == null) {
                  await _repo.criar(novaImpressora);
                  Get.snackbar(
                    'Sucesso',
                    'Impressora criada com sucesso',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  await _repo.atualizar(novaImpressora);
                  Get.snackbar(
                    'Sucesso',
                    'Impressora atualizada com sucesso',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }

                Get.back();
                _carregarImpressoras();
              } catch (e) {
                Get.snackbar(
                  'Erro',
                  'Erro ao salvar impressora: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('SALVAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarDelete(int id) async {
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja excluir esta impressora?\n\n'
          'Todas as associações com documentos e áreas serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SIM, EXCLUIR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _repo.deletar(id);
        Get.snackbar(
          'Sucesso',
          'Impressora excluída com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _carregarImpressoras();
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Erro ao excluir impressora: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
