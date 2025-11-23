import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/acerto_stock_repository.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/setor_model.dart';
import '../../../data/models/familia_model.dart';
import 'consultar_acertos_tab.dart';

class AcertoStockTab extends StatefulWidget {
  const AcertoStockTab({Key? key}) : super(key: key);

  @override
  _AcertoStockTabState createState() => _AcertoStockTabState();
}

class _AcertoStockTabState extends State<AcertoStockTab> {
  final ProdutoRepository _produtoRepo = Get.put(ProdutoRepository());
  final SetorRepository _setorRepo = Get.put(SetorRepository());
  final FamiliaRepository _familiaRepo = Get.put(FamiliaRepository());
  final AcertoStockRepository _acertoRepo = Get.put(AcertoStockRepository());

  final RxList<ProdutoModel> produtos = <ProdutoModel>[].obs;
  final RxList<SetorModel> setores = <SetorModel>[].obs;
  final RxList<FamiliaModel> familias = <FamiliaModel>[].obs;
  final Rxn<SetorModel> setorSelecionado = Rxn<SetorModel>();
  final Rxn<FamiliaModel> familiaSelecionada = Rxn<FamiliaModel>();

  final TextEditingController produtoController = TextEditingController();

  // Map para armazenar alterações: produto_id -> novo estoque
  final RxMap<int, int> alteracoes = <int, int>{}.obs;
  // Map para armazenar motivos: produto_id -> motivo
  final RxMap<int, String> motivos = <int, String>{}.obs;
  // Produtos selecionados com checkbox
  final RxList<int> produtosSelecionados = <int>[].obs;
  final RxBool selecionarTodos = false.obs;

  final List<String> motivosDisponiveis = [
    '-',
    'Acerto Manual',
    'Inventário',
    'Perda',
    'Quebra',
    'Devolução',
    'Erro de Lançamento',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      setores.value = await _setorRepo.listarTodos();
      familias.value = await _familiaRepo.listarTodas();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    }
  }

  Future<void> pesquisar() async {
    try {
      List<ProdutoModel> resultado;

      if (familiaSelecionada.value != null) {
        resultado = await _produtoRepo.listarPorFamilia(
          familiaSelecionada.value!.id!,
        );
      } else if (setorSelecionado.value != null) {
        resultado = await _produtoRepo.listarPorSetor(
          setorSelecionado.value!.id!,
        );
      } else {
        resultado = await _produtoRepo.listarTodos();
      }

      // Filtrar por nome se houver pesquisa
      if (produtoController.text.isNotEmpty) {
        final pesquisa = produtoController.text.toLowerCase();
        resultado = resultado
            .where(
              (p) =>
                  p.nome.toLowerCase().contains(pesquisa) ||
                  p.codigo.toLowerCase().contains(pesquisa) ||
                  (p.familiaNome?.toLowerCase().contains(pesquisa) ?? false),
            )
            .toList();
      }

      // Apenas produtos contáveis
      produtos.value = resultado.where((p) => p.contavel).toList();

      // Limpar alterações anteriores
      alteracoes.clear();
      motivos.clear();
      produtosSelecionados.clear();
      selecionarTodos.value = false;
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar: $e');
    }
  }

  Future<void> guardarAlteracoes() async {
    if (alteracoes.isEmpty) {
      Get.snackbar('Atenção', 'Nenhuma alteração para guardar');
      return;
    }

    try {
      int totalSalvo = 0;

      // Para cada produto com alteração, registrar o acerto
      for (var entry in alteracoes.entries) {
        final produtoId = entry.key;
        final novoEstoque = entry.value;

        // Usar motivo selecionado ou padrão "Acerto Manual"
        var motivo = motivos[produtoId] ?? 'Acerto Manual';
        if (motivo == '-' || motivo.isEmpty) {
          motivo = 'Acerto Manual';
        }

        // Registrar acerto (trigger automático atualizará o estoque)
        await _acertoRepo.registrarAcerto(
          produtoId: produtoId,
          estoqueNovo: novoEstoque,
          motivo: motivo,
          observacao: null,
          usuario: 'Admin', // TODO: Pegar usuário logado
        );

        totalSalvo++;
      }

      Get.snackbar(
        'Sucesso',
        '$totalSalvo alterações guardadas com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Recarregar produtos
      await pesquisar();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao guardar alterações: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void zerarQuantidades() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
          produtosSelecionados.isEmpty
              ? 'Deseja zerar as quantidades de TODOS os produtos?'
              : 'Deseja zerar as quantidades dos ${produtosSelecionados.length} produtos selecionados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();

              final produtosParaZerar = produtosSelecionados.isEmpty
                  ? produtos.map((p) => p.id!).toList()
                  : produtosSelecionados.toList();

              for (var produtoId in produtosParaZerar) {
                alteracoes[produtoId] = 0;
                if (!motivos.containsKey(produtoId)) {
                  motivos[produtoId] = '-';
                }
              }

              Get.snackbar(
                'Info',
                '${produtosParaZerar.length} produtos marcados para zerar',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('ZERAR'),
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
          _buildFiltros(),
          Expanded(
            child: Obx(
              () => produtos.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum produto para exibir. Use PESQUISAR para carregar.',
                      ),
                    )
                  : _buildTabela(),
            ),
          ),
          _buildRodape(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Campo PRODUTO
          SizedBox(
            width: 250,
            child: TextField(
              controller: produtoController,
              decoration: const InputDecoration(
                labelText: 'PRODUTO',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Dropdown FAMÍLIA
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<FamiliaModel>(
                value: familiaSelecionada.value,
                decoration: const InputDecoration(
                  labelText: 'FAMÍLIA',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: familias
                    .map(
                      (familia) => DropdownMenuItem(
                        value: familia,
                        child: Text(familia.nome),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  familiaSelecionada.value = value;
                  // Limpar setor se família for selecionada
                  if (value != null) {
                    setorSelecionado.value = null;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Dropdown SECTOR
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<SetorModel>(
                value: setorSelecionado.value,
                decoration: const InputDecoration(
                  labelText: 'SECTOR',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: setores
                    .map(
                      (setor) => DropdownMenuItem(
                        value: setor,
                        child: Text(setor.nome),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setorSelecionado.value = value;
                  // Limpar família se setor for selecionado
                  if (value != null) {
                    familiaSelecionada.value = null;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Botão PESQUISAR
          ElevatedButton(
            onPressed: pesquisar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
            child: const Text('PESQUISAR', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 16),

          // Botão GUARDAR
          Obx(
            () => ElevatedButton(
              onPressed: alteracoes.isEmpty ? null : guardarAlteracoes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                'GUARDAR\nALTERAÇÕES\nINTRODUZIDAS',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela() {
    return Column(
      children: [
        // Cabeçalho
        Container(
          color: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Obx(
                  () => Checkbox(
                    value: selecionarTodos.value,
                    onChanged: (_) => toggleSelecionarTodos(),
                    tristate: false,
                  ),
                ),
              ),
              _buildCabecalho('ID', flex: 1),
              _buildCabecalho('DESIGNAÇÃO', flex: 3),
              _buildCabecalho('CLASSE', flex: 2),
              _buildCabecalho('QUANT', flex: 1),
              _buildCabecalho('Q.REAL', flex: 1),
              _buildCabecalho('MOTIVO', flex: 2),
              _buildCabecalho('ÁREA', flex: 1),
              _buildCabecalho('V', flex: 1),
            ],
          ),
        ),
        // Linhas
        Expanded(
          child: Obx(
            () => ListView.builder(
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index];
                return _buildLinha(produto, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho(String texto, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLinha(ProdutoModel produto, int index) {
    final produtoId = produto.id!;

    // Cor de fundo alternada (amarelo/branco como na imagem)
    Color corFundo;
    if (produtosSelecionados.contains(produtoId)) {
      corFundo = Colors.blue[50]!;
    } else if (index % 2 == 0) {
      corFundo = Colors.yellow[100]!;
    } else {
      corFundo = Colors.white;
    }

    return Obx(
      () => Container(
        color: corFundo,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: produtosSelecionados.contains(produtoId),
                onChanged: (_) => toggleProduto(produtoId),
              ),
            ),
            _buildCelula(produto.id.toString(), flex: 1),
            _buildCelula(produto.nome, flex: 3, align: TextAlign.left),
            _buildCelula(produto.familiaNome ?? '-', flex: 2),
            // QUANT - somente leitura, fundo amarelo
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[200],
                  border: Border.all(color: Colors.grey),
                ),
                child: Text(
                  produto.estoque.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Q.REAL - editável
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                  onChanged: (value) {
                    final novoEstoque = int.tryParse(value);
                    if (novoEstoque != null) {
                      alteracoes[produtoId] = novoEstoque;
                      if (!motivos.containsKey(produtoId)) {
                        motivos[produtoId] = '-';
                      }
                    } else {
                      alteracoes.remove(produtoId);
                      motivos.remove(produtoId);
                    }
                  },
                ),
              ),
            ),
            // MOTIVO - dropdown
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: motivos[produtoId] ?? '-',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    items: motivosDisponiveis
                        .map(
                          (motivo) => DropdownMenuItem(
                            value: motivo,
                            child: Text(
                              motivo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        motivos[produtoId] = value;
                      }
                    },
                  ),
                ),
              ),
            ),
            _buildCelula(produto.areaNome ?? '-', flex: 1),
            // Checkbox V
            Expanded(
              flex: 1,
              child: Center(
                child: Checkbox(
                  value: alteracoes.containsKey(produtoId),
                  onChanged: null, // Somente leitura
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelula(
    String texto, {
    int flex = 1,
    TextAlign align = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 10),
          textAlign: align,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              Get.to(() => const ConsultarAcertosTab());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text(
              'CONSULTAR\nACERTOS DE STOCK',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: zerarQuantidades,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text(
              'ZERAR\nQUANTIDADES',
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total de produtos: ${produtos.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (alteracoes.isNotEmpty)
                  Text(
                    'Alterações pendentes: ${alteracoes.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            ),
            child: const Text('VOLTAR', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void toggleSelecionarTodos() {
    selecionarTodos.value = !selecionarTodos.value;
    if (selecionarTodos.value) {
      produtosSelecionados.value = produtos.map((p) => p.id!).toList();
    } else {
      produtosSelecionados.clear();
    }
  }

  void toggleProduto(int produtoId) {
    if (produtosSelecionados.contains(produtoId)) {
      produtosSelecionados.remove(produtoId);
    } else {
      produtosSelecionados.add(produtoId);
    }
    selecionarTodos.value = produtosSelecionados.length == produtos.length;
  }

  @override
  void dispose() {
    produtoController.dispose();
    super.dispose();
  }
}
