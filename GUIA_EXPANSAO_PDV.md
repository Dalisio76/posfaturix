# 🚀 GUIA DE EXPANSÃO - Sistema PDV

> **Expansão do Sistema PDV com:**
> - Dados da Empresa
> - Formas de Pagamento
> - Setores e Áreas
> - Admin com Drawer
> - Impressão com dados da empresa

---

## 📋 Índice

1. [Criar Novas Tabelas no PostgreSQL](#fase-1-criar-novas-tabelas-no-postgresql)
2. [Models Flutter](#fase-2-models-flutter)
3. [Repositories](#fase-3-repositories)
4. [Admin com Drawer](#fase-4-admin-com-drawer)
5. [CRUD Completo](#fase-5-crud-completo---todas-tabelas)
6. [Formas de Pagamento na Venda](#fase-6-formas-de-pagamento-na-venda)
7. [Impressão com Dados da Empresa](#fase-7-impressão-com-dados-da-empresa)
8. [Testes](#fase-8-testes-finais)

---

## 🗄️ FASE 1: Criar Novas Tabelas no PostgreSQL

### 1. Abrir SQL Shell

```bash
# Abra SQL Shell (psql)
# Pressione Enter em tudo, depois digite a senha

# Conectar ao database
\c pdv_system
```

### 2. Executar SQL Completo

Cole todo este código de uma vez:

```sql
-- ===================================
-- TABELA: empresa (dados da empresa)
-- ===================================
CREATE TABLE empresa (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nuit VARCHAR(50),
    endereco TEXT,
    cidade VARCHAR(100),
    email VARCHAR(100),
    contacto VARCHAR(50),
    logo_url TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados padrão da empresa
INSERT INTO empresa (nome, nuit, endereco, cidade, email, contacto) VALUES 
('FRENTEX E SERVICOS', '123456789', 'Av. Julius Nyerere, Maputo', 'Maputo', 'contato@frentex.co.mz', '+258 84 123 4567');

-- ===================================
-- TABELA: formas_pagamento
-- ===================================
CREATE TABLE formas_pagamento (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(200),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir formas de pagamento padrão
INSERT INTO formas_pagamento (nome, descricao) VALUES 
('CASH', 'Pagamento em dinheiro'),
('EMOLA', 'Pagamento via eMola'),
('MPESA', 'Pagamento via M-Pesa'),
('POS', 'Pagamento via POS/Cartão');

-- ===================================
-- TABELA: setores
-- ===================================
CREATE TABLE setores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dados de exemplo
INSERT INTO setores (nome, descricao) VALUES 
('RESTAURANTE', 'Setor de preparação de alimentos'),
('ARMAZEM', 'Setor de bebidas'),
('ARMAZEM 2', 'Setor de atendimento e vendas');

-- ===================================
-- TABELA: areas
-- ===================================
CREATE TABLE areas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dados de exemplo
INSERT INTO areas (nome, descricao) VALUES 
('BAR', 'Área principal do restaurante'),
('COZINHA', 'Área externa com vista'),
('GERAL', 'Área reservada para clientes especiais');

-- ===================================
-- ATUALIZAR TABELA VENDAS
-- Adicionar forma de pagamento
-- ===================================
ALTER TABLE vendas ADD COLUMN forma_pagamento_id INTEGER REFERENCES formas_pagamento(id);

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View: Vendas com forma de pagamento
CREATE VIEW v_vendas_completo AS
SELECT 
    v.*,
    fp.nome as forma_pagamento_nome
FROM vendas v
LEFT JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id;

-- View: Setores ativos
CREATE VIEW v_setores_ativos AS
SELECT * FROM setores WHERE ativo = true ORDER BY nome;

-- View: Áreas ativas
CREATE VIEW v_areas_ativas AS
SELECT * FROM areas WHERE ativo = true ORDER BY nome;

-- ===================================
-- ÍNDICES
-- ===================================
CREATE INDEX idx_vendas_forma_pagamento ON vendas(forma_pagamento_id);
CREATE INDEX idx_setores_ativo ON setores(ativo);
CREATE INDEX idx_areas_ativo ON areas(ativo);
```

### 3. Verificar se Foi Criado

```sql
-- Ver todas as tabelas
\dt

-- Ver dados da empresa
SELECT * FROM empresa;

-- Ver formas de pagamento
SELECT * FROM formas_pagamento;

-- Ver setores
SELECT * FROM setores;

-- Ver áreas
SELECT * FROM areas;

-- Sair
\q
```

### ✅ Checkpoint Fase 1

- [ ] Tabelas criadas sem erros
- [ ] Dados de exemplo inseridos
- [ ] Views criadas
- [ ] Consegue ver os dados

---

## 📱 FASE 2: Models Flutter

### 1. Empresa Model

Crie `lib/app/data/models/empresa_model.dart`:

```dart
class EmpresaModel {
  final int? id;
  final String nome;
  final String? nuit;
  final String? endereco;
  final String? cidade;
  final String? email;
  final String? contacto;
  final String? logoUrl;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmpresaModel({
    this.id,
    required this.nome,
    this.nuit,
    this.endereco,
    this.cidade,
    this.email,
    this.contacto,
    this.logoUrl,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EmpresaModel.fromMap(Map<String, dynamic> map) {
    return EmpresaModel(
      id: map['id'],
      nome: map['nome'],
      nuit: map['nuit'],
      endereco: map['endereco'],
      cidade: map['cidade'],
      email: map['email'],
      contacto: map['contacto'],
      logoUrl: map['logo_url'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'nuit': nuit,
      'endereco': endereco,
      'cidade': cidade,
      'email': email,
      'contacto': contacto,
      'logo_url': logoUrl,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Empresa(id: $id, nome: $nome, nuit: $nuit)';
}
```

### 2. Forma Pagamento Model

Crie `lib/app/data/models/forma_pagamento_model.dart`:

```dart
class FormaPagamentoModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;

  FormaPagamentoModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
  });

  factory FormaPagamentoModel.fromMap(Map<String, dynamic> map) {
    return FormaPagamentoModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'FormaPagamento(id: $id, nome: $nome)';
}
```

### 3. Setor Model

Crie `lib/app/data/models/setor_model.dart`:

```dart
class SetorModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;

  SetorModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
  });

  factory SetorModel.fromMap(Map<String, dynamic> map) {
    return SetorModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Setor(id: $id, nome: $nome)';
}
```

### 4. Area Model

Crie `lib/app/data/models/area_model.dart`:

```dart
class AreaModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;

  AreaModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
  });

  factory AreaModel.fromMap(Map<String, dynamic> map) {
    return AreaModel(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Area(id: $id, nome: $nome)';
}
```

### 5. Atualizar Venda Model

Edite `lib/app/data/models/venda_model.dart`:

Adicione o campo `formaPagamentoId`:

```dart
import 'item_venda_model.dart';

class VendaModel {
  final int? id;
  final String numero;
  final double total;
  final DateTime dataVenda;
  final String? terminal;
  final int? formaPagamentoId; // ⭐ NOVO
  
  // Itens da venda
  final List<ItemVendaModel>? itens;
  
  // Campo adicional para joins
  final String? formaPagamentoNome; // ⭐ NOVO

  VendaModel({
    this.id,
    required this.numero,
    required this.total,
    required this.dataVenda,
    this.terminal,
    this.formaPagamentoId, // ⭐ NOVO
    this.itens,
    this.formaPagamentoNome, // ⭐ NOVO
  });

  factory VendaModel.fromMap(Map<String, dynamic> map) {
    return VendaModel(
      id: map['id'],
      numero: map['numero'],
      total: double.parse(map['total'].toString()),
      dataVenda: DateTime.parse(map['data_venda'].toString()),
      terminal: map['terminal'],
      formaPagamentoId: map['forma_pagamento_id'], // ⭐ NOVO
      formaPagamentoNome: map['forma_pagamento_nome'], // ⭐ NOVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'total': total,
      'data_venda': dataVenda.toIso8601String(),
      'terminal': terminal,
      'forma_pagamento_id': formaPagamentoId, // ⭐ NOVO
    };
  }
}
```

### ✅ Checkpoint Fase 2

- [ ] Todos os models criados
- [ ] Imports corretos
- [ ] Sem erros de compilação

---

## 🔧 FASE 3: Repositories

### 1. Empresa Repository

Crie `lib/app/data/repositories/empresa_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/empresa_model.dart';

class EmpresaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  /// Buscar dados da empresa (sempre retorna o primeiro registro)
  Future<EmpresaModel?> buscarDados() async {
    final result = await _db.query('''
      SELECT * FROM empresa WHERE ativo = true LIMIT 1
    ''');
    
    if (result.isEmpty) return null;
    return EmpresaModel.fromMap(result.first);
  }
  
  /// Atualizar dados da empresa
  Future<void> atualizar(int id, EmpresaModel empresa) async {
    await _db.execute('''
      UPDATE empresa 
      SET nome = @nome,
          nuit = @nuit,
          endereco = @endereco,
          cidade = @cidade,
          email = @email,
          contacto = @contacto,
          logo_url = @logo_url,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...empresa.toMap(),
      'id': id,
    });
  }
}
```

### 2. Forma Pagamento Repository

Crie `lib/app/data/repositories/forma_pagamento_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/forma_pagamento_model.dart';

class FormaPagamentoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Future<List<FormaPagamentoModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM formas_pagamento 
      WHERE ativo = true 
      ORDER BY nome
    ''');
    
    return result.map((map) => FormaPagamentoModel.fromMap(map)).toList();
  }
  
  Future<FormaPagamentoModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM formas_pagamento WHERE id = @id
    ''', parameters: {'id': id});
    
    if (result.isEmpty) return null;
    return FormaPagamentoModel.fromMap(result.first);
  }
  
  Future<int> inserir(FormaPagamentoModel forma) async {
    return await _db.insert('''
      INSERT INTO formas_pagamento (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: forma.toMap());
  }
  
  Future<void> atualizar(int id, FormaPagamentoModel forma) async {
    await _db.execute('''
      UPDATE formas_pagamento 
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...forma.toMap(),
      'id': id,
    });
  }
  
  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE formas_pagamento SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
```

### 3. Setor Repository

Crie `lib/app/data/repositories/setor_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/setor_model.dart';

class SetorRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Future<List<SetorModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM setores 
      WHERE ativo = true 
      ORDER BY nome
    ''');
    
    return result.map((map) => SetorModel.fromMap(map)).toList();
  }
  
  Future<SetorModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM setores WHERE id = @id
    ''', parameters: {'id': id});
    
    if (result.isEmpty) return null;
    return SetorModel.fromMap(result.first);
  }
  
  Future<int> inserir(SetorModel setor) async {
    return await _db.insert('''
      INSERT INTO setores (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: setor.toMap());
  }
  
  Future<void> atualizar(int id, SetorModel setor) async {
    await _db.execute('''
      UPDATE setores 
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...setor.toMap(),
      'id': id,
    });
  }
  
  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE setores SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
```

### 4. Area Repository

Crie `lib/app/data/repositories/area_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/area_model.dart';

class AreaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Future<List<AreaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM areas 
      WHERE ativo = true 
      ORDER BY nome
    ''');
    
    return result.map((map) => AreaModel.fromMap(map)).toList();
  }
  
  Future<AreaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM areas WHERE id = @id
    ''', parameters: {'id': id});
    
    if (result.isEmpty) return null;
    return AreaModel.fromMap(result.first);
  }
  
  Future<int> inserir(AreaModel area) async {
    return await _db.insert('''
      INSERT INTO areas (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: area.toMap());
  }
  
  Future<void> atualizar(int id, AreaModel area) async {
    await _db.execute('''
      UPDATE areas 
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...area.toMap(),
      'id': id,
    });
  }
  
  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE areas SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
```

### 5. Atualizar Venda Repository

Edite `lib/app/data/repositories/venda_repository.dart`:

Modifique o método `registrarVenda` para incluir forma de pagamento:

```dart
Future<int> registrarVenda(
  VendaModel venda, 
  List<ItemVendaModel> itens,
) async {
  return await _db.transaction((conn) async {
    // 1. Inserir venda
    final vendaResult = await conn.execute(
      Sql.named('''
        INSERT INTO vendas (numero, total, terminal, forma_pagamento_id)
        VALUES (@numero, @total, @terminal, @forma_pagamento_id)
        RETURNING id
      '''),
      parameters: venda.toMap(),
    );
    
    final vendaId = vendaResult.first[0] as int;
    
    // 2. Inserir itens (resto do código permanece igual)
    for (var item in itens) {
      await conn.execute(
        Sql.named('''
          INSERT INTO itens_venda (venda_id, produto_id, quantidade, preco_unitario, subtotal)
          VALUES (@venda_id, @produto_id, @quantidade, @preco_unitario, @subtotal)
        '''),
        parameters: {
          'venda_id': vendaId,
          ...item.toMap(),
        },
      );
      
      // 3. Atualizar estoque
      await conn.execute(
        Sql.named('''
          UPDATE produtos 
          SET estoque = estoque - @quantidade 
          WHERE id = @produto_id
        '''),
        parameters: {
          'quantidade': item.quantidade,
          'produto_id': item.produtoId,
        },
      );
    }
    
    return vendaId;
  });
}
```

### ✅ Checkpoint Fase 3

- [ ] Todos os repositories criados
- [ ] Métodos CRUD completos
- [ ] Sem erros de compilação

---

## 🎨 FASE 4: Admin com Drawer

### 1. Atualizar Admin Controller

Edite `lib/app/modules/admin/controllers/admin_controller.dart`:

Adicione os novos imports e variáveis:

```dart
import 'package:get/get.dart';
import '../../../data/models/familia_model.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/empresa_model.dart';
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/models/setor_model.dart';
import '../../../data/models/area_model.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/repositories/empresa_repository.dart';
import '../../../data/repositories/forma_pagamento_repository.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/repositories/area_repository.dart';

class AdminController extends GetxController {
  final FamiliaRepository _familiaRepo = FamiliaRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  final FormaPagamentoRepository _formaPagamentoRepo = FormaPagamentoRepository();
  final SetorRepository _setorRepo = SetorRepository();
  final AreaRepository _areaRepo = AreaRepository();
  
  final familias = <FamiliaModel>[].obs;
  final produtos = <ProdutoModel>[].obs;
  final empresa = Rxn<EmpresaModel>();
  final formasPagamento = <FormaPagamentoModel>[].obs;
  final setores = <SetorModel>[].obs;
  final areas = <AreaModel>[].obs;
  final isLoading = false.obs;
  
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
  
  // ===== FAMÍLIA (métodos já existentes - manter) =====
  Future<void> adicionarFamilia(String nome, String? descricao) async {
    try {
      final familia = FamiliaModel(nome: nome, descricao: descricao);
      await _familiaRepo.inserir(familia);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Família adicionada!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar família: $e');
    }
  }
  
  Future<void> editarFamilia(int id, String nome, String? descricao) async {
    try {
      final familia = FamiliaModel(nome: nome, descricao: descricao);
      await _familiaRepo.atualizar(id, familia);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Família atualizada!');
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
  
  // ===== PRODUTO (métodos já existentes - manter) =====
  Future<void> adicionarProduto(ProdutoModel produto) async {
    try {
      await _produtoRepo.inserir(produto);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Produto adicionado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao adicionar produto: $e');
    }
  }
  
  Future<void> editarProduto(int id, ProdutoModel produto) async {
    try {
      await _produtoRepo.atualizar(id, produto);
      await carregarDados();
      Get.back();
      Get.snackbar('Sucesso', 'Produto atualizado!');
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao atualizar produto: $e');
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
}
```

### 2. Nova Admin Page com Drawer

Edite `lib/app/modules/admin/admin_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/admin_controller.dart';
import 'views/familias_tab.dart';
import 'views/produtos_tab.dart';
import 'views/empresa_tab.dart';
import 'views/formas_pagamento_tab.dart';
import 'views/setores_tab.dart';
import 'views/areas_tab.dart';

class AdminPage extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());
  final RxInt selectedIndex = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(_getTitulo())),
      ),
      drawer: _buildDrawer(),
      body: Obx(() => _getBody()),
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Get.theme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'ADMINISTRAÇÃO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(0, Icons.business, 'Dados da Empresa'),
          Divider(),
          _buildMenuItem(1, Icons.category, 'Famílias'),
          _buildMenuItem(2, Icons.inventory, 'Produtos'),
          Divider(),
          _buildMenuItem(3, Icons.payment, 'Formas de Pagamento'),
          _buildMenuItem(4, Icons.store, 'Setores'),
          _buildMenuItem(5, Icons.location_on, 'Áreas'),
          Divider(),
          ListTile(
            leading: Icon(Icons.arrow_back, color: Colors.red),
            title: Text('Voltar', style: TextStyle(color: Colors.red)),
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(int index, IconData icon, String title) {
    return Obx(() => ListTile(
      selected: selectedIndex.value == index,
      selectedTileColor: Get.theme.primaryColor.withOpacity(0.1),
      leading: Icon(
        icon,
        color: selectedIndex.value == index 
            ? Get.theme.primaryColor 
            : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selectedIndex.value == index 
              ? FontWeight.bold 
              : FontWeight.normal,
          color: selectedIndex.value == index 
              ? Get.theme.primaryColor 
              : Colors.black,
        ),
      ),
      onTap: () {
        selectedIndex.value = index;
        Get.back(); // Fechar drawer
      },
    ));
  }
  
  String _getTitulo() {
    switch (selectedIndex.value) {
      case 0: return 'EMPRESA';
      case 1: return 'FAMÍLIAS';
      case 2: return 'PRODUTOS';
      case 3: return 'FORMAS DE PAGAMENTO';
      case 4: return 'SETORES';
      case 5: return 'ÁREAS';
      default: return 'ADMIN';
    }
  }
  
  Widget _getBody() {
    switch (selectedIndex.value) {
      case 0: return EmpresaTab();
      case 1: return FamiliasTab();
      case 2: return ProdutosTab();
      case 3: return FormasPagamentoTab();
      case 4: return SetoresTab();
      case 5: return AreasTab();
      default: return EmpresaTab();
    }
  }
}
```

### ✅ Checkpoint Fase 4

- [ ] Admin controller atualizado
- [ ] Admin page com drawer criada
- [ ] Menu lateral funciona
- [ ] Consegue navegar entre seções

---

## 📝 FASE 5: CRUD Completo - Todas Tabelas

### 1. Empresa Tab

**IMPORTANTE:** As tabs `FamiliasTab` e `ProdutosTab` já existem do guia anterior! Não precisa recriar. Apenas certifique-se de que os imports estão corretos na `AdminPage`.

Crie `lib/app/modules/admin/views/empresa_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class EmpresaTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      
      final empresa = controller.empresa.value;
      
      if (empresa == null) {
        return Center(child: Text('Dados da empresa não encontrados'));
      }
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, size: 40, color: Get.theme.primaryColor),
                    SizedBox(width: 16),
                    Text(
                      'DADOS DA EMPRESA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogEmpresa(empresa),
                      icon: Icon(Icons.edit),
                      label: Text('EDITAR'),
                    ),
                  ],
                ),
                Divider(height: 30),
                _buildInfoRow('Nome:', empresa.nome),
                _buildInfoRow('NUIT:', empresa.nuit ?? 'N/A'),
                _buildInfoRow('Endereço:', empresa.endereco ?? 'N/A'),
                _buildInfoRow('Cidade:', empresa.cidade ?? 'N/A'),
                _buildInfoRow('Email:', empresa.email ?? 'N/A'),
                _buildInfoRow('Contacto:', empresa.contacto ?? 'N/A'),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  void _mostrarDialogEmpresa(empresa) {
    final nomeController = TextEditingController(text: empresa.nome);
    final nuitController = TextEditingController(text: empresa.nuit ?? '');
    final enderecoController = TextEditingController(text: empresa.endereco ?? '');
    final cidadeController = TextEditingController(text: empresa.cidade ?? '');
    final emailController = TextEditingController(text: empresa.email ?? '');
    final contactoController = TextEditingController(text: empresa.contacto ?? '');
    
    Get.dialog(
      AlertDialog(
        title: Text('Editar Dados da Empresa'),
        content: SingleChildScrollView(
          child: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Empresa *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: nuitController,
                  decoration: InputDecoration(
                    labelText: 'NUIT',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: enderecoController,
                  decoration: InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: cidadeController,
                  decoration: InputDecoration(
                    labelText: 'Cidade',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: contactoController,
                  decoration: InputDecoration(
                    labelText: 'Contacto',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
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
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }
              
              final empresaAtualizada = EmpresaModel(
                nome: nomeController.text,
                nuit: nuitController.text,
                endereco: enderecoController.text,
                cidade: cidadeController.text,
                email: emailController.text,
                contacto: contactoController.text,
              );
              
              controller.atualizarEmpresa(empresaAtualizada);
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Formas Pagamento Tab

Crie `lib/app/modules/admin/views/formas_pagamento_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class FormasPagamentoTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.formasPagamento.isEmpty) {
          return Center(child: Text('Nenhuma forma de pagamento cadastrada'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.formasPagamento.length,
          itemBuilder: (context, index) {
            final forma = controller.formasPagamento[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(_getIcon(forma.nome), color: Colors.white),
                ),
                title: Text(
                  forma.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(forma.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(forma),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(forma.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialog(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  IconData _getIcon(String nome) {
    switch (nome.toUpperCase()) {
      case 'CASH': return Icons.money;
      case 'EMOLA': return Icons.phone_android;
      case 'MPESA': return Icons.phone_iphone;
      case 'POS': return Icons.credit_card;
      default: return Icons.payment;
    }
  }
  
  void _mostrarDialog(forma) {
    final nomeController = TextEditingController(text: forma?.nome ?? '');
    final descController = TextEditingController(text: forma?.descricao ?? '');
    
    Get.dialog(
      AlertDialog(
        title: Text(forma == null ? 'Nova Forma de Pagamento' : 'Editar Forma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }
              
              if (forma == null) {
                controller.adicionarFormaPagamento(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarFormaPagamento(
                  forma.id!,
                  nomeController.text,
                  descController.text,
                );
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
        content: Text('Deseja realmente remover esta forma de pagamento?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarFormaPagamento(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
```

### 3. Setores Tab

Crie `lib/app/modules/admin/views/setores_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class SetoresTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.setores.isEmpty) {
          return Center(child: Text('Nenhum setor cadastrado'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.setores.length,
          itemBuilder: (context, index) {
            final setor = controller.setores[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(Icons.store, color: Colors.white),
                ),
                title: Text(
                  setor.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(setor.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(setor),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(setor.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialog(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _mostrarDialog(setor) {
    final nomeController = TextEditingController(text: setor?.nome ?? '');
    final descController = TextEditingController(text: setor?.descricao ?? '');
    
    Get.dialog(
      AlertDialog(
        title: Text(setor == null ? 'Novo Setor' : 'Editar Setor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }
              
              if (setor == null) {
                controller.adicionarSetor(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarSetor(
                  setor.id!,
                  nomeController.text,
                  descController.text,
                );
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
        content: Text('Deseja realmente remover este setor?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarSetor(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
```

### 4. Áreas Tab

Crie `lib/app/modules/admin/views/areas_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class AreasTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.areas.isEmpty) {
          return Center(child: Text('Nenhuma área cadastrada'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.areas.length,
          itemBuilder: (context, index) {
            final area = controller.areas[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(Icons.location_on, color: Colors.white),
                ),
                title: Text(
                  area.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(area.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(area),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(area.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialog(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _mostrarDialog(area) {
    final nomeController = TextEditingController(text: area?.nome ?? '');
    final descController = TextEditingController(text: area?.descricao ?? '');
    
    Get.dialog(
      AlertDialog(
        title: Text(area == null ? 'Nova Área' : 'Editar Área'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }
              
              if (area == null) {
                controller.adicionarArea(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarArea(
                  area.id!,
                  nomeController.text,
                  descController.text,
                );
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
        content: Text('Deseja realmente remover esta área?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarArea(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
```

### ✅ Checkpoint Fase 5

- [ ] Todas as tabs criadas
- [ ] CRUD funciona em todas
- [ ] Diálogos de edição funcionam
- [ ] Confirmação de delete funciona

---

## 💳 FASE 6: Formas de Pagamento na Venda

### 1. Atualizar Vendas Controller

Edite `lib/app/modules/vendas/controllers/vendas_controller.dart`:

Adicione os imports:

```dart
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/repositories/forma_pagamento_repository.dart';
```

Adicione as variáveis:

```dart
final FormaPagamentoRepository _formaPagamentoRepo = FormaPagamentoRepository();
final formasPagamento = <FormaPagamentoModel>[].obs;
final formaPagamentoSelecionada = Rxn<FormaPagamentoModel>();
```

No método `carregarDados()`, adicione:

```dart
Future<void> carregarDados() async {
  isLoading.value = true;
  try {
    familias.value = await _familiaRepo.listarTodas();
    produtos.value = await _produtoRepo.listarTodos();
    formasPagamento.value = await _formaPagamentoRepo.listarTodas(); // ⭐ NOVO
    produtosFiltrados.value = produtos;
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao carregar dados: $e');
  } finally {
    isLoading.value = false;
  }
}
```

Modifique o método `finalizarVenda()`:

```dart
Future<void> finalizarVenda() async {
  if (carrinho.isEmpty) {
    Get.snackbar('Erro', 'Carrinho vazio');
    return;
  }
  
  // Resetar forma de pagamento
  formaPagamentoSelecionada.value = null;
  
  // Mostrar dialog de forma de pagamento
  await Get.dialog(
    AlertDialog(
      title: Text('Forma de Pagamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selecione a forma de pagamento:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ...formasPagamento.map((forma) {
            return Obx(() => RadioListTile<FormaPagamentoModel>(
              title: Text(
                forma.nome,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(forma.descricao ?? ''),
              value: forma,
              groupValue: formaPagamentoSelecionada.value,
              onChanged: (value) {
                formaPagamentoSelecionada.value = value;
              },
            ));
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formaPagamentoSelecionada.value == null) {
              Get.snackbar('Erro', 'Selecione uma forma de pagamento');
              return;
            }
            Get.back();
            _processarVenda();
          },
          child: Text('CONFIRMAR'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

Future<void> _processarVenda() async {
  try {
    // Gerar número da venda
    final numero = 'VD${DateTime.now().millisecondsSinceEpoch}';
    
    // Criar venda
    final venda = VendaModel(
      numero: numero,
      total: totalCarrinho,
      dataVenda: DateTime.now(),
      terminal: 'CAIXA-01',
      formaPagamentoId: formaPagamentoSelecionada.value!.id, // ⭐ NOVO
    );
    
    // Criar itens
    final itens = carrinho.map((item) {
      return ItemVendaModel(
        produtoId: item.produto.id!,
        quantidade: item.quantidade,
        precoUnitario: item.produto.preco,
        subtotal: item.subtotal,
        produtoNome: item.produto.nome,
      );
    }).toList();
    
    // Registrar venda no banco
    final vendaId = await _vendaRepo.registrarVenda(venda, itens);
    
    // Atualizar ID da venda
    final vendaFinal = VendaModel(
      id: vendaId,
      numero: numero,
      total: totalCarrinho,
      dataVenda: DateTime.now(),
      terminal: 'CAIXA-01',
      formaPagamentoId: formaPagamentoSelecionada.value!.id,
      formaPagamentoNome: formaPagamentoSelecionada.value!.nome,
    );
    
    Get.snackbar(
      'Sucesso',
      'Venda #$vendaId registrada!',
      backgroundColor: Get.theme.primaryColor,
      colorText: Colors.white,
    );
    
    // IMPRIMIR CUPOM
    Get.dialog(
      AlertDialog(
        title: Text('Impressão'),
        content: Text('Deseja imprimir o cupom?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _finalizarVendaSemImprimir();
            },
            child: Text('NÃO'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _imprimirEFinalizar(vendaFinal, itens);
            },
            child: Text('SIM'),
          ),
        ],
      ),
    );
    
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao finalizar venda: $e');
  }
}
```

### ✅ Checkpoint Fase 6

- [ ] Dialog de forma de pagamento aparece
- [ ] Consegue selecionar forma
- [ ] Venda registra com forma de pagamento
- [ ] Verifica no banco que forma foi salva

---

## 🖨️ FASE 7: Impressão com Dados da Empresa

### 1. Atualizar Printer Service

Edite `lib/core/utils/printer_service.dart`:

Adicione os imports:

```dart
import '../../app/data/models/empresa_model.dart';
```

Modifique a assinatura do método `imprimirCupom`:

```dart
static Future<bool> imprimirCupom(
  VendaModel venda,
  List<ItemVendaModel> itens,
  EmpresaModel? empresa, // ⭐ NOVO parâmetro
) async {
  try {
    final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load());
    
    final result = await printer.connect(printerIp, port: printerPort);
    
    if (result != PosPrintResult.success) {
      print('❌ Erro ao conectar na impressora: $result');
      return false;
    }
    
    // Gerar conteúdo do cupom
    await _gerarCupom(printer, venda, itens, empresa); // ⭐ NOVO parâmetro
    
    printer.disconnect();
    
    print('✅ Cupom impresso com sucesso!');
    return true;
    
  } catch (e) {
    print('❌ Erro ao imprimir: $e');
    return false;
  }
}
```

Modifique o método `_gerarCupom`:

```dart
static Future<void> _gerarCupom(
  NetworkPrinter printer,
  VendaModel venda,
  List<ItemVendaModel> itens,
  EmpresaModel? empresa, // ⭐ NOVO parâmetro
) async {
  // CABEÇALHO COM DADOS DA EMPRESA
  if (empresa != null) {
    printer.text(
      empresa.nome,
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    
    if (empresa.nuit != null && empresa.nuit!.isNotEmpty) {
      printer.text(
        'NUIT: ${empresa.nuit}',
        styles: PosStyles(align: PosAlign.center),
      );
    }
    
    if (empresa.endereco != null && empresa.endereco!.isNotEmpty) {
      printer.text(
        empresa.endereco!,
        styles: PosStyles(align: PosAlign.center),
      );
    }
    
    if (empresa.cidade != null && empresa.cidade!.isNotEmpty) {
      printer.text(
        empresa.cidade!,
        styles: PosStyles(align: PosAlign.center),
      );
    }
    
    if (empresa.contacto != null && empresa.contacto!.isNotEmpty) {
      printer.text(
        'Tel: ${empresa.contacto}',
        styles: PosStyles(align: PosAlign.center),
      );
    }
    
    if (empresa.email != null && empresa.email!.isNotEmpty) {
      printer.text(
        empresa.email!,
        styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }
  } else {
    // Fallback se não houver dados da empresa
    printer.text(
      'SISTEMA PDV',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
  }
  
  printer.emptyLines(1);
  printer.hr();
  printer.emptyLines(1);
  
  // INFORMAÇÕES DA VENDA
  printer.row([
    PosColumn(text: 'Cupom:', width: 4),
    PosColumn(text: venda.numero, width: 8, styles: PosStyles(bold: true)),
  ]);
  
  printer.row([
    PosColumn(text: 'Data:', width: 4),
    PosColumn(
      text: Formatters.formatarData(venda.dataVenda),
      width: 8,
    ),
  ]);
  
  printer.row([
    PosColumn(text: 'Terminal:', width: 4),
    PosColumn(text: venda.terminal ?? 'CAIXA-01', width: 8),
  ]);
  
  // ⭐ NOVO: Forma de Pagamento
  if (venda.formaPagamentoNome != null) {
    printer.row([
      PosColumn(text: 'Pagamento:', width: 4),
      PosColumn(
        text: venda.formaPagamentoNome!,
        width: 8,
        styles: PosStyles(bold: true),
      ),
    ]);
  }
  
  printer.emptyLines(1);
  printer.hr();
  printer.emptyLines(1);
  
  // CABEÇALHO DOS ITENS
  printer.row([
    PosColumn(text: 'Item', width: 6, styles: PosStyles(bold: true)),
    PosColumn(text: 'Qtd', width: 2, styles: PosStyles(bold: true, align: PosAlign.right)),
    PosColumn(text: 'Valor', width: 4, styles: PosStyles(bold: true, align: PosAlign.right)),
  ]);
  
  printer.hr(ch: '-');
  
  // ITENS
  for (var item in itens) {
    printer.text(
      item.produtoNome ?? 'Produto',
      styles: PosStyles(bold: true),
    );
    
    printer.row([
      PosColumn(text: '', width: 6),
      PosColumn(
        text: '${item.quantidade}x',
        width: 2,
        styles: PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: _formatarValor(item.subtotal),
        width: 4,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    
    if (item.quantidade > 1) {
      printer.text(
        '  ${_formatarValor(item.precoUnitario)} cada',
        styles: PosStyles(fontType: PosFontType.fontB),
      );
    }
    
    printer.emptyLines(1);
  }
  
  printer.hr();
  printer.emptyLines(1);
  
  // TOTAL
  printer.row([
    PosColumn(
      text: 'TOTAL:',
      width: 8,
      styles: PosStyles(
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ),
    PosColumn(
      text: _formatarValor(venda.total),
      width: 4,
      styles: PosStyles(
        bold: true,
        align: PosAlign.right,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ),
  ]);
  
  printer.emptyLines(2);
  printer.hr();
  printer.emptyLines(1);
  
  // RODAPÉ
  printer.text(
    'Obrigado pela preferencia!',
    styles: PosStyles(align: PosAlign.center),
  );
  
  printer.text(
    'Volte sempre!',
    styles: PosStyles(align: PosAlign.center, bold: true),
  );
  
  printer.emptyLines(1);
  
  if (empresa != null) {
    printer.text(
      empresa.nome,
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
  }
  
  // Cortar papel
  printer.cut();
}
```

### 2. Atualizar Vendas Controller para Passar Dados da Empresa

Edite `lib/app/modules/vendas/controllers/vendas_controller.dart`:

Adicione as variáveis:

```dart
import '../../../data/models/empresa_model.dart';
import '../../../data/repositories/empresa_repository.dart';

final EmpresaRepository _empresaRepo = EmpresaRepository();
final empresa = Rxn<EmpresaModel>();
```

No `carregarDados()`:

```dart
empresa.value = await _empresaRepo.buscarDados();
```

No método `_imprimirEFinalizar`:

```dart
Future<void> _imprimirEFinalizar(VendaModel venda, List<ItemVendaModel> itens) async {
  Get.dialog(
    Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );
  
  final sucesso = await PrinterService.imprimirCupom(
    venda, 
    itens, 
    empresa.value, // ⭐ NOVO: Passar dados da empresa
  );
  
  Get.back();
  
  if (sucesso) {
    Get.snackbar(
      'Sucesso',
      'Cupom impresso!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } else {
    Get.snackbar(
      'Aviso',
      'Erro ao imprimir. Venda registrada.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
  
  _finalizarVendaSemImprimir();
}
```

### ✅ Checkpoint Fase 7

- [ ] Cupom imprime com dados da empresa
- [ ] Mostra NUIT, endereço, cidade
- [ ] Mostra forma de pagamento
- [ ] Layout está correto

---

## ✅ FASE 8: Testes Finais

### 1. Checklist Completo

#### **Banco de Dados**
- [ ] Tabela `empresa` criada com dados
- [ ] Tabela `formas_pagamento` criada
- [ ] Tabela `setores` criada
- [ ] Tabela `areas` criada
- [ ] Campo `forma_pagamento_id` em `vendas`
- [ ] Views criadas corretamente

#### **Admin**
- [ ] Drawer funciona
- [ ] CRUD Empresa funciona
- [ ] CRUD Formas de Pagamento funciona
- [ ] CRUD Setores funciona
- [ ] CRUD Áreas funciona
- [ ] CRUD Famílias funciona
- [ ] CRUD Produtos funciona

#### **Vendas**
- [ ] Dialog de forma de pagamento aparece
- [ ] Consegue selecionar forma
- [ ] Venda registra corretamente
- [ ] Forma de pagamento salva no banco

#### **Impressão**
- [ ] Dados da empresa aparecem no cupom
- [ ] Forma de pagamento aparece
- [ ] Layout está correto (80mm)
- [ ] Todas informações visíveis

### 2. Testes no PostgreSQL

```bash
# Conectar
psql -U postgres -d pdv_system

# Ver dados da empresa
SELECT * FROM empresa;

# Ver formas de pagamento
SELECT * FROM formas_pagamento;

# Ver setores e áreas
SELECT * FROM setores;
SELECT * FROM areas;

# Ver vendas com forma de pagamento
SELECT 
    v.numero,
    v.total,
    fp.nome as forma_pagamento,
    v.data_venda
FROM vendas v
LEFT JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
ORDER BY v.data_venda DESC
LIMIT 10;

# Sair
\q
```

### 3. Teste Completo no Sistema

**Passo a Passo:**

1. **Admin - Empresa**
   - Editar dados da empresa
   - Salvar
   - Verificar que salvou

2. **Admin - Formas de Pagamento**
   - Criar nova forma (ex: PIX)
   - Editar forma existente
   - Ver lista atualizada

3. **Admin - Setores**
   - Criar novo setor
   - Editar
   - Deletar

4. **Admin - Áreas**
   - Criar nova área
   - Editar
   - Deletar

5. **Vendas**
   - Adicionar produtos ao carrinho
   - Clicar em "Finalizar Venda"
   - Selecionar forma de pagamento
   - Confirmar
   - Escolher imprimir
   - Verificar cupom impresso

6. **Verificar no Banco**
   ```sql
   SELECT * FROM vendas ORDER BY id DESC LIMIT 1;
   ```
   - Deve mostrar a forma de pagamento

### 4. Problemas Comuns

**Erro: "forma_pagamento_id does not exist"**
```sql
-- Executar novamente:
ALTER TABLE vendas ADD COLUMN forma_pagamento_id INTEGER REFERENCES formas_pagamento(id);
```

**Erro: "Drawer não abre"**
- Verifique se `AdminPage` tem `Scaffold` com `drawer`
- Verifique imports das tabs

**Erro: "Dados da empresa null"**
```sql
-- Verificar se existe registro:
SELECT * FROM empresa;

-- Se não existir, inserir:
INSERT INTO empresa (nome, nuit) VALUES ('Sua Empresa', '123456789');
```

---

## 🎉 Conclusão

Você agora tem um sistema **completo** com:

✅ **Dados da Empresa** configuráveis  
✅ **Formas de Pagamento** customizáveis  
✅ **Setores e Áreas** gerenciáveis  
✅ **Admin com Drawer** organizado  
✅ **CRUD completo** de todas tabelas  
✅ **Impressão** com dados da empresa  
✅ **Forma de pagamento** na venda

### 📝 Próximas Funcionalidades Sugeridas

- [ ] Relatórios de vendas por forma de pagamento
- [ ] Relatórios por setor/área
- [ ] Múltiplos usuários com login
- [ ] Controle de permissões
- [ ] Comandas por área
- [ ] Transferência entre áreas
- [ ] Histórico de vendas
- [ ] Dashboard com gráficos

---

**Desenvolvido com ❤️ para Frentex e Serviços**

*Expansão v2.0 - Novembro 2025*
