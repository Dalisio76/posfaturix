import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/venda_model.dart';
import '../../../data/models/item_venda_model.dart';
import '../../../data/models/pagamento_venda_model.dart';
import '../../../data/repositories/venda_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/formatters.dart';

class TodasVendasController extends GetxController {
  final VendaRepository _vendaRepo = VendaRepository();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<VendaModel> vendas = <VendaModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filtroStatus = 'todas'.obs; // 'todas', 'finalizada', 'cancelada'
  final Rx<DateTime?> dataInicio = Rx<DateTime?>(null);
  final Rx<DateTime?> dataFim = Rx<DateTime?>(null);
  final RxString filtroNumero = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Inicializar com últimos 30 dias
    final hoje = DateTime.now();
    dataInicio.value = DateTime(hoje.year, hoje.month, hoje.day - 30);
    dataFim.value = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    carregarVendas();
  }

  Future<void> carregarVendas() async {
    try {
      isLoading.value = true;

      final status = filtroStatus.value == 'todas' ? null : filtroStatus.value;

      final resultado = await _vendaRepo.listarTodasVendas(
        dataInicio: dataInicio.value,
        dataFim: dataFim.value,
        status: status,
        numeroFiltro: filtroNumero.value.isEmpty ? null : filtroNumero.value,
      );

      vendas.value = resultado;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar vendas: $e',
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selecionarDataInicio(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicio.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
    );

    if (data != null) {
      dataInicio.value = DateTime(data.year, data.month, data.day, 0, 0, 0);
      carregarVendas();
    }
  }

  Future<void> selecionarDataFim(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataFim.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
    );

    if (data != null) {
      dataFim.value = DateTime(data.year, data.month, data.day, 23, 59, 59);
      carregarVendas();
    }
  }

  void aplicarFiltroStatus(String status) {
    filtroStatus.value = status;
    carregarVendas();
  }

  void aplicarFiltroNumero(String numero) {
    filtroNumero.value = numero;
    carregarVendas();
  }

  Future<void> mostrarDetalhesVenda(VendaModel venda) async {
    try {
      // Carregar itens e pagamentos
      final itens = await _vendaRepo.listarItensVenda(venda.id!);
      final pagamentos = await _vendaRepo.listarPagamentosVenda(venda.id!);

      Get.dialog(
        _DialogDetalhesVenda(
          venda: venda,
          itens: itens,
          pagamentos: pagamentos,
          onCancelar: () => _confirmarCancelamento(venda),
        ),
        barrierDismissible: true,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar detalhes: $e',
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    }
  }

  Future<void> _confirmarCancelamento(VendaModel venda) async {
    if (venda.isCancelada) {
      Get.snackbar(
        'Aviso',
        'Esta venda já está cancelada',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Cancelar Venda?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja CANCELAR esta venda?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Venda: ${venda.numeroExibicao}'),
            Text('Total: ${_formatarMoeda(venda.total)}'),
            Text('Data: ${_formatarData(venda.dataVenda)}'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.orange[800]),
                      SizedBox(width: 8),
                      Text(
                        'Esta ação irá:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Marcar a venda como cancelada'),
                  Text('• Restaurar o estoque dos produtos'),
                  Text('• Registrar no histórico de auditoria'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'NÃO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'SIM, CANCELAR VENDA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _executarCancelamento(venda);
    }
  }

  Future<void> _executarCancelamento(VendaModel venda) async {
    try {
      Get.dialog(
        Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cancelando venda...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final usuarioId = _authService.usuarioLogado.value?.id;
      if (usuarioId == null) {
        throw Exception('Usuário não identificado');
      }

      await _vendaRepo.cancelarVenda(venda.id!, usuarioId);

      Get.back(); // Fechar loading
      Get.back(); // Fechar dialog de detalhes

      Get.snackbar(
        'Sucesso',
        'Venda ${venda.numeroExibicao} cancelada com sucesso!',
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
      );

      // Recarregar lista
      carregarVendas();
    } catch (e) {
      Get.back(); // Fechar loading

      Get.snackbar(
        'Erro',
        'Erro ao cancelar venda: $e',
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }
  }

  String _formatarMoeda(double valor) {
    return Formatters.formatarMoeda(valor);
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }
}

// ==========================================
// DIALOG DE DETALHES DA VENDA
// ==========================================
class _DialogDetalhesVenda extends StatelessWidget {
  final VendaModel venda;
  final List<ItemVendaModel> itens;
  final List<PagamentoVendaModel> pagamentos;
  final VoidCallback onCancelar;

  const _DialogDetalhesVenda({
    required this.venda,
    required this.itens,
    required this.pagamentos,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: venda.isCancelada ? Colors.red[700] : Get.theme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    venda.isCancelada ? Icons.cancel : Icons.receipt_long,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venda ${venda.numeroExibicao}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          venda.isCancelada ? 'CANCELADA' : 'FINALIZADA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações da venda
                    _buildInfoSection(),
                    SizedBox(height: 24),

                    // Produtos
                    _buildProdutosSection(),
                    SizedBox(height: 24),

                    // Pagamentos
                    _buildPagamentosSection(),
                  ],
                ),
              ),
            ),

            // Footer com botões
            if (!venda.isCancelada) ...[
              Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('FECHAR', style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onCancelar,
                      icon: Icon(Icons.cancel),
                      label: Text('CANCELAR VENDA', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Data/Hora', _formatarData(venda.dataVenda)),
          _buildInfoRow('Terminal', venda.terminal ?? 'N/A'),
          _buildInfoRow('Cliente', venda.clienteNome ?? 'Venda direta'),
          _buildInfoRow('Usuário', venda.usuarioNome ?? 'N/A'),
          if (venda.observacoes != null && venda.observacoes!.isNotEmpty)
            _buildInfoRow('Observações', venda.observacoes!, maxLines: 3),
          Divider(height: 24),
          _buildInfoRow(
            'TOTAL',
            _formatarMoeda(venda.total),
            isBold: true,
            fontSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor, {bool isBold = false, int maxLines = 1, double? fontSize}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: fontSize ?? 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize ?? 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUTOS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Qtd', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Preço Un.', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // Itens
              ...itens.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index.isEven ? Colors.white : Colors.grey[50],
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(item.produtoNome ?? 'Produto #${item.produtoId}')),
                      Expanded(flex: 1, child: Text('${item.quantidade}', textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text(_formatarMoeda(item.precoUnitario), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text(_formatarMoeda(item.subtotal), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagamentosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAGAMENTOS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        ...pagamentos.map((pagamento) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: Colors.green[700], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pagamento.formaPagamentoNome ?? 'Forma de pagamento #${pagamento.formaPagamentoId}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  _formatarMoeda(pagamento.valor),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[900]),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatarMoeda(double valor) {
    return Formatters.formatarMoeda(valor);
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }
}
