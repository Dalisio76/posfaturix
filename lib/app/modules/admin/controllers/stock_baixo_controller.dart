import 'package:get/get.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/models/familia_model.dart';
import '../../../data/models/setor_model.dart';
import '../../../../core/database/database_service.dart';

enum NivelAlerta {
  todos('Todos'),
  critico('Crítico'),
  baixo('Baixo'),
  alerta('Alerta');

  final String label;
  const NivelAlerta(this.label);
}

class ProdutoStockBaixo {
  final int id;
  final String codigo;
  final String nome;
  final String familiaNome;
  final String? setorNome;
  final int estoque;
  final int estoqueMinimo;
  final DateTime? ultimaEntrada;
  final NivelAlerta nivelAlerta;
  final double percentualMinimo;

  ProdutoStockBaixo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.familiaNome,
    this.setorNome,
    required this.estoque,
    required this.estoqueMinimo,
    this.ultimaEntrada,
    required this.nivelAlerta,
    required this.percentualMinimo,
  });

  factory ProdutoStockBaixo.fromMap(Map<String, dynamic> map) {
    final estoque = map['estoque'] as int? ?? 0;
    final estoqueMinimo = map['estoque_minimo'] as int? ?? 0;

    // Calcular percentual em relação ao mínimo
    final percentual = estoqueMinimo > 0
        ? (estoque / estoqueMinimo) * 100
        : 0.0;

    // Determinar nível de alerta
    NivelAlerta nivel;
    if (percentual < 30) {
      nivel = NivelAlerta.critico;
    } else if (percentual < 60) {
      nivel = NivelAlerta.baixo;
    } else {
      nivel = NivelAlerta.alerta;
    }

    return ProdutoStockBaixo(
      id: map['id'] as int,
      codigo: map['codigo']?.toString() ?? '',
      nome: map['nome'] as String,
      familiaNome: map['familia_nome'] as String? ?? 'Sem família',
      setorNome: map['setor_nome'] as String?,
      estoque: estoque,
      estoqueMinimo: estoqueMinimo,
      ultimaEntrada: map['ultima_entrada'] != null
          ? DateTime.parse(map['ultima_entrada'].toString())
          : null,
      nivelAlerta: nivel,
      percentualMinimo: percentual,
    );
  }
}

class StockBaixoController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();
  final FamiliaRepository _familiaRepo = Get.put(FamiliaRepository());
  final SetorRepository _setorRepo = Get.put(SetorRepository());

  // Listas observáveis
  final RxList<ProdutoStockBaixo> produtos = <ProdutoStockBaixo>[].obs;
  final RxList<ProdutoStockBaixo> produtosFiltrados = <ProdutoStockBaixo>[].obs;
  final RxList<FamiliaModel> familias = <FamiliaModel>[].obs;
  final RxList<SetorModel> setores = <SetorModel>[].obs;

  // Filtros
  final Rxn<FamiliaModel> familiaSelecionada = Rxn<FamiliaModel>();
  final Rxn<SetorModel> setorSelecionado = Rxn<SetorModel>();
  final Rx<NivelAlerta> nivelSelecionado = NivelAlerta.todos.obs;

  // Estado
  final RxBool carregando = false.obs;
  final RxInt linhaSelecionada = (-1).obs;

  // Totais
  final RxInt totalProdutosCritico = 0.obs;
  final RxInt totalProdutosBaixo = 0.obs;
  final RxInt totalProdutosAlerta = 0.obs;

  @override
  void onInit() {
    super.onInit();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      // Carregar familias e setores
      familias.value = await _familiaRepo.listarTodas();
      setores.value = await _setorRepo.listarTodos();

      // Carregar produtos com stock baixo
      await carregarProdutosStockBaixo();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    }
  }

  Future<void> carregarProdutosStockBaixo() async {
    try {
      carregando.value = true;

      // Buscar produtos onde estoque < estoque_minimo
      final result = await _db.query('''
        SELECT
          p.id,
          p.codigo,
          p.nome,
          p.estoque,
          p.estoque_minimo,
          p.familia_id,
          p.setor_id,
          f.nome as familia_nome,
          s.nome as setor_nome,
          (
            SELECT MAX(fe.data_entrada)
            FROM faturas_entrada_itens fei
            INNER JOIN faturas_entrada fe ON fe.id = fei.fatura_id
            WHERE fei.produto_id = p.id
          ) as ultima_entrada
        FROM produtos p
        LEFT JOIN familias f ON f.id = p.familia_id
        LEFT JOIN setores s ON s.id = p.setor_id
        WHERE p.ativo = true
          AND p.estoque_minimo > 0
          AND p.estoque < p.estoque_minimo
        ORDER BY
          CASE
            WHEN p.estoque < (p.estoque_minimo * 0.3) THEN 1
            WHEN p.estoque < (p.estoque_minimo * 0.6) THEN 2
            ELSE 3
          END,
          p.nome
      ''');

      produtos.value = result
          .map((map) => ProdutoStockBaixo.fromMap(map))
          .toList();

      // Aplicar filtros
      aplicarFiltros();

      Get.snackbar(
        'Sucesso',
        '${produtos.length} produtos com stock baixo encontrados',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar produtos: $e');
    } finally {
      carregando.value = false;
    }
  }

  void aplicarFiltros() {
    var lista = produtos.toList();

    // Filtrar por família
    if (familiaSelecionada.value != null) {
      // Filtrar pelo nome da família
      lista = lista.where((p) => p.familiaNome == familiaSelecionada.value!.nome).toList();
    }

    // Filtrar por setor
    if (setorSelecionado.value != null) {
      final setorNome = setorSelecionado.value!.nome;
      lista = lista.where((p) => p.setorNome == setorNome).toList();
    }

    // Filtrar por nível de alerta
    if (nivelSelecionado.value != NivelAlerta.todos) {
      lista = lista.where((p) => p.nivelAlerta == nivelSelecionado.value).toList();
    }

    produtosFiltrados.value = lista;

    // Calcular totais
    calcularTotais();
  }

  void calcularTotais() {
    totalProdutosCritico.value = produtosFiltrados
        .where((p) => p.nivelAlerta == NivelAlerta.critico)
        .length;

    totalProdutosBaixo.value = produtosFiltrados
        .where((p) => p.nivelAlerta == NivelAlerta.baixo)
        .length;

    totalProdutosAlerta.value = produtosFiltrados
        .where((p) => p.nivelAlerta == NivelAlerta.alerta)
        .length;
  }

  void limparFiltros() {
    familiaSelecionada.value = null;
    setorSelecionado.value = null;
    nivelSelecionado.value = NivelAlerta.todos;
    aplicarFiltros();
  }

  void setFamilia(FamiliaModel? familia) {
    familiaSelecionada.value = familia;
    aplicarFiltros();
  }

  void setSetor(SetorModel? setor) {
    setorSelecionado.value = setor;
    aplicarFiltros();
  }

  void setNivel(NivelAlerta nivel) {
    nivelSelecionado.value = nivel;
    aplicarFiltros();
  }
}
