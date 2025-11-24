import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/mesa_model.dart';
import '../../../data/models/local_mesa_model.dart';
import '../../../data/models/pedido_model.dart';
import '../../../data/models/item_pedido_model.dart';
import '../../../data/repositories/mesa_repository.dart';
import '../../../data/repositories/local_mesa_repository.dart';
import '../../../data/repositories/pedido_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/formatters.dart';

class DialogGerenciarPedidos extends StatefulWidget {
  const DialogGerenciarPedidos({Key? key}) : super(key: key);

  @override
  State<DialogGerenciarPedidos> createState() => _DialogGerenciarPedidosState();
}

class _DialogGerenciarPedidosState extends State<DialogGerenciarPedidos> {
  final _mesaRepo = MesaRepository();
  final _localRepo = LocalMesaRepository();
  final _pedidoRepo = PedidoRepository();
  final _authService = Get.find<AuthService>();

  final RxList<LocalMesaModel> locais = <LocalMesaModel>[].obs;
  final RxList<MesaModel> mesas = <MesaModel>[].obs;
  final RxList<MesaModel> mesasFiltradas = <MesaModel>[].obs;
  final Rxn<LocalMesaModel> localSelecionado = Rxn<LocalMesaModel>();
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      isLoading.value = true;

      locais.value = await _localRepo.listarTodos();

      final isAdmin = await _authService.temPermissao('gestao_mesas');
      final usuarioId = _authService.usuarioLogado.value?.id ?? 0;

      mesas.value = await _mesaRepo.listarPorUsuario(usuarioId, isAdmin);

      if (locais.isNotEmpty) {
        _selecionarLocal(locais.first);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar mesas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _selecionarLocal(LocalMesaModel local) {
    localSelecionado.value = local;
    mesasFiltradas.value = mesas.where((m) => m.localId == local.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.receipt_long, size: 28, color: Get.theme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'GERENCIAR PEDIDOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Obx(() => localSelecionado.value != null
                    ? Text(
                        'Local: ${localSelecionado.value!.nome}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Get.theme.primaryColor,
                        ),
                      )
                    : Container()),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.refresh, size: 24),
                  onPressed: _carregarDados,
                  tooltip: 'Atualizar',
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Divider(height: 24),

            // Grid de mesas
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                if (locais.isEmpty) {
                  return Center(child: Text('Nenhum local cadastrado'));
                }

                return _buildGridMesas();
              }),
            ),

            SizedBox(height: 16),

            // Legenda
            _buildLegenda(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMesas() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna dos locais
        Container(
          width: 160,
          child: Obx(() => Column(
            children: locais.map((local) {
              final mesasDoLocal = mesas.where((m) => m.localId == local.id).length;
              final mesasOcupadas = mesas
                  .where((m) => m.localId == local.id && m.isOcupada)
                  .length;
              final isSelected = localSelecionado.value?.id == local.id;

              return InkWell(
                onTap: () => _selecionarLocal(local),
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Get.theme.primaryColor : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        local.nome,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$mesasOcupadas/$mesasDoLocal ocupadas',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )),
        ),

        SizedBox(width: 16),

        // Grid das mesas
        Expanded(
          child: Obx(() => GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: mesasFiltradas.length,
            itemBuilder: (context, index) {
              final mesa = mesasFiltradas[index];
              return _buildCardMesa(mesa);
            },
          )),
        ),
      ],
    );
  }

  Widget _buildCardMesa(MesaModel mesa) {
    Color corFundo;
    Color corTexto;

    if (mesa.isLivre) {
      corFundo = Colors.blue[900]!;
      corTexto = Colors.white;
    } else if (mesa.isOcupada) {
      corFundo = Colors.amber[600]!;
      corTexto = Colors.black;
    } else {
      corFundo = Colors.grey[400]!;
      corTexto = Colors.black54;
    }

    return InkWell(
      onTap: mesa.isOcupada ? () => _abrirDetalhesPedido(mesa) : null,
      child: Container(
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${mesa.numero}',
              style: TextStyle(
                color: corTexto,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mesa.isOcupada) ...[
              SizedBox(height: 2),
              Text(
                '${mesa.pedidoTotal?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  color: corTexto,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                (mesa.usuarioNome ?? '').split(' ').first.toUpperCase(),
                style: TextStyle(
                  color: corTexto,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegenda() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItemLegenda(Colors.blue[900]!, 'Livre'),
          _buildItemLegenda(Colors.amber[600]!, 'Ocupada (clique para ver)'),
          _buildItemLegenda(Colors.grey[400]!, 'Inativa'),
        ],
      ),
    );
  }

  Widget _buildItemLegenda(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _abrirDetalhesPedido(MesaModel mesa) async {
    if (mesa.pedidoId == null) return;

    try {
      final pedido = await _pedidoRepo.buscarPorId(mesa.pedidoId!);
      if (pedido == null) {
        Get.snackbar('Erro', 'Pedido não encontrado');
        return;
      }

      final itens = await _pedidoRepo.listarItensPedido(pedido.id!);

      Get.dialog(
        _buildDialogDetalhesPedido(mesa, pedido, itens),
        barrierDismissible: true,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar pedido: $e');
    }
  }

  Widget _buildDialogDetalhesPedido(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) {
    return Dialog(
      child: Container(
        width: 600,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.receipt, size: 28, color: Get.theme.primaryColor),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MESA ${mesa.numero}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Pedido: ${pedido.numero}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Divider(height: 24),

            // Informações
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Responsável:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(pedido.usuarioNome ?? ''),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Data Abertura:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${pedido.dataAbertura.day}/${pedido.dataAbertura.month}/${pedido.dataAbertura.year} ${pedido.dataAbertura.hour}:${pedido.dataAbertura.minute.toString().padLeft(2, '0')}'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Lista de itens
            Text('ITENS DO PEDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.produtoNome),
                      subtitle: Text('${item.quantidade}x ${Formatters.formatarMoeda(item.precoUnitario)}'),
                      trailing: Text(
                        Formatters.formatarMoeda(item.subtotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Get.theme.primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 24),

            // Total
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    Formatters.formatarMoeda(pedido.total),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _imprimirConta(mesa, pedido, itens);
                    },
                    icon: Icon(Icons.print),
                    label: Text('IMPRIMIR CONTA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _finalizarPedido(mesa, pedido, itens);
                    },
                    icon: Icon(Icons.payment),
                    label: Text('FINALIZAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

  Future<void> _imprimirConta(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) async {
    Get.snackbar(
      'Impressão',
      'Função de impressão será implementada em breve',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> _finalizarPedido(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) async {
    // Retornar dados para o controller processar o pagamento
    Get.back(result: {
      'mesa': mesa,
      'pedido': pedido,
      'itens': itens,
    });
  }
}
