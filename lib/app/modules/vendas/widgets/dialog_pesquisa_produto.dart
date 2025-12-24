import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/produto_model.dart';
import 'teclado_qwerty.dart';

class DialogPesquisaProduto extends StatefulWidget {
  final List<ProdutoModel> produtos;
  final Function(ProdutoModel) onProdutoSelecionado;

  const DialogPesquisaProduto({
    Key? key,
    required this.produtos,
    required this.onProdutoSelecionado,
  }) : super(key: key);

  @override
  State<DialogPesquisaProduto> createState() => _DialogPesquisaProdutoState();
}

class _DialogPesquisaProdutoState extends State<DialogPesquisaProduto> {
  final RxString textoPesquisa = ''.obs;
  final RxList<ProdutoModel> produtosFiltrados = <ProdutoModel>[].obs;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    produtosFiltrados.value = widget.produtos;
    _searchController.addListener(() {
      textoPesquisa.value = _searchController.text;
      _filtrarProdutos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _selecionarPrimeiroProduto() {
    if (produtosFiltrados.isNotEmpty) {
      widget.onProdutoSelecionado(produtosFiltrados.first);
      Get.back();
    }
  }

  void _filtrarProdutos() {
    if (textoPesquisa.value.isEmpty) {
      produtosFiltrados.value = widget.produtos;
    } else {
      produtosFiltrados.value = widget.produtos
          .where((produto) => produto.nome
              .toLowerCase()
              .contains(textoPesquisa.value.toLowerCase()))
          .toList();
    }
  }

  void _adicionarLetra(String letra) {
    _searchController.text += letra;
  }

  void _removerLetra() {
    if (_searchController.text.isNotEmpty) {
      _searchController.text =
          _searchController.text.substring(0, _searchController.text.length - 1);
    }
  }

  void _limparTexto() {
    _searchController.clear();
  }

  void _adicionarEspaco() {
    _searchController.text += ' ';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 850,  // Aumentado para teclado maior
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.search, size: 24, color: Get.theme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'PESQUISAR PRODUTO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.all(4),
                ),
              ],
            ),
            Divider(height: 20),

            // Campo de pesquisa
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[400]!, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Digite para pesquisar... (Enter = adicionar)',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _selecionarPrimeiroProduto(),
                textInputAction: TextInputAction.done,
              ),
            ),

            SizedBox(height: 8),

            // Teclado QWERTY (maior)
            Flexible(
              flex: 0,
              child: TecladoQwerty(
                onLetraPressed: _adicionarLetra,
                onBackspace: _removerLetra,
                onClear: _limparTexto,
                onEspaco: _adicionarEspaco,
              ),
            ),

            SizedBox(height: 8),

            // Resultados
            Obx(() => Text(
                  '${produtosFiltrados.length} produto(s) encontrado(s)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                )),

            SizedBox(height: 6),

            // Lista de produtos
            Expanded(
              child: Obx(() => produtosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum produto encontrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: produtosFiltrados.length,
                      itemBuilder: (context, index) {
                        final produto = produtosFiltrados[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Get.theme.primaryColor,
                              child: Text(
                                produto.nome.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              produto.nome,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'MT ${produto.preco.toStringAsFixed(2)} • Estoque: ${produto.estoque}',
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: Icon(Icons.add_circle,
                                color: Get.theme.primaryColor, size: 32),
                            onTap: () {
                              widget.onProdutoSelecionado(produto);
                              Get.back();
                            },
                          ),
                        );
                      },
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
