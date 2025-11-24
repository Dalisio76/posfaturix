import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/mesa_model.dart';
import '../../../data/models/local_mesa_model.dart';
import '../../../data/repositories/mesa_repository.dart';
import '../../../data/repositories/local_mesa_repository.dart';
import '../../../../core/services/auth_service.dart';

class DialogSelecaoMesa extends StatefulWidget {
  const DialogSelecaoMesa({Key? key}) : super(key: key);

  @override
  State<DialogSelecaoMesa> createState() => _DialogSelecaoMesaState();
}

class _DialogSelecaoMesaState extends State<DialogSelecaoMesa> {
  final _mesaRepo = MesaRepository();
  final _localRepo = LocalMesaRepository();
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

      // Carregar locais
      locais.value = await _localRepo.listarTodos();

      // Verificar se usuário é admin
      final isAdmin = await _authService.temPermissao('gestao_mesas');
      final usuarioId = _authService.usuarioLogado.value?.id ?? 0;

      // Carregar mesas (filtradas por usuário se não for admin)
      mesas.value = await _mesaRepo.listarPorUsuario(usuarioId, isAdmin);

      // Selecionar primeiro local por padrão
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
                Icon(Icons.table_restaurant, size: 28, color: Get.theme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'SELECIONAR MESA',
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
                  return Center(
                    child: Text('Nenhum local cadastrado'),
                  );
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
                        '($mesasDoLocal mesas)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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

        // Grid das mesas (filtradas)
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
    bool habilitada = false;
    final usuarioLogadoId = _authService.usuarioLogado.value?.id;

    if (mesa.isLivre) {
      corFundo = Colors.blue[900]!;
      corTexto = Colors.white;
      habilitada = true;
    } else if (mesa.isOcupada) {
      // Verifica se a mesa é do usuário logado
      if (mesa.usuarioId == usuarioLogadoId) {
        corFundo = Colors.green[600]!; // Verde = minha mesa, pode adicionar
        corTexto = Colors.white;
        habilitada = true;
      } else {
        corFundo = Colors.red[600]!; // Vermelho = mesa de outro usuário
        corTexto = Colors.white;
        habilitada = false;
      }
    } else {
      corFundo = Colors.grey[400]!;
      corTexto = Colors.black54;
      habilitada = false;
    }

    return InkWell(
      onTap: habilitada ? () => Get.back(result: mesa) : null,
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
            // Número da mesa
            Text(
              '${mesa.numero}',
              style: TextStyle(
                color: corTexto,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Informações extras se ocupada
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
          _buildItemLegenda(Colors.green[600]!, 'Minha Mesa (pode adicionar)'),
          _buildItemLegenda(Colors.red[600]!, 'Ocupada por outro'),
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
