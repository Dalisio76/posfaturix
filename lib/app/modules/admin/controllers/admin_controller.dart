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
      // Erro silencioso
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
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  // ===== FORMA PAGAMENTO =====
  Future<void> adicionarFormaPagamento(String nome, String? descricao) async {
    try {
      final forma = FormaPagamentoModel(nome: nome, descricao: descricao);
      await _formaPagamentoRepo.inserir(forma);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> editarFormaPagamento(int id, String nome, String? descricao) async {
    try {
      final forma = FormaPagamentoModel(nome: nome, descricao: descricao);
      await _formaPagamentoRepo.atualizar(id, forma);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> deletarFormaPagamento(int id) async {
    try {
      await _formaPagamentoRepo.deletar(id);
      formasPagamento.removeWhere((f) => f.id == id);
      formasPagamento.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }

  // ===== SETOR =====
  Future<void> adicionarSetor(String nome, String? descricao) async {
    try {
      final setor = SetorModel(nome: nome, descricao: descricao);
      await _setorRepo.inserir(setor);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> editarSetor(int id, String nome, String? descricao) async {
    try {
      final setor = SetorModel(nome: nome, descricao: descricao);
      await _setorRepo.atualizar(id, setor);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> deletarSetor(int id) async {
    try {
      await _setorRepo.deletar(id);
      setores.removeWhere((s) => s.id == id);
      setores.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }

  // ===== ÁREA =====
  Future<void> adicionarArea(String nome, String? descricao, int? impressoraId) async {
    try {
      final area = AreaModel(
        nome: nome,
        descricao: descricao,
        impressoraId: impressoraId,
      );
      await _areaRepo.inserir(area);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> editarArea(int id, String nome, String? descricao, int? impressoraId) async {
    try {
      final area = AreaModel(
        nome: nome,
        descricao: descricao,
        impressoraId: impressoraId,
      );
      await _areaRepo.atualizar(id, area);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> deletarArea(int id) async {
    try {
      await _areaRepo.deletar(id);
      areas.removeWhere((a) => a.id == id);
      areas.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }

  // FAMÍLIA
  Future<void> adicionarFamilia(String nome, String? descricao, List<int> setorIds) async {
    try {
      final familia = FamiliaModel(nome: nome, descricao: descricao);
      await _familiaRepo.inserir(familia, setorIds);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> editarFamilia(int id, String nome, String? descricao, List<int> setorIds) async {
    try {
      final familia = FamiliaModel(nome: nome, descricao: descricao);
      await _familiaRepo.atualizar(id, familia, setorIds);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> deletarFamilia(int id) async {
    try {
      await _familiaRepo.deletar(id);
      familias.removeWhere((f) => f.id == id);
      familias.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }

  // PRODUTO

  /// Verifica se produto já existe (por nome ou código de barras)
  /// Retorna mensagem de erro ou null se não existe duplicado
  Future<String?> verificarProdutoDuplicado(String nome, String? codigoBarras, {int? excluirId}) async {
    try {
      // Verificar nome duplicado
      final existeNome = await _produtoRepo.existeProdutoComNome(nome, excluirId: excluirId);
      if (existeNome) {
        return 'Já existe um produto com o nome "$nome"';
      }

      // Verificar código de barras duplicado
      if (codigoBarras != null && codigoBarras.isNotEmpty) {
        final existeCodigo = await _produtoRepo.existeProdutoComCodigoBarras(codigoBarras, excluirId: excluirId);
        if (existeCodigo) {
          return 'Já existe um produto com o código de barras "$codigoBarras"';
        }
      }

      return null; // Sem duplicado
    } catch (e) {
      return 'Erro ao verificar duplicados: $e';
    }
  }

  /// Adiciona produto e retorna resultado: null = sucesso, String = mensagem de erro
  Future<String?> adicionarProduto(
    ProdutoModel produto, [
    List<ProdutoComposicaoModel>? composicao,
  ]) async {
    try {
      // Verificar duplicados antes de inserir
      final erroDuplicado = await verificarProdutoDuplicado(
        produto.nome,
        produto.codigoBarras,
      );
      if (erroDuplicado != null) {
        return erroDuplicado;
      }

      final produtoId = await _produtoRepo.inserir(produto);

      if (composicao != null && composicao.isNotEmpty) {
        await _composicaoRepo.salvarComposicao(produtoId, composicao);
      }

      ultimaFamiliaSelecionada.value = produto.familiaId;
      if (produto.setorId != null) {
        ultimoSetorSelecionado.value = produto.setorId;
      }
      if (produto.areaId != null) {
        ultimaAreaSelecionada.value = produto.areaId;
      }

      await carregarDados();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao adicionar produto: $e';
    }
  }

  /// Edita produto e retorna resultado: null = sucesso, String = mensagem de erro
  Future<String?> editarProduto(
    int id,
    ProdutoModel produto, [
    List<ProdutoComposicaoModel>? composicao,
  ]) async {
    try {
      // Verificar duplicados (excluindo o próprio produto)
      final erroDuplicado = await verificarProdutoDuplicado(
        produto.nome,
        produto.codigoBarras,
        excluirId: id,
      );
      if (erroDuplicado != null) {
        return erroDuplicado;
      }

      await _produtoRepo.atualizar(id, produto);

      if (composicao != null) {
        await _composicaoRepo.salvarComposicao(id, composicao);
      }

      await carregarDados();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao editar produto: $e';
    }
  }

  Future<List<ProdutoComposicaoModel>> buscarComposicaoProduto(int produtoId) async {
    try {
      return await _composicaoRepo.buscarComposicao(produtoId);
    } catch (e) {
      return [];
    }
  }

  Future<void> deletarProduto(int id) async {
    try {
      await _produtoRepo.deletar(id);
      produtos.removeWhere((p) => p.id == id);
      produtos.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }

  // ===== CLIENTE =====

  /// Verifica se cliente já existe (por nome, telefone ou NUIT)
  /// Retorna mensagem de erro ou null se não existe duplicado
  Future<String?> verificarClienteDuplicado(ClienteModel cliente, {int? excluirId}) async {
    try {
      // Verificar nome duplicado
      final existeNome = await _clienteRepo.existeClienteComNome(cliente.nome, excluirId: excluirId);
      if (existeNome) {
        return 'Já existe um cliente com o nome "${cliente.nome}"';
      }

      // Verificar telefone duplicado
      if (cliente.contacto != null && cliente.contacto!.isNotEmpty) {
        final existeTelefone = await _clienteRepo.existeClienteComTelefone(cliente.contacto!, excluirId: excluirId);
        if (existeTelefone) {
          return 'Já existe um cliente com o telefone "${cliente.contacto}"';
        }
      }

      // Verificar NUIT duplicado
      if (cliente.nuit != null && cliente.nuit!.isNotEmpty) {
        final existeNuit = await _clienteRepo.existeClienteComNuit(cliente.nuit!, excluirId: excluirId);
        if (existeNuit) {
          return 'Já existe um cliente com o NUIT "${cliente.nuit}"';
        }
      }

      return null; // Sem duplicado
    } catch (e) {
      return 'Erro ao verificar duplicados: $e';
    }
  }

  /// Adiciona cliente e retorna resultado: null = sucesso, String = mensagem de erro
  Future<String?> adicionarCliente(ClienteModel cliente) async {
    try {
      // Verificar duplicados antes de inserir
      final erroDuplicado = await verificarClienteDuplicado(cliente);
      if (erroDuplicado != null) {
        return erroDuplicado;
      }

      await _clienteRepo.inserir(cliente);
      await carregarDados();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao adicionar cliente: $e';
    }
  }

  /// Edita cliente e retorna resultado: null = sucesso, String = mensagem de erro
  Future<String?> editarCliente(int id, ClienteModel cliente) async {
    try {
      // Verificar duplicados (excluindo o próprio cliente)
      final erroDuplicado = await verificarClienteDuplicado(cliente, excluirId: id);
      if (erroDuplicado != null) {
        return erroDuplicado;
      }

      await _clienteRepo.atualizar(id, cliente);
      await carregarDados();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao editar cliente: $e';
    }
  }

  Future<void> deletarCliente(int id) async {
    try {
      await _clienteRepo.deletar(id);
      clientes.removeWhere((c) => c.id == id);
      clientes.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }

  // ===== DESPESA =====
  Future<void> adicionarDespesa(DespesaModel despesa) async {
    try {
      await _despesaRepo.inserir(despesa);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> editarDespesa(int id, DespesaModel despesa) async {
    try {
      await _despesaRepo.atualizar(id, despesa);
      await carregarDados();
      Get.back();
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> deletarDespesa(int id) async {
    try {
      await _despesaRepo.deletar(id);
      despesas.removeWhere((d) => d.id == id);
      despesas.refresh();
    } catch (e) {
      // Erro silencioso
    }
  }
}
