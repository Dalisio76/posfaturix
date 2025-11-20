import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/relatorio_vendas_printer_service.dart';
import '../../../data/models/caixa_model.dart';
import '../../../data/repositories/relatorios_repository.dart';
import '../controllers/admin_controller.dart';

class RelatoriosTab extends GetView<AdminController> {
  const RelatoriosTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _abrirDrawerRelatorios(context),
          icon: Icon(Icons.analytics, size: 32),
          label: Text(
            'ABRIR RELATÓRIOS',
            style: TextStyle(fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
        ),
      ),
    );
  }

  void _abrirDrawerRelatorios(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Relatórios',
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return RelatoriosDrawer();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }
}

class RelatoriosDrawer extends StatefulWidget {
  const RelatoriosDrawer({Key? key}) : super(key: key);

  @override
  _RelatoriosDrawerState createState() => _RelatoriosDrawerState();
}

class _RelatoriosDrawerState extends State<RelatoriosDrawer> {
  final RelatoriosRepository _repo = RelatoriosRepository();
  final AdminController controller = Get.find<AdminController>();

  // Listas de caixas
  final RxList<CaixaModel> caixasAbertas = <CaixaModel>[].obs;
  final RxList<CaixaModel> caixasFechadas = <CaixaModel>[].obs;
  final RxBool isLoading = true.obs;

  // Caixa selecionada
  final Rxn<CaixaModel> caixaSelecionada = Rxn<CaixaModel>();

  // Dados do relatório de período
  final Rxn<Map<String, dynamic>> dadosRelatorio = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> produtosVendidos = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, List<Map<String, dynamic>>>> produtosPorFamilia = Rx<Map<String, List<Map<String, dynamic>>>>({});

  // Listas de datas de aberturas e fechos
  final RxList<DateTime> datasAberturas = <DateTime>[].obs;
  final RxList<DateTime> datasFechos = <DateTime>[].obs;

  // Filtros
  final Rxn<int> setorSelecionado = Rxn<int>();
  final Rxn<int> areaSelecionada = Rxn<int>();
  final Rxn<DateTime> dataAberturaSelecionada = Rxn<DateTime>();
  final Rxn<DateTime> dataFechoSelecionado = Rxn<DateTime>();

  @override
  void initState() {
    super.initState();
    carregarCaixas();
  }

  Future<void> carregarCaixas() async {
    isLoading.value = true;
    try {
      // Carregar todas as caixas
      final todasCaixas = await _repo.listarTodasCaixas();

      caixasAbertas.value = await _repo.listarCaixasAbertas();
      caixasFechadas.value = await _repo.listarCaixasFechadas();

      // Extrair datas únicas de aberturas (ordenadas da mais recente para a mais antiga)
      final aberturasSet = todasCaixas.map((c) => c.dataAbertura).toSet().toList();
      aberturasSet.sort((a, b) => b.compareTo(a)); // Ordem decrescente
      datasAberturas.value = aberturasSet;

      // Extrair datas únicas de fechos (apenas caixas fechadas, ordenadas da mais recente para a mais antiga)
      final fechosSet = todasCaixas
          .where((c) => c.dataFechamento != null)
          .map((c) => c.dataFechamento!)
          .toSet()
          .toList();
      fechosSet.sort((a, b) => b.compareTo(a)); // Ordem decrescente
      datasFechos.value = fechosSet;

    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar caixas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> consultarRelatorio() async {
    if (dataAberturaSelecionada.value == null || dataFechoSelecionado.value == null) {
      Get.snackbar('Atenção', 'Selecione a data de ABERTURA e a data de FECHO');
      return;
    }

    isLoading.value = true;
    try {
      final dataInicio = dataAberturaSelecionada.value!;
      final dataFim = dataFechoSelecionado.value!;

      print('=== CONSULTAR RELATÓRIO POR PERÍODO ===');
      print('Período: ${DateFormat('dd/MM/yyyy HH:mm').format(dataInicio)} até ${DateFormat('dd/MM/yyyy HH:mm').format(dataFim)}');

      // Buscar dados agregados do período
      final dados = await _repo.buscarDadosPorPeriodo(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      // Buscar produtos vendidos no período
      final produtos = await _repo.buscarProdutosPorPeriodo(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      // Buscar produtos agrupados por família (para impressão)
      final produtosFamilia = await _repo.buscarProdutosPorFamiliaPeriodo(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      print('Dados do período recebidos');
      print('Vendas: ${dados['vendas']}');
      print('Produtos: ${produtos.length}');
      print('Famílias: ${produtosFamilia.keys.length}');

      dadosRelatorio.value = dados;
      produtosVendidos.value = produtos;
      produtosPorFamilia.value = produtosFamilia;

      // Limpar seleção de caixa (não usamos mais)
      caixaSelecionada.value = null;

    } catch (e) {
      Get.snackbar('Erro', 'Erro ao gerar relatório: $e');
      print('Erro ao consultar relatório: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filtrarCaixasPorData() async {
    isLoading.value = true;
    try {
      final todasCaixas = await _repo.listarTodasCaixas();

      // Filtrar por data de abertura
      var caixasFiltradas = todasCaixas;
      if (dataAberturaSelecionada.value != null) {
        caixasFiltradas = caixasFiltradas.where((c) {
          return c.dataAbertura.isAtSameMomentAs(dataAberturaSelecionada.value!) ||
                 c.dataAbertura.isAfter(dataAberturaSelecionada.value!);
        }).toList();
      }

      // Filtrar por data de fecho
      if (dataFechoSelecionado.value != null) {
        caixasFiltradas = caixasFiltradas.where((c) {
          if (c.dataFechamento == null) return false;
          return c.dataFechamento!.isAtSameMomentAs(dataFechoSelecionado.value!) ||
                 c.dataFechamento!.isBefore(dataFechoSelecionado.value!);
        }).toList();
      }

      // Separar entre abertas e fechadas
      caixasAbertas.value = caixasFiltradas.where((c) => c.status == 'ABERTO').toList();
      caixasFechadas.value = caixasFiltradas.where((c) => c.status == 'FECHADO').toList();

    } catch (e) {
      Get.snackbar('Erro', 'Erro ao filtrar caixas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> imprimirRelatorio() async {
    if (dadosRelatorio.value == null) {
      Get.snackbar('Atenção', 'Gere o relatório primeiro clicando em CONSULTAR');
      return;
    }

    try {
      Get.snackbar('Impressão', 'Enviando para impressora...', duration: Duration(seconds: 2));

      final sucesso = await RelatorioVendasPrinterService.imprimirRelatorio(
        empresa: controller.empresa.value,
        dataInicio: dataAberturaSelecionada.value!,
        dataFim: dataFechoSelecionado.value!,
        dadosRelatorio: dadosRelatorio.value!,
        produtosPorFamilia: produtosPorFamilia.value,
        setor: setorSelecionado.value != null
            ? controller.setores.firstWhere((s) => s.id == setorSelecionado.value).nome
            : null,
      );

      if (sucesso) {
        Get.snackbar(
          'Sucesso',
          'Relatório enviado para impressora!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Não foi possível imprimir. Verifique se a impressora está conectada.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao imprimir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 16,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(),
              _buildFiltros(),
              Expanded(
                child: Row(
                  children: [
                    // Lista lateral - Aberturas e Fechos
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: _buildListaLateral(),
                    ),

                    // Área central - Relatório
                    Expanded(
                      child: _buildRelatorioArea(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 32, color: Colors.red),
          SizedBox(width: 12),
          Text(
            'RELATÓRIOS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Obx(() => ElevatedButton.icon(
            onPressed: dadosRelatorio.value != null ? imprimirRelatorio : null,
            icon: Icon(Icons.print, size: 20),
            label: Text('IMPRIMIR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )),
          SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Obx(() => Row(
        children: [
          // SETOR
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SECTOR', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: setorSelecionado.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: Text('Todos'),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    ...controller.setores.map((setor) => DropdownMenuItem(
                      value: setor.id,
                      child: Text(setor.nome),
                    )),
                  ],
                  onChanged: (value) {
                    setorSelecionado.value = value;
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 16),

          // ÁREA
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AREA', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: areaSelecionada.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: Text('Todas'),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    ...controller.areas.map((area) => DropdownMenuItem(
                      value: area.id,
                      child: Text(area.nome),
                    )),
                  ],
                  onChanged: (value) {
                    areaSelecionada.value = value;
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 16),

          // DATA ABERTURA
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VENDAS DE', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                DropdownButtonFormField<DateTime>(
                  value: dataAberturaSelecionada.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: Text('Selecionar abertura'),
                  isExpanded: true,
                  items: datasAberturas.map((data) => DropdownMenuItem(
                    value: data,
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(data),
                      style: TextStyle(fontSize: 13),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    dataAberturaSelecionada.value = value;
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 16),

          // DATA FECHO
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ATÉ', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                DropdownButtonFormField<DateTime>(
                  value: dataFechoSelecionado.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: Text('Selecionar fecho'),
                  isExpanded: true,
                  items: datasFechos.map((data) => DropdownMenuItem(
                    value: data,
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(data),
                      style: TextStyle(fontSize: 13),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    dataFechoSelecionado.value = value;
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 16),

          // BOTÃO CONSULTAR
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: ElevatedButton(
              onPressed: consultarRelatorio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                'CONSULTAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildListaLateral() {
    return Obx(() {
      if (isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              indicatorColor: Get.theme.primaryColor,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_open, size: 16),
                      SizedBox(width: 4),
                      Text('Aberturas'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 16),
                      SizedBox(width: 4),
                      Text('Fechos'),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Aberturas (Caixas Abertas)
                  _buildListaCaixas(caixasAbertas, Colors.green),

                  // Fechos (Caixas Fechadas)
                  _buildListaCaixas(caixasFechadas, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildListaCaixas(List<CaixaModel> caixas, Color cor) {
    if (caixas.isEmpty) {
      return Center(
        child: Text(
          'Nenhum registro',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: caixas.length,
      itemBuilder: (context, index) {
        final caixa = caixas[index];
        final isSelected = caixaSelecionada.value?.id == caixa.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? cor.withOpacity(0.1) : null,
          child: ListTile(
            leading: Icon(
              caixa.status == 'ABERTO' ? Icons.lock_open : Icons.lock,
              color: cor,
            ),
            title: Text(
              caixa.numero,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abertura: ${DateFormat('dd/MM/yyyy HH:mm').format(caixa.dataAbertura)}',
                  style: TextStyle(fontSize: 11),
                ),
                if (caixa.dataFechamento != null)
                  Text(
                    'Fecho: ${DateFormat('dd/MM/yyyy HH:mm').format(caixa.dataFechamento!)}',
                    style: TextStyle(fontSize: 11),
                  ),
              ],
            ),
            trailing: Text(
              Formatters.formatarMoeda(caixa.saldoFinal),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            onTap: () {
              caixaSelecionada.value = caixa;
              consultarRelatorio();
            },
          ),
        );
      },
    );
  }

  Widget _buildRelatorioArea() {
    return Obx(() {
      if (dadosRelatorio.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Selecione as datas e clique em CONSULTAR',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      final dados = dadosRelatorio.value!;
      final vendas = dados['vendas'] as Map<String, dynamic>;
      final formasPagamento = dados['formas_pagamento'] as List<Map<String, dynamic>>;
      final dividasPagas = dados['dividas_pagas'] as Map<String, dynamic>;
      final despesas = dados['despesas'] as Map<String, dynamic>;

      // Calcular totais
      final totalVendasPagas = double.tryParse(vendas['total_vendas_pagas']?.toString() ?? '0') ?? 0.0;
      final totalVendasCredito = double.tryParse(vendas['total_vendas_credito']?.toString() ?? '0') ?? 0.0;
      final totalDividasPagas = double.tryParse(dividasPagas['total_dividas_pagas']?.toString() ?? '0') ?? 0.0;
      final totalDespesas = double.tryParse(despesas['total_despesas']?.toString() ?? '0') ?? 0.0;

      final totalPago = totalVendasPagas + totalDividasPagas;
      final emCaixa = totalPago - totalDespesas;

      return SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Center(
                child: Text(
                  'RELATÓRIO DE VENDAS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Período
              _buildLinhaRelatorio(
                'PERÍODO',
                '${DateFormat('dd-MM-yyyy HH:mm:ss').format(dataAberturaSelecionada.value!)} até ${DateFormat('dd-MM-yyyy HH:mm:ss').format(dataFechoSelecionado.value!)}',
              ),
              SizedBox(height: 16),

              // Vendas a crédito e pagamentos
              _buildLinhaRelatorio('EM DIVIDA', Formatters.formatarMoeda(totalVendasCredito)),
              _buildLinhaRelatorio('PAGTO. DIVIDA', Formatters.formatarMoeda(totalDividasPagas)),
              SizedBox(height: 16),

              Divider(color: Colors.black),
              SizedBox(height: 16),

              // Lista de produtos vendidos
              if (produtosVendidos.isNotEmpty) ...[
                ...produtosVendidos.map((produto) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(produto['produto_nome'] ?? '', style: TextStyle(fontSize: 14)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Qtd: ${produto['quantidade_total']}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          Formatters.formatarMoeda(
                            double.tryParse(produto['total_vendido']?.toString() ?? '0') ?? 0,
                          ),
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: 16),
                Divider(color: Colors.black),
                SizedBox(height: 16),
              ],

              // Formas de pagamento
              ...formasPagamento.map((forma) => _buildLinhaRelatorio(
                forma['forma_pagamento']?.toString().toUpperCase() ?? '',
                Formatters.formatarMoeda(double.tryParse(forma['total']?.toString() ?? '0') ?? 0.0),
              )),

              SizedBox(height: 16),
              Divider(color: Colors.black),
              SizedBox(height: 16),

              // Totais
              _buildLinhaRelatorio('TOTAL PAGO', Formatters.formatarMoeda(totalPago), bold: true),
              _buildLinhaRelatorio('DESPESAS', Formatters.formatarMoeda(totalDespesas)),
              _buildLinhaRelatorio('EM CAIXA', Formatters.formatarMoeda(emCaixa), bold: true),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLinhaRelatorio(String label, String valor, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
