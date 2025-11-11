import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/despesa_model.dart';
import '../controllers/admin_controller.dart';

class DespesasTab extends GetView<AdminController> {
  final List<String> categorias = [
    'OPERACIONAL',
    'UTILIDADES',
    'PESSOAL',
    'MANUTENÇÃO',
    'MARKETING',
    'TRANSPORTE',
    'OUTROS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.despesas.isEmpty) {
          return Center(
            child: Text('Nenhuma despesa cadastrada'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.despesas.length,
          itemBuilder: (context, index) {
            final despesa = controller.despesas[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.money_off, color: Colors.white),
                  backgroundColor: _getCorCategoria(despesa.categoria),
                ),
                title: Text(
                  despesa.descricao,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categoria: ${despesa.categoria ?? "N/A"}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(despesa.dataDespesa)}'),
                    if (despesa.formaPagamentoNome != null)
                      Text('Forma: ${despesa.formaPagamentoNome}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatarMoeda(despesa.valor),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _mostrarDialogDespesa(despesa),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _confirmarDelete(despesa.id!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogDespesa(null),
        child: Icon(Icons.add),
      ),
    );
  }

  Color _getCorCategoria(String? categoria) {
    switch (categoria) {
      case 'OPERACIONAL':
        return Colors.blue;
      case 'UTILIDADES':
        return Colors.orange;
      case 'PESSOAL':
        return Colors.green;
      case 'MANUTENÇÃO':
        return Colors.purple;
      case 'MARKETING':
        return Colors.pink;
      case 'TRANSPORTE':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _mostrarDialogDespesa(DespesaModel? despesa) {
    final descricaoController =
        TextEditingController(text: despesa?.descricao ?? '');
    final valorController = TextEditingController(
      text: despesa?.valor.toString() ?? '',
    );
    final observacoesController =
        TextEditingController(text: despesa?.observacoes ?? '');

    String? categoriaSelecionada = despesa?.categoria ?? categorias[0];
    int? formaPagamentoIdSelecionada = despesa?.formaPagamentoId;
    DateTime dataSelecionada = despesa?.dataDespesa ?? DateTime.now();

    Get.dialog(
      AlertDialog(
        title: Text(despesa == null ? 'Nova Despesa' : 'Editar Despesa'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: valorController,
                  decoration: InputDecoration(
                    labelText: 'Valor *',
                    border: OutlineInputBorder(),
                    prefixText: 'MT ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: categorias.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    categoriaSelecionada = value;
                  },
                ),
                SizedBox(height: 10),
                Obx(() => DropdownButtonFormField<int>(
                      value: formaPagamentoIdSelecionada,
                      decoration: InputDecoration(
                        labelText: 'Forma de Pagamento',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.formasPagamento.map((forma) {
                        return DropdownMenuItem<int>(
                          value: forma.id,
                          child: Text(forma.nome),
                        );
                      }).toList(),
                      onChanged: (value) {
                        formaPagamentoIdSelecionada = value;
                      },
                    )),
                SizedBox(height: 10),
                ListTile(
                  title: Text('Data da Despesa'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(dataSelecionada),
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final data = await showDatePicker(
                      context: Get.context!,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (data != null) {
                      final hora = await showTimePicker(
                        context: Get.context!,
                        initialTime: TimeOfDay.fromDateTime(dataSelecionada),
                      );
                      if (hora != null) {
                        dataSelecionada = DateTime(
                          data.year,
                          data.month,
                          data.day,
                          hora.hour,
                          hora.minute,
                        );
                      }
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: observacoesController,
                  decoration: InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descricaoController.text.isEmpty ||
                  valorController.text.isEmpty) {
                Get.snackbar('Erro', 'Preencha todos os campos obrigatórios');
                return;
              }

              final novaDespesa = DespesaModel(
                descricao: descricaoController.text,
                valor: double.tryParse(valorController.text) ?? 0,
                categoria: categoriaSelecionada,
                dataDespesa: dataSelecionada,
                formaPagamentoId: formaPagamentoIdSelecionada,
                observacoes: observacoesController.text.isEmpty
                    ? null
                    : observacoesController.text,
                usuario: 'Admin', // TODO: Pegar usuário logado
              );

              if (despesa == null) {
                controller.adicionarDespesa(novaDespesa);
              } else {
                controller.editarDespesa(despesa.id!, novaDespesa);
              }
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja realmente remover esta despesa?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarDespesa(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
