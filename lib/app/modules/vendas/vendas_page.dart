import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import 'controllers/vendas_controller.dart';
import 'widgets/dialog_pesquisa_produto.dart';
import 'views/tela_devedores.dart';

class VendasPage extends StatelessWidget {
  final VendasController controller = Get.put(VendasController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VENDAS', style: TextStyle(fontSize: 18)),
        actions: [
          // Botão DESPESAS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: controller.abrirDialogDespesas,
              icon: Icon(Icons.money_off, size: 20),
              label: Text('DESPESAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Botão PEDIDO
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Em Desenvolvimento',
                  'Funcionalidade de Pedidos será implementada em breve',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              },
              icon: Icon(Icons.receipt_long, size: 20),
              label: Text('PEDIDO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Botão CLIENTES - Abre tela de devedores
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => TelaDevedores());
              },
              icon: Icon(Icons.people, size: 20),
              label: Text('CLIENTES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Botão de Pesquisa
          IconButton(
            icon: Icon(Icons.search, size: 28),
            onPressed: _abrirPesquisa,
            tooltip: 'Pesquisar Produto',
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh, size: 24),
            onPressed: controller.carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Row(
        children: [
          // LADO ESQUERDO: Produtos
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Filtro por família (maior)
                _buildFiltroFamilias(),
                Divider(height: 1),
                // Grid de produtos (menor)
                Expanded(child: _buildGridProdutos()),
              ],
            ),
          ),

          // LADO DIREITO: Carrinho
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                _buildHeaderCarrinho(),
                Expanded(child: _buildListaCarrinho()),
                _buildTotalCarrinho(),
                _buildBotoesAcao(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirPesquisa() {
    Get.dialog(
      DialogPesquisaProduto(
        produtos: controller.produtos,
        onProdutoSelecionado: (produto) {
          controller.adicionarAoCarrinho(produto);
        },
      ),
    );
  }

  Widget _buildFiltroFamilias() {
    return Container(
      height: 120,  // Aumentado para acomodar grid
      padding: EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Obx(() {
        final todasAsFamilias = [null, ...controller.familias];
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,  // 6 famílias por linha
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.0,  // Largura/altura
          ),
          itemCount: todasAsFamilias.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Botão TODAS
              return FilterChip(
                label: Text('TODAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                selected: controller.familiaSelecionada == null,
                onSelected: (_) => controller.selecionarFamilia(null),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                selectedColor: Get.theme.primaryColor,
                labelStyle: TextStyle(
                  color: controller.familiaSelecionada == null ? Colors.white : Colors.black,
                ),
              );
            } else {
              final familia = todasAsFamilias[index];
              final isSelected = controller.familiaSelecionada?.id == familia?.id;
              return FilterChip(
                label: Text(
                  familia!.nome,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                selected: isSelected,
                onSelected: (_) => controller.selecionarFamilia(familia),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                selectedColor: Get.theme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            }
          },
        );
      }),
    );
  }

  Widget _buildGridProdutos() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.produtosFiltrados.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhum produto encontrado', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _abrirPesquisa,
                icon: Icon(Icons.search),
                label: Text('PESQUISAR'),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.2,  // Aumentado para cards mais largos e baixos (sem ícone)
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: controller.produtosFiltrados.length,
        itemBuilder: (context, index) {
          final produto = controller.produtosFiltrados[index];
          return _buildCardProduto(produto);
        },
      );
    });
  }

  Widget _buildCardProduto(produto) {
    return InkWell(
      onTap: () => controller.adicionarAoCarrinho(produto),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nome
              Text(
                produto.nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              // Preço
              Text(
                Formatters.formatarMoeda(produto.preco),
                style: TextStyle(
                  color: Get.theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              // Estoque
              Text(
                'Estoque: ${produto.estoque}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCarrinho() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            'CARRINHO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Obx(() => Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.carrinho.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.primaryColor,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildListaCarrinho() {
    return Obx(() {
      if (controller.carrinho.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Carrinho vazio',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.carrinho.length,
        itemBuilder: (context, index) {
          final item = controller.carrinho[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.produto.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => controller.removerDoCarrinho(index),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Controles de quantidade
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => controller.diminuirQuantidade(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.remove, size: 18),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item.quantidade}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => controller.aumentarQuantidade(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.add, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      // Subtotal
                      Text(
                        Formatters.formatarMoeda(item.subtotal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Get.theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${Formatters.formatarMoeda(item.produto.preco)} cada',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildTotalCarrinho() {
    return Obx(() => Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                Formatters.formatarMoeda(controller.totalCarrinho),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.primaryColor,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildBotoesAcao() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.limparCarrinho,
              icon: Icon(Icons.delete_sweep, size: 20),
              label: Text('LIMPAR', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(14),
              ),
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.finalizarVenda,
              icon: Icon(Icons.payment, size: 22),
              label: Text('FINALIZAR VENDA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
