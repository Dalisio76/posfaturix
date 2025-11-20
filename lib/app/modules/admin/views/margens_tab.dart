import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/relatorios_repository.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/repositories/empresa_repository.dart';
import '../../../data/models/setor_model.dart';
import '../../../data/models/empresa_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/margens_printer_service.dart';

class MargensTab extends StatefulWidget {
  const MargensTab({Key? key}) : super(key: key);

  @override
  _MargensTabState createState() => _MargensTabState();
}

class _MargensTabState extends State<MargensTab> {
  final RelatoriosRepository _repo = RelatoriosRepository();
  final SetorRepository _setorRepo = Get.put(SetorRepository());
  final EmpresaRepository _empresaRepo = Get.put(EmpresaRepository());

  final RxList<DateTime> datasAberturas = <DateTime>[].obs;
  final RxList<DateTime> datasFechos = <DateTime>[].obs;
  final Rxn<DateTime> dataAberturaSelecionada = Rxn<DateTime>();
  final Rxn<DateTime> dataFechoSelecionado = Rxn<DateTime>();

  final RxList<Map<String, dynamic>> margens = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> resumo = Rxn<Map<String, dynamic>>();

  final RxList<SetorModel> setores = <SetorModel>[].obs;
  final Rxn<SetorModel> setorSelecionado = Rxn<SetorModel>();

  final Rxn<EmpresaModel> empresa = Rxn<EmpresaModel>();

  final TextEditingController produtoController = TextEditingController();

  final RxList<int> produtosSelecionados = <int>[].obs;
  final RxBool selecionarTodos = false.obs;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    await carregarEmpresa();
    await carregarSetores();
    await carregarCaixas();
  }

  Future<void> carregarEmpresa() async {
    empresa.value = await _empresaRepo.buscarDados();
  }

  Future<void> carregarSetores() async {
    final result = await _setorRepo.listarTodos();
    setores.value = result;
  }

  Future<void> carregarCaixas() async {
    try {
      final caixas = await _repo.listarTodasCaixas();

      // Extrair datas de abertura
      Set<DateTime> aberturasSet = {};
      Set<DateTime> fechosSet = {};

      for (var caixa in caixas) {
        if (caixa.dataAbertura != null) {
          aberturasSet.add(caixa.dataAbertura!);
        }
        if (caixa.dataFechamento != null) {
          fechosSet.add(caixa.dataFechamento!);
        }
      }

      datasAberturas.value = aberturasSet.toList()
        ..sort((a, b) => b.compareTo(a));
      datasFechos.value = fechosSet.toList()..sort((a, b) => b.compareTo(a));

      // Selecionar primeira data de abertura e última de fecho por padrão
      if (datasAberturas.isNotEmpty) {
        dataAberturaSelecionada.value = datasAberturas.last;
      }
      if (datasFechos.isNotEmpty) {
        dataFechoSelecionado.value = datasFechos.first;
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar caixas: $e');
    }
  }

  Future<void> pesquisarMargens() async {
    if (dataAberturaSelecionada.value == null ||
        dataFechoSelecionado.value == null) {
      Get.snackbar('Atenção', 'Selecione as datas de abertura e fecho');
      return;
    }

    try {
      final resultado = await _repo.buscarMargensPorPeriodo(
        dataInicio: dataAberturaSelecionada.value!,
        dataFim: dataFechoSelecionado.value!,
        produtoNome: produtoController.text.isEmpty
            ? null
            : produtoController.text,
        setorId: setorSelecionado.value?.id,
      );

      final resumoData = await _repo.buscarResumoMargens(
        dataInicio: dataAberturaSelecionada.value!,
        dataFim: dataFechoSelecionado.value!,
        produtoNome: produtoController.text.isEmpty
            ? null
            : produtoController.text,
        setorId: setorSelecionado.value?.id,
      );

      margens.value = resultado;
      resumo.value = resumoData;
      produtosSelecionados.clear();
      selecionarTodos.value = false;
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar margens: $e');
    }
  }

  void toggleSelecionarTodos() {
    selecionarTodos.value = !selecionarTodos.value;
    if (selecionarTodos.value) {
      produtosSelecionados.value = margens
          .map((m) => m['produto_id'] as int)
          .toList();
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
    selecionarTodos.value = produtosSelecionados.length == margens.length;
  }

  Future<void> imprimirRelatorio() async {
    if (margens.isEmpty || resumo.value == null) {
      Get.snackbar('Atenção', 'Nenhum dado para imprimir');
      return;
    }

    try {
      final sucesso = await MargensPrinterService.imprimirRelatorio(
        empresa: empresa.value,
        dataInicio: dataAberturaSelecionada.value!,
        dataFim: dataFechoSelecionado.value!,
        margens: margens,
        resumo: resumo.value!,
        setor: setorSelecionado.value?.nome,
      );

      if (sucesso) {
        Get.snackbar(
          'Sucesso',
          'Relatório impresso com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Falha ao imprimir relatório',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao imprimir: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> imprimirResumo() async {
    if (resumo.value == null) {
      Get.snackbar('Atenção', 'Nenhum dado para imprimir');
      return;
    }

    try {
      final sucesso = await MargensPrinterService.imprimirResumo(
        empresa: empresa.value,
        dataInicio: dataAberturaSelecionada.value!,
        dataFim: dataFechoSelecionado.value!,
        resumo: resumo.value!,
        setor: setorSelecionado.value?.nome,
      );

      if (sucesso) {
        Get.snackbar(
          'Sucesso',
          'Resumo impresso com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Falha ao imprimir resumo',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao imprimir: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: Obx(
              () => margens.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum dado para exibir. Use os filtros acima para pesquisar.',
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
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
              Expanded(
                flex: 2,
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
                    onChanged: (value) => setorSelecionado.value = value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<DateTime>(
                    value: dataAberturaSelecionada.value,
                    decoration: const InputDecoration(
                      labelText: 'VENDAS DE',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: datasAberturas
                        .map(
                          (data) => DropdownMenuItem(
                            value: data,
                            child: Text(
                              DateFormat('M/d/yyyy h:mm a').format(data),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => dataAberturaSelecionada.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<DateTime>(
                    value: dataFechoSelecionado.value,
                    decoration: const InputDecoration(
                      labelText: 'ATÉ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: datasFechos
                        .map(
                          (data) => DropdownMenuItem(
                            value: data,
                            child: Text(
                              DateFormat('M/d/yyyy h:mm a').format(data),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => dataFechoSelecionado.value = value,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: pesquisarMargens,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                ),
                child: const Text('PESQUISAR', style: TextStyle(fontSize: 16)),
              ),
            ],
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
              _buildCabecalho('QUANT', flex: 1),
              _buildCabecalho('VALOR', flex: 2),
              _buildCabecalho('COMPRA', flex: 2),
              _buildCabecalho('LUCRO', flex: 2),
              _buildCabecalho('%', flex: 1),
              _buildCabecalho('SECTOR', flex: 2),
            ],
          ),
        ),
        // Linhas
        Expanded(
          child: ListView.builder(
            itemCount: margens.length,
            itemBuilder: (context, index) {
              final margem = margens[index];
              return _buildLinha(margem, index);
            },
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLinha(Map<String, dynamic> margem, int index) {
    final produtoId = margem['produto_id'] as int;
    final quantidade =
        double.tryParse(margem['quantidade']?.toString() ?? '0') ?? 0.0;
    final valor = double.tryParse(margem['valor']?.toString() ?? '0') ?? 0.0;
    final compra = double.tryParse(margem['compra']?.toString() ?? '0') ?? 0.0;
    final lucro = double.tryParse(margem['lucro']?.toString() ?? '0') ?? 0.0;
    final percentagem =
        double.tryParse(margem['percentagem']?.toString() ?? '0') ?? 0.0;

    final corFundo = index % 2 == 0 ? Colors.white : Colors.grey[50];
    final corLucro = lucro >= 0 ? Colors.black : Colors.red;

    return Obx(
      () => Container(
        color: produtosSelecionados.contains(produtoId)
            ? Colors.blue[50]
            : corFundo,
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
            _buildCelula(margem['produto_id'].toString(), flex: 1),
            _buildCelula(
              margem['designacao']?.toString() ?? '',
              flex: 3,
              align: TextAlign.left,
            ),
            _buildCelula(quantidade.toStringAsFixed(2), flex: 1),
            _buildCelula(Formatters.formatarMoeda(valor), flex: 2),
            _buildCelula(Formatters.formatarMoeda(compra), flex: 2),
            _buildCelula(
              Formatters.formatarMoeda(lucro),
              flex: 2,
              cor: corLucro,
            ),
            _buildCelula(percentagem.toStringAsFixed(2), flex: 1),
            _buildCelula(margem['setor']?.toString() ?? '', flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildCelula(
    String texto, {
    int flex = 1,
    TextAlign align = TextAlign.center,
    Color? cor,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          texto,
          style: TextStyle(fontSize: 11, color: cor),
          textAlign: align,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Obx(() {
      if (resumo.value == null) return const SizedBox.shrink();

      final totalVendas =
          double.tryParse(resumo.value!['total_vendas']?.toString() ?? '0') ??
          0.0;
      final totalCompra =
          double.tryParse(resumo.value!['total_compra']?.toString() ?? '0') ??
          0.0;
      final totalLucro =
          double.tryParse(resumo.value!['total_lucro']?.toString() ?? '0') ??
          0.0;
      final percentagemTotal =
          double.tryParse(
            resumo.value!['percentagem_total']?.toString() ?? '0',
          ) ??
          0.0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: margens.isEmpty ? null : imprimirRelatorio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'IMPRIMIR\nRELATORIO',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: margens.isEmpty ? null : imprimirResumo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'IMPRIMIR\nRESUMO',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildResumoLinha('VENDAS', totalVendas),
                const SizedBox(height: 4),
                _buildResumoLinha('COMPRA', totalCompra),
                const SizedBox(height: 4),
                _buildResumoLinha(
                  'LUCRO',
                  totalLucro,
                  cor: totalLucro >= 0 ? Colors.black : Colors.red,
                ),
                const SizedBox(height: 4),
                _buildResumoLinha('%', percentagemTotal, isSufixo: false),
              ],
            ),
            const SizedBox(width: 32),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
              ),
              child: const Text('VOLTAR', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResumoLinha(
    String label,
    double valor, {
    Color? cor,
    bool isSufixo = true,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: Text(
            isSufixo
                ? Formatters.formatarMoeda(valor)
                : valor.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    produtoController.dispose();
    super.dispose();
  }
}
