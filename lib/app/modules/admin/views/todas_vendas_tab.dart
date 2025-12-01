import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/todas_vendas_controller.dart';
import '../../../data/models/venda_model.dart';
import '../../../../core/utils/formatters.dart';

class TodasVendasTab extends StatelessWidget {
  const TodasVendasTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TodasVendasController());

    return Column(
      children: [
        // Filtros
        _buildFiltros(controller, context),
        SizedBox(height: 16),

        // Estatísticas rápidas
        _buildEstatisticas(controller),
        SizedBox(height: 16),

        // Tabela de vendas
        Expanded(
          child: _buildTabelaVendas(controller),
        ),
      ],
    );
  }

  Widget _buildFiltros(TodasVendasController controller, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20),
              SizedBox(width: 8),
              Text(
                'FILTROS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Linha 1: Datas e Status
          Row(
            children: [
              // Data Início
              Expanded(
                child: Obx(() => InkWell(
                  onTap: () => controller.selecionarDataInicio(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data Início',
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      controller.dataInicio.value != null
                          ? DateFormat('dd/MM/yyyy').format(controller.dataInicio.value!)
                          : 'Selecione',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )),
              ),
              SizedBox(width: 12),

              // Data Fim
              Expanded(
                child: Obx(() => InkWell(
                  onTap: () => controller.selecionarDataFim(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data Fim',
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      controller.dataFim.value != null
                          ? DateFormat('dd/MM/yyyy').format(controller.dataFim.value!)
                          : 'Selecione',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )),
              ),
              SizedBox(width: 12),

              // Status
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.filtroStatus.value,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag, size: 20),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'todas', child: Text('Todas')),
                    DropdownMenuItem(value: 'finalizada', child: Text('Finalizadas')),
                    DropdownMenuItem(value: 'cancelada', child: Text('Canceladas')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.aplicarFiltroStatus(value);
                    }
                  },
                )),
              ),
              SizedBox(width: 12),

              // Busca por número
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar Número',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => controller.aplicarFiltroNumero(value),
                ),
              ),
              SizedBox(width: 12),

              // Botão atualizar
              ElevatedButton.icon(
                onPressed: () => controller.carregarVendas(),
                icon: Icon(Icons.refresh),
                label: Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticas(TodasVendasController controller) {
    return Obx(() {
      final vendas = controller.vendas;
      final finalizadas = vendas.where((v) => v.isFinalizada).length;
      final canceladas = vendas.where((v) => v.isCancelada).length;
      final totalFinalizadas = vendas
          .where((v) => v.isFinalizada)
          .fold<double>(0, (sum, v) => sum + v.total);

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total de Vendas',
              vendas.length.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Finalizadas',
              finalizadas.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Canceladas',
              canceladas.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Finalizadas',
              Formatters.formatarMoeda(totalFinalizadas),
              Icons.euro,
              Colors.purple,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(String label, String valor, IconData icon, Color cor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cor, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelaVendas(TodasVendasController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando vendas...'),
            ],
          ),
        );
      }

      if (controller.vendas.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Nenhuma venda encontrada',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                'Ajuste os filtros para encontrar vendas',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            // Header da tabela
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Número', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Data/Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 100), // Espaço para ações
                ],
              ),
            ),

            // Linhas da tabela
            Expanded(
              child: ListView.builder(
                itemCount: controller.vendas.length,
                itemBuilder: (context, index) {
                  final venda = controller.vendas[index];
                  return _buildLinhaVenda(controller, venda, index);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLinhaVenda(TodasVendasController controller, VendaModel venda, int index) {
    final cor = index.isEven ? Colors.white : Colors.grey[50];

    return InkWell(
      onTap: () => controller.mostrarDetalhesVenda(venda),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cor,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Número
            Expanded(
              flex: 2,
              child: Text(
                venda.numero,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            // Data/Hora
            Expanded(
              flex: 3,
              child: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(venda.dataVenda),
                style: TextStyle(fontSize: 14),
              ),
            ),

            // Cliente
            Expanded(
              flex: 3,
              child: Text(
                venda.clienteNome ?? 'Venda direta',
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Total
            Expanded(
              flex: 2,
              child: Text(
                Formatters.formatarMoeda(venda.total),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: venda.isCancelada ? Colors.grey : Colors.black87,
                ),
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: venda.isCancelada ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: venda.isCancelada ? Colors.red[300]! : Colors.green[300]!,
                    ),
                  ),
                  child: Text(
                    venda.isCancelada ? 'CANCELADA' : 'FINALIZADA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: venda.isCancelada ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ),
              ),
            ),

            // Ações
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility, size: 20),
                    onPressed: () => controller.mostrarDetalhesVenda(venda),
                    tooltip: 'Ver detalhes',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
