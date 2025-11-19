import 'package:get/get.dart';
import '../../../data/models/familia_model.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/empresa_model.dart';
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/models/setor_model.dart';
import '../../../data/models/area_model.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/models/despesa_model.dart';
import '../../../data/models/produto_composicao_model.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/repositories/empresa_repository.dart';
import '../../../data/repositories/forma_pagamento_repository.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/repositories/area_repository.dart';
import '../../../data/repositories/cliente_repository.dart';
import '../../../data/repositories/despesa_repository.dart';
import '../../../data/repositories/produto_composicao_repository.dart';

class AdminController extends GetxController {
  final FamiliaRepository _familiaRepo = FamiliaRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  final FormaPagamentoRepository _formaPagamentoRepo = FormaPagamentoRepository();
  final SetorRepository _setorRepo = SetorRepository();
  final AreaRepository _areaRepo = AreaRepository();
  final ClienteRepository _clienteRepo = ClienteRepository();
  final DespesaRepository _despesaRepo = DespesaRepository();
  final ProdutoComposicaoRepository _composicaoRepo = ProdutoComposicaoRepository();

  final familias = <FamiliaModel>[].obs;
  final produtos = <ProdutoModel>[].obs;
  final empresa = Rxn<EmpresaModel>();
  final formasPagamento = <FormaPagamentoModel>[].obs;
  final setores = <SetorModel>[].obs;
  final areas = <AreaModel>[].obs;
  final clientes = <ClienteModel>[].obs;
  final despesas = <DespesaModel>[].obs;
  final isLoading = false.obs;

  // Variáveis para memorizar últimas seleções ao criar produtos
  final Rxn<int> ultimaFamiliaSelecionada = Rxn<int>();
  final Rxn<int> ultimoSetorSelecionado = Rxn<int>();
  final Rxn<int> ultimaAreaSelecionada = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    carregarDados();
  }

  Future<void> carregarDados() async {
    isLoading.value = true;
    try {
      familias.value = await _familiaRepo.listarTodas();
      produtos.value = await _produtoRepo.listarTodos();
      empresa.value = await _empresaRepo.buscarDados();
      formasPagamento.value = await _formaPagamentoRepo.listarTodas();
      setores.value = await _setorRepo.listarTodos();
      areas.value = await _areaRepo.listarTodas();
      clientes.value = await _clienteRepo.listarTodos();
      despesas.value = await _despesaRepo.listarTodas();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===== EMPRESA =====
  Future<void> atualizarEmpresa(EmpresaModel novaEmpresa) async {
    try {
      if (empresa.value != null) {
        await _empresaRepo.atualizar(empresa.value!.id!, novaEmpresa);
        await carregarDados();
        Get.back();
        Get.snackbar('Sucesso', 'Dados da empresa atualizados!');
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar empresa: $e');
    }
  }

  // ===== FORMA PAGAMENTO =====
  Future<void> adicionarFormaPagamento(String nome, String? descricao) async {
    try {
      final forma = FormaPagamentoModel(nome: nome, descricao: descricao);
      await _formaPagamentoRepo.inserir(forma);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Forma de pagamento adicionada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar: $e');
    }
  }

  Future<void> editarFormaPagamento(int id, String nome, String? descricao) async {
    try {
      final forma = FormaPagamentoModel(nome: nome, descricao: descricao);
      await _formaPagamentoRepo.atualizar(id, forma);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Forma de pagamento atualizada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar: $e');
    }
  }

  Future<void> deletarFormaPagamento(int id) async {
    try {
      await _formaPagamentoRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Forma de pagamento removida!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover: $e');
    }
  }

  // ===== SETOR =====
  Future<void> adicionarSetor(String nome, String? descricao) async {
    try {
      final setor = SetorModel(nome: nome, descricao: descricao);
      await _setorRepo.inserir(setor);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Setor adicionado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar: $e');
    }
  }

  Future<void> editarSetor(int id, String nome, String? descricao) async {
    try {
      final setor = SetorModel(nome: nome, descricao: descricao);
      await _setorRepo.atualizar(id, setor);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Setor atualizado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar: $e');
    }
  }

  Future<void> deletarSetor(int id) async {
    try {
      await _setorRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Setor removido!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover: $e');
    }
  }

  // ===== ÁREA =====
  Future<void> adicionarArea(String nome, String? descricao) async {
    try {
      final area = AreaModel(nome: nome, descricao: descricao);
      await _areaRepo.inserir(area);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Área adicionada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar: $e');
    }
  }

  Future<void> editarArea(int id, String nome, String? descricao) async {
    try {
      final area = AreaModel(nome: nome, descricao: descricao);
      await _areaRepo.atualizar(id, area);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Área atualizada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar: $e');
    }
  }

  Future<void> deletarArea(int id) async {
    try {
      await _areaRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Área removida!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover: $e');
    }
  }

  // FAMÍLIA
  Future<void> adicionarFamilia(String nome, String? descricao, List<int> setorIds) async {
    try {
      final familia = FamiliaModel(nome: nome, descricao: descricao);
      await _familiaRepo.inserir(familia, setorIds);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Família adicionada com sucesso!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar família: $e');
    }
  }

  Future<void> editarFamilia(int id, String nome, String? descricao, List<int> setorIds) async {
    try {
      final familia = FamiliaModel(nome: nome, descricao: descricao);
      await _familiaRepo.atualizar(id, familia, setorIds);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Família atualizada com sucesso!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar família: $e');
    }
  }

  Future<void> deletarFamilia(int id) async {
    try {
      await _familiaRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Família removida!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover família: $e');
    }
  }

  // PRODUTO
  Future<void> adicionarProduto(
    ProdutoModel produto, [
    List<ProdutoComposicaoModel>? composicao,
  ]) async {
    try {
      // Inserir produto
      final produtoId = await _produtoRepo.inserir(produto);

      // Salvar composição se fornecida
      if (composicao != null && composicao.isNotEmpty) {
        await _composicaoRepo.salvarComposicao(produtoId, composicao);
      }

      // Memorizar seleções para o próximo produto
      ultimaFamiliaSelecionada.value = produto.familiaId;
      if (produto.setorId != null) {
        ultimoSetorSelecionado.value = produto.setorId;
      }
      if (produto.areaId != null) {
        ultimaAreaSelecionada.value = produto.areaId;
      }

      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Produto adicionado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar produto: $e');
    }
  }

  Future<void> editarProduto(
    int id,
    ProdutoModel produto, [
    List<ProdutoComposicaoModel>? composicao,
  ]) async {
    try {
      // Atualizar produto
      await _produtoRepo.atualizar(id, produto);

      // Atualizar composição
      if (composicao != null) {
        await _composicaoRepo.salvarComposicao(id, composicao);
      }

      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Produto atualizado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar produto: $e');
    }
  }

  Future<List<ProdutoComposicaoModel>> buscarComposicaoProduto(
      int produtoId) async {
    try {
      return await _composicaoRepo.buscarComposicao(produtoId);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao buscar composição: $e');
      return [];
    }
  }

  Future<void> deletarProduto(int id) async {
    try {
      await _produtoRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Produto removido!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover produto: $e');
    }
  }

  // ===== CLIENTE =====
  Future<void> adicionarCliente(ClienteModel cliente) async {
    try {
      await _clienteRepo.inserir(cliente);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Cliente adicionado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar cliente: $e');
    }
  }

  Future<void> editarCliente(int id, ClienteModel cliente) async {
    try {
      await _clienteRepo.atualizar(id, cliente);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Cliente atualizado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar cliente: $e');
    }
  }

  Future<void> deletarCliente(int id) async {
    try {
      await _clienteRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Cliente removido!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover cliente: $e');
    }
  }

  // ===== DESPESA =====
  Future<void> adicionarDespesa(DespesaModel despesa) async {
    try {
      await _despesaRepo.inserir(despesa);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Despesa adicionada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar despesa: $e');
    }
  }

  Future<void> editarDespesa(int id, DespesaModel despesa) async {
    try {
      await _despesaRepo.atualizar(id, despesa);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Despesa atualizada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar despesa: $e');
    }
  }

  Future<void> deletarDespesa(int id) async {
    try {
      await _despesaRepo.deletar(id);
      await carregarDados();
      Get.snackbar('Sucesso', 'Despesa removida!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao remover despesa: $e');
    }
  }
}
