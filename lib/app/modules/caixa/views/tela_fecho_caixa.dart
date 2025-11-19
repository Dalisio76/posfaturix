import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/caixa_model.dart';
import '../../../data/models/caixa_detalhe_model.dart';
import '../../../data/models/empresa_model.dart';
import '../../../data/models/conferencia_model.dart';
import '../controllers/caixa_controller.dart';
import '../../../data/repositories/empresa_repository.dart';
import '../../../data/repositories/caixa_repository.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/caixa_printer_service.dart';
import '../widgets/dialog_conferencia_manual.dart';

class TelaFechoCaixa extends StatelessWidget {
  final CaixaController controller = Get.put(CaixaController());
  final TextEditingController observacoesController = TextEditingController();
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  final CaixaRepository _caixaRepo = CaixaRepository();
  final Rx<EmpresaModel?> empresa = Rx<EmpresaModel?>(null);
  final Rx<ConferenciaModel?> conferenciaAtual = Rx<ConferenciaModel?>(null);

  @override
  Widget build(BuildContext context) {
    // Carregar dados do caixa e empresa ao abrir a tela
    _carregarEmpresa();
    _carregarDadosCaixa();

    return Scaffold(
      appBar: AppBar(
        title: Text('FECHO DE CAIXA', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _carregarDadosCaixa(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.caixaAtual.value == null) {
          return _buildNenhumCaixaAberto();
        }

        final caixa = controller.caixaAtual.value!;
        return _buildRelatorioCaixa(context, caixa);
      }),
    );
  }

  /// Carregar dados do caixa com tratamento de erro
  Future<void> _carregarDadosCaixa() async {
    try {
      await controller.verificarCaixaAtual();
      if (controller.caixaAtual.value != null) {
        await controller.carregarDetalhes();
      }
    } catch (e) {
      print('Erro ao carregar dados do caixa: $e');
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildNenhumCaixaAberto() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Nenhum caixa aberto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Abra um novo caixa para começar',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              final sucesso = await controller.abrirCaixa(
                terminal: 'TERMINAL-01',
                usuario: 'Sistema',
              );
              if (sucesso) {
                controller.verificarCaixaAtual();
              }
            },
            icon: Icon(Icons.add),
            label: Text('ABRIR CAIXA'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatorioCaixa(BuildContext context, CaixaModel caixa) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          _buildCabecalho(caixa),
          SizedBox(height: 20),

          // Vendas Pagas
          _buildSecaoVendasPagas(caixa),
          SizedBox(height: 15),

          // Produtos Vendidos
          Obx(() => _buildSecaoProdutosVendidos()),
          SizedBox(height: 15),

          // Formas de Pagamento (só as usadas)
          _buildSecaoFormasPagamento(caixa),
          SizedBox(height: 15),

          // Vendas a Crédito
          _buildSecaoVendasCredito(caixa),
          SizedBox(height: 15),

          // Pagamentos de Dívidas
          Obx(() => _buildSecaoDividasPagas(caixa)),
          SizedBox(height: 15),

          // Despesas
          Obx(() => _buildSecaoDespesas(caixa)),
          SizedBox(height: 20),

          // Totais Finais
          _buildTotaisFinais(caixa),
          SizedBox(height: 30),

          // Botões de Ação
          _buildBotoesAcao(context, caixa),
        ],
      ),
    );
  }

  Widget _buildCabecalho(CaixaModel caixa) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CAIXA: ${caixa.numero}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: caixa.status == 'ABERTO' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    caixa.status,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 5),
                Text(
                  'Abertura: ${DateFormat('dd/MM/yyyy HH:mm').format(caixa.dataAbertura)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (caixa.dataFechamento != null) ...[
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    'Fechamento: ${DateFormat('dd/MM/yyyy HH:mm').format(caixa.dataFechamento!)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (caixa.terminal != null) ...[
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.computer, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    'Terminal: ${caixa.terminal}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoVendasPagas(CaixaModel caixa) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'VENDAS PAGAS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            _buildLinha('Total de Vendas', Formatters.formatarMoeda(caixa.totalVendasPagas)),
            _buildLinha('Quantidade', '${caixa.qtdVendasPagas} vendas'),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoProdutosVendidos() {
    if (controller.produtosVendidos.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'PRODUTOS VENDIDOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            ...controller.produtosVendidos.map((produto) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      produto.produtoNome,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${produto.quantidadeTotal}x',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  Text(
                    Formatters.formatarMoeda(produto.subtotalTotal),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Get.theme.primaryColor),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoFormasPagamento(CaixaModel caixa) {
    // Criar lista de formas usadas (valor > 0)
    final formasUsadas = <Map<String, dynamic>>[];

    if (caixa.totalCash > 0) {
      formasUsadas.add({'nome': 'CASH', 'total': caixa.totalCash, 'qtd': caixa.qtdTransacoesCash});
    }
    if (caixa.totalEmola > 0) {
      formasUsadas.add({'nome': 'EMOLA', 'total': caixa.totalEmola, 'qtd': caixa.qtdTransacoesEmola});
    }
    if (caixa.totalMpesa > 0) {
      formasUsadas.add({'nome': 'MPESA', 'total': caixa.totalMpesa, 'qtd': caixa.qtdTransacoesMpesa});
    }
    if (caixa.totalPos > 0) {
      formasUsadas.add({'nome': 'POS', 'total': caixa.totalPos, 'qtd': caixa.qtdTransacoesPos});
    }

    if (formasUsadas.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'FORMAS DE PAGAMENTO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            ...formasUsadas.map((forma) => _buildLinhaFormaPagamento(
              forma['nome'],
              forma['total'],
              forma['qtd'],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaFormaPagamento(String forma, double total, int qtd) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCorFormaPagamento(forma),
                ),
              ),
              SizedBox(width: 8),
              Text(forma, style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text('($qtd)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Text(
            Formatters.formatarMoeda(total),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getCorFormaPagamento(String forma) {
    switch (forma) {
      case 'CASH':
        return Colors.green;
      case 'EMOLA':
        return Colors.orange;
      case 'MPESA':
        return Colors.red;
      case 'POS':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSecaoVendasCredito(CaixaModel caixa) {
    if (caixa.totalVendasCredito == 0) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'VENDAS A CRÉDITO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '(não entram no saldo)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Divider(),
            _buildLinha('Total a Receber', Formatters.formatarMoeda(caixa.totalVendasCredito)),
            _buildLinha('Quantidade', '${caixa.qtdVendasCredito} vendas'),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoDividasPagas(CaixaModel caixa) {
    if (controller.pagamentosDividas.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'PAGAMENTOS DE DÍVIDAS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            _buildLinha('Total Recebido', Formatters.formatarMoeda(caixa.totalDividasPagas)),
            _buildLinha('Quantidade', '${caixa.qtdDividasPagas} pagamentos'),
            SizedBox(height: 10),
            Text(
              'DETALHES:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            ...controller.pagamentosDividas.map((pag) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pag.clienteNome,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        Formatters.formatarMoeda(pag.valor),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  Text(
                    '${pag.formaPagamento} • ${DateFormat('dd/MM HH:mm').format(pag.dataPagamento)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (pag.observacoes != null && pag.observacoes!.isNotEmpty)
                    Text(
                      pag.observacoes!,
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  SizedBox(height: 4),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoDespesas(CaixaModel caixa) {
    if (controller.despesas.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.money_off, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'DESPESAS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            _buildLinha('Total de Despesas', Formatters.formatarMoeda(caixa.totalDespesas)),
            _buildLinha('Quantidade', '${caixa.qtdDespesas} despesas'),
            SizedBox(height: 10),
            Text(
              'DETALHES:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            ...controller.despesas.map((desp) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          desp.descricao,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        Formatters.formatarMoeda(desp.valor),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd/MM HH:mm').format(desp.dataDespesa),
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (desp.observacoes != null && desp.observacoes!.isNotEmpty)
                    Text(
                      desp.observacoes!,
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  SizedBox(height: 4),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotaisFinais(CaixaModel caixa) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESUMO FINANCEIRO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 2),
            _buildLinhaTotal('Total de Entradas', caixa.totalEntradas, Colors.green),
            SizedBox(height: 8),
            _buildLinhaTotal('Total de Saídas', caixa.totalSaidas, Colors.red),
            SizedBox(height: 8),
            Divider(thickness: 2),
            _buildLinhaTotal(
              'SALDO FINAL',
              caixa.saldoFinal,
              caixa.saldoFinal >= 0 ? Colors.green : Colors.red,
              isBold: true,
              fontSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinha(String label, String valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(valor, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLinhaTotal(String label, double valor, Color cor,
      {bool isBold = false, double fontSize = 16}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          Formatters.formatarMoeda(valor),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildBotoesAcao(BuildContext context, CaixaModel caixa) {
    return Column(
      children: [
        // Botão Imprimir
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _imprimirRelatorio(caixa);
            },
            icon: Icon(Icons.print, size: 20),
            label: Text('IMPRIMIR RELATÓRIO', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(16),
            ),
          ),
        ),
        SizedBox(height: 10),
        // Botão Fechar Caixa
        if (caixa.status == 'ABERTO')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _mostrarDialogFecharCaixa(context, caixa);
              },
              icon: Icon(Icons.lock, size: 20),
              label: Text('FECHAR CAIXA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(18),
              ),
            ),
          ),
      ],
    );
  }

  /// FASE 1: Novo fluxo de fechamento com conferência manual
  void _mostrarDialogFecharCaixa(BuildContext context, CaixaModel caixa) async {
    // PASSO 0: Confirmação simples antes de continuar
    final confirmar = await Get.defaultDialog<bool>(
      title: 'FECHAR CAIXA',
      titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
          SizedBox(height: 20),
          Text(
            'Tem certeza que deseja fechar o caixa?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Saldo Atual:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 5),
                Text(
                  Formatters.formatarMoeda(caixa.saldoFinal),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      textCancel: 'NÃO',
      textConfirm: 'SIM, FECHAR',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.grey[700],
      buttonColor: Colors.red,
      onCancel: () => Get.back(result: false),
      onConfirm: () => Get.back(result: true),
    );

    if (confirmar != true) {
      // Usuário cancelou
      return;
    }

    observacoesController.clear();

    // PASSO 1: Mostrar dialog de conferência manual
    final resultadoConferencia = await Get.dialog<Map<String, dynamic>>(
      DialogConferenciaManual(caixa: caixa),
      barrierDismissible: false,
    );

    if (resultadoConferencia == null || resultadoConferencia['conferido'] != true) {
      // Usuário cancelou na conferência
      return;
    }

    // PASSO 2: Registrar conferência no banco
    try {
      final valores = resultadoConferencia['valores'] as Map<String, dynamic>;
      final observacoes = resultadoConferencia['observacoes'] as String?;

      // Registrar conferência
      await _caixaRepo.registrarConferencia(
        caixaId: caixa.id!,
        contadoCash: valores['cash']['digitado'] ?? 0.0,
        contadoEmola: valores['emola']['digitado'] ?? 0.0,
        contadoMpesa: valores['mpesa']['digitado'] ?? 0.0,
        contadoPos: valores['pos']['digitado'] ?? 0.0,
        observacoes: observacoes,
      );

      // Buscar conferência registrada
      conferenciaAtual.value = await _caixaRepo.buscarConferencia(caixa.id!);

      // PASSO 3: Fechar o caixa
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final resultado = await controller.fecharCaixa(
        observacoes: observacoes,
      );

      Get.back(); // Fechar loading

      if (resultado != null) {
        // PASSO 4: Mostrar resultado e imprimir
        Get.defaultDialog(
          title: 'CAIXA FECHADO',
          barrierDismissible: false,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 20),
              Text(
                'Caixa ${resultado['numero_caixa']} fechado com sucesso!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Saldo Final: ${Formatters.formatarMoeda(resultado['saldo_final'])}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              if (conferenciaAtual.value != null && conferenciaAtual.value!.diferencaTotal != 0) ...[
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'Diferença na conferência: ${Formatters.formatarMoeda(conferenciaAtual.value!.diferencaTotal)}',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ],
          ),
          textConfirm: 'IMPRIMIR RELATÓRIO',
          textCancel: 'FECHAR SEM IMPRIMIR',
          confirmTextColor: Colors.white,
          cancelTextColor: Colors.grey,
          onConfirm: () async {
            Get.back(); // Fechar dialog
            await _imprimirRelatorioComConferencia(caixa);
            _finalizarEFecharSistema();
          },
          onCancel: () {
            _finalizarEFecharSistema();
          },
        );
      }
    } catch (e) {
      Get.back(); // Fechar qualquer dialog aberto
      Get.snackbar(
        'Erro',
        'Erro ao fechar caixa: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// FASE 1: Imprimir relatório com dados de conferência
  Future<void> _imprimirRelatorioComConferencia(CaixaModel caixa) async {
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Recarregar dados do caixa para ter os valores atualizados
      final caixaAtualizado = await _caixaRepo.buscarResumo(caixa.id!);

      final sucesso = await CaixaPrinterService.imprimirFechoCaixaComConferencia(
        caixaAtualizado ?? caixa,
        empresa.value,
        controller.despesas,
        controller.pagamentosDividas,
        controller.produtosVendidos,
        conferenciaAtual.value, // Passar conferência
      );

      Get.back(); // Fechar loading

      if (sucesso) {
        Get.snackbar(
          'Sucesso',
          'Relatório impresso com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Aviso',
          'Erro ao imprimir relatório.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.back();
      print('Erro ao imprimir relatório: $e');
    }
  }

  /// FASE 1: Finalizar e fechar sistema
  void _finalizarEFecharSistema() {
    Get.defaultDialog(
      title: 'ENCERRANDO SISTEMA',
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('O sistema será encerrado em 3 segundos...'),
        ],
      ),
    );

    Future.delayed(Duration(seconds: 3), () {
      exit(0); // Fechar aplicação
    });
  }

  Future<void> _carregarEmpresa() async {
    try {
      empresa.value = await _empresaRepo.buscarDados();
    } catch (e) {
      print('Erro ao carregar empresa: $e');
    }
  }

  Future<void> _imprimirRelatorio(CaixaModel caixa) async {
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final sucesso = await CaixaPrinterService.imprimirFechoCaixa(
        caixa,
        empresa.value,
        controller.despesas,
        controller.pagamentosDividas,
        controller.produtosVendidos,
      );

      Get.back(); // Fechar dialog de loading

      if (sucesso) {
        Get.snackbar(
          'Sucesso',
          'Relatório impresso com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Erro ao imprimir relatório. Verifique a impressora.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Fechar dialog de loading
      Get.snackbar(
        'Erro',
        'Erro ao imprimir: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
