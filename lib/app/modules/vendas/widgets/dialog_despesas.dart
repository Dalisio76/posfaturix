import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/despesa_model.dart';
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/repositories/despesa_repository.dart';

class DialogDespesas extends StatefulWidget {
  final List<FormaPagamentoModel> formasPagamento;

  const DialogDespesas({
    Key? key,
    required this.formasPagamento,
  }) : super(key: key);

  @override
  State<DialogDespesas> createState() => _DialogDespesasState();
}

class _DialogDespesasState extends State<DialogDespesas> {
  final _despesaRepo = DespesaRepository();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  final List<String> categorias = [
    'OPERACIONAL',
    'UTILIDADES',
    'PESSOAL',
    'MANUTENÇÃO',
    'MARKETING',
    'TRANSPORTE',
    'OUTROS',
  ];

  String? categoriaSelecionada;
  int? formaPagamentoIdSelecionada;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    categoriaSelecionada = categorias[0];
    if (widget.formasPagamento.isNotEmpty) {
      formaPagamentoIdSelecionada = widget.formasPagamento[0].id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.money_off, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text(
                  'Registrar Despesa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Divider(height: 24),
            SizedBox(height: 8),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _valorController,
              decoration: InputDecoration(
                labelText: 'Valor *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'MT ',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: categoriaSelecionada,
              decoration: InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categorias.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  categoriaSelecionada = value;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: formaPagamentoIdSelecionada,
              decoration: InputDecoration(
                labelText: 'Forma de Pagamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: widget.formasPagamento.map((forma) {
                return DropdownMenuItem<int>(
                  value: forma.id,
                  child: Text(forma.nome),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  formaPagamentoIdSelecionada = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _observacoesController,
              decoration: InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: salvando ? null : () => Get.back(),
                    icon: Icon(Icons.cancel),
                    label: Text('CANCELAR'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: salvando ? null : _salvarDespesa,
                    icon: salvando
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.save),
                    label: Text(salvando ? 'SALVANDO...' : 'SALVAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarDespesa() async {
    if (_descricaoController.text.isEmpty || _valorController.text.isEmpty) {
      Get.snackbar(
        'Erro',
        'Preencha todos os campos obrigatórios',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final despesa = DespesaModel(
        descricao: _descricaoController.text,
        valor: double.parse(_valorController.text),
        categoria: categoriaSelecionada,
        dataDespesa: DateTime.now(),
        formaPagamentoId: formaPagamentoIdSelecionada,
        observacoes: _observacoesController.text.isEmpty
            ? null
            : _observacoesController.text,
        usuario: 'Caixa', // TODO: Pegar usuário logado
      );

      await _despesaRepo.inserir(despesa);

      Get.back();
      Get.snackbar(
        'Sucesso',
        'Despesa registrada com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar despesa: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        salvando = false;
      });
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}
