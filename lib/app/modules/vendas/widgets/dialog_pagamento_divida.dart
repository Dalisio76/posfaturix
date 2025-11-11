import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/divida_model.dart';
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/repositories/divida_repository.dart';
import '../../../data/repositories/forma_pagamento_repository.dart';
import 'teclado_numerico.dart';

class DialogPagamentoDivida extends StatefulWidget {
  final DividaModel divida;
  final Function()? onPagamentoRealizado;

  const DialogPagamentoDivida({
    Key? key,
    required this.divida,
    this.onPagamentoRealizado,
  }) : super(key: key);

  @override
  State<DialogPagamentoDivida> createState() => _DialogPagamentoDividaState();
}

class _DialogPagamentoDividaState extends State<DialogPagamentoDivida> {
  final RxString valorDigitado = '0'.obs;
  final RxList<FormaPagamentoModel> formasPagamento = <FormaPagamentoModel>[].obs;
  final Rxn<FormaPagamentoModel> formaSelecionada = Rxn<FormaPagamentoModel>();
  final _dividaRepo = DividaRepository();
  final _formaPagamentoRepo = FormaPagamentoRepository();
  final RxBool isLoading = true.obs;
  final RxBool isProcessando = false.obs;
  final observacoesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarFormasPagamento();
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregarFormasPagamento() async {
    isLoading.value = true;
    try {
      formasPagamento.value = await _formaPagamentoRepo.listarTodas();
      if (formasPagamento.isNotEmpty) {
        formaSelecionada.value = formasPagamento[0];
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar formas de pagamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  double get valorAtual {
    return double.tryParse(valorDigitado.value) ?? 0;
  }

  bool get podeRegistrar {
    return valorAtual > 0 &&
           valorAtual <= widget.divida.valorRestante &&
           formaSelecionada.value != null &&
           !isProcessando.value;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 700,
        child: Obx(() => isLoading.value
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Conteúdo
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna esquerda - Formas de pagamento
                        Expanded(
                          flex: 3,
                          child: _buildFormasPagamento(),
                        ),

                        VerticalDivider(width: 1),

                        // Coluna direita - Valor e teclado
                        Expanded(
                          flex: 2,
                          child: _buildTecladoValor(),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  _buildFooter(),
                ],
              )),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGISTRAR PAGAMENTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dívida #${widget.divida.id} - ${widget.divida.clienteNome}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'TOTAL',
                  Formatters.formatarMoeda(widget.divida.valorTotal),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  'PAGO',
                  Formatters.formatarMoeda(widget.divida.valorPago),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  'RESTANTE',
                  Formatters.formatarMoeda(widget.divida.valorRestante),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String valor, IconData icon, Color cor) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: cor),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormasPagamento() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FORMA DE PAGAMENTO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),

          // Grid de formas de pagamento
          Expanded(
            child: Obx(() => GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: formasPagamento.length,
              itemBuilder: (context, index) {
                final forma = formasPagamento[index];
                final selecionada = formaSelecionada.value?.id == forma.id;

                return OutlinedButton(
                  onPressed: () => formaSelecionada.value = forma,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selecionada ? Get.theme.primaryColor : Colors.white,
                    foregroundColor: selecionada ? Colors.white : Colors.black,
                    side: BorderSide(
                      color: selecionada ? Get.theme.primaryColor : Colors.grey[400]!,
                      width: 2,
                    ),
                    padding: EdgeInsets.all(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconeFormaPagamento(forma.nome),
                        size: 20,
                        color: selecionada ? Colors.white : Get.theme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          forma.nome,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )),
          ),

          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 8),

          // Campo de observações
          Text(
            'OBSERVAÇÕES (OPCIONAL)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: observacoesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Pagamento referente à parcela 1/3',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
              hintStyle: TextStyle(fontSize: 12),
            ),
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTecladoValor() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'VALOR A PAGAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),

          // Display do valor
          Obx(() => Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCorValor(),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'MT ${_formatarValor(valorDigitado.value)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.right,
                ),
                if (valorAtual > 0) ...[
                  SizedBox(height: 8),
                  Text(
                    _getMensagemValor(),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getCorMensagem(),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          )),

          SizedBox(height: 16),

          // Atalhos rápidos
          Text(
            'ATALHOS RÁPIDOS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setValor(widget.divida.valorRestante / 2),
                  child: Text('50%', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setValor(widget.divida.valorRestante),
                  child: Text('TOTAL', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Teclado numérico
          Expanded(
            child: TecladoNumerico(
              onNumeroPressed: _adicionarDigito,
              onBackspace: _removerUltimoDigito,
              onClear: _limparValor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isProcessando.value ? null : () => Get.back(),
              icon: Icon(Icons.close),
              label: Text('CANCELAR'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(16),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton.icon(
              onPressed: podeRegistrar ? _registrarPagamento : null,
              icon: isProcessando.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.check_circle),
              label: Text(
                isProcessando.value ? 'PROCESSANDO...' : 'CONFIRMAR PAGAMENTO',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
            )),
          ),
        ],
      ),
    );
  }

  IconData _getIconeFormaPagamento(String nome) {
    switch (nome.toUpperCase()) {
      case 'CASH':
        return Icons.money;
      case 'EMOLA':
        return Icons.phone_android;
      case 'MPESA':
        return Icons.phone_iphone;
      case 'POS':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getCorValor() {
    if (valorAtual == 0) return Colors.grey[100]!;
    if (valorAtual > widget.divida.valorRestante) return Colors.red[50]!;
    if (valorAtual == widget.divida.valorRestante) return Colors.green[50]!;
    return Colors.orange[50]!;
  }

  Color _getCorMensagem() {
    if (valorAtual > widget.divida.valorRestante) return Colors.red[700]!;
    if (valorAtual == widget.divida.valorRestante) return Colors.green[700]!;
    return Colors.orange[700]!;
  }

  String _getMensagemValor() {
    if (valorAtual > widget.divida.valorRestante) {
      return '⚠️ Valor maior que o restante!';
    }
    if (valorAtual == widget.divida.valorRestante) {
      return '✅ Pagamento total - Dívida será quitada';
    }
    final restante = widget.divida.valorRestante - valorAtual;
    return '📝 Pagamento parcial - Restará ${Formatters.formatarMoeda(restante)}';
  }

  void _adicionarDigito(String digito) {
    if (digito == '.' && valorDigitado.value.contains('.')) return;
    if (valorDigitado.value == '0' && digito != '.') {
      valorDigitado.value = digito;
    } else {
      valorDigitado.value += digito;
    }
  }

  void _removerUltimoDigito() {
    if (valorDigitado.value.length > 1) {
      valorDigitado.value = valorDigitado.value.substring(0, valorDigitado.value.length - 1);
    } else {
      valorDigitado.value = '0';
    }
  }

  void _limparValor() {
    valorDigitado.value = '0';
  }

  void _setValor(double valor) {
    valorDigitado.value = valor.toStringAsFixed(2);
  }

  String _formatarValor(String valor) {
    double val = double.tryParse(valor) ?? 0;
    return val.toStringAsFixed(2);
  }

  Future<void> _registrarPagamento() async {
    if (!podeRegistrar) return;

    isProcessando.value = true;

    try {
      final sucesso = await _dividaRepo.registrarPagamento(
        widget.divida.id!,
        valorAtual,
        formaSelecionada.value!.id,
        observacoesController.text.isEmpty ? null : observacoesController.text,
        'Sistema', // TODO: Pegar usuário logado
      );

      if (sucesso) {
        Get.back(result: true);

        final foiQuitada = valorAtual == widget.divida.valorRestante;

        Get.snackbar(
          'Sucesso',
          foiQuitada
              ? 'Dívida quitada com sucesso! 🎉'
              : 'Pagamento de ${Formatters.formatarMoeda(valorAtual)} registrado com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
          icon: Icon(
            foiQuitada ? Icons.celebration : Icons.check_circle,
            color: Colors.white,
          ),
        );

        // Chamar callback se fornecido
        widget.onPagamentoRealizado?.call();
      } else {
        throw Exception('Falha ao registrar pagamento');
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao registrar pagamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } finally {
      isProcessando.value = false;
    }
  }
}
