# 🚀 GUIA COMPLETO - Sistema PDV Flutter + PostgreSQL + GetX

> **Autor:** Assistente Claude  
> **Data:** Novembro 2025  
> **Projeto:** Sistema de Vendas (PDV) para Restaurante/Mercearia  
> **Tecnologias:** Flutter, GetX, PostgreSQL, Impressão Térmica 80mm

---

## 📋 Índice

1. [Preparação Inicial](#fase-0-preparação-inicial)
2. [Configurar PostgreSQL](#fase-1-configurar-postgresql-no-windows)
3. [Estrutura Flutter](#fase-2-estrutura-do-projeto-flutter)
4. [Repositories e Lógica](#fase-3-repositories-e-controllers)
5. [Telas Principais](#fase-4-telas-principais)
6. [Tela de Admin](#fase-5-tela-de-admin)
7. [Tela de Vendas](#fase-6-tela-de-vendas)
8. [Impressão Térmica](#fase-7-impressão-térmica-80mm)
9. [Testes e Validação](#fase-8-testes-e-validação)

---

## 🎯 FASE 0: Preparação Inicial

### 1. Criar Projeto Flutter

```bash
flutter create pdv_system
cd pdv_system
```

### 2. Adicionar Dependências

Edite `pubspec.yaml`:

```yaml
name: pdv_system
description: Sistema PDV com Flutter e PostgreSQL
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Estado e Navegação
  get: ^4.6.6
  
  # Banco de Dados
  postgres: ^3.0.0
  
  # Impressão Térmica
  esc_pos_utils: ^1.1.0
  esc_pos_printer: ^4.1.0
  network_info_plus: ^5.0.0
  ping_discover_network: ^0.0.1
  
  # UI
  flutter_svg: ^2.0.9
  google_fonts: ^6.1.0
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

```bash
flutter pub get
```

### ✅ Teste Fase 0

```bash
flutter doctor
# Todos os checks devem estar OK (Windows, Chrome, VS Code/Android Studio)
```

---

## 🗄️ FASE 1: Configurar PostgreSQL no Windows

### 1. Instalar PostgreSQL

- **Download:** https://www.postgresql.org/download/windows/
- **Versão:** PostgreSQL 15 ou superior
- **Configurações na instalação:**
  - Porta: `5432`
  - Senha do postgres: **ANOTE SUA SENHA!**
  - Locale: `Portuguese_Brazil.1252`
  - Instalar Stack Builder: `Sim`

### 2. Verificar Instalação

Abra **CMD** ou **PowerShell**:

```bash
# Testar conexão
psql -U postgres -h localhost

# Digite a senha quando solicitado
# Se conectou, você verá: postgres=#
# Para sair: \q
```

### 3. Criar Database e Usuário

No terminal SQL (`psql -U postgres`):

```sql
-- Criar database
CREATE DATABASE pdv_system;

-- Criar usuário específico (mais seguro)
CREATE USER pdv_user WITH PASSWORD 'pdv123';

-- Dar permissões
GRANT ALL PRIVILEGES ON DATABASE pdv_system TO pdv_user;

-- Conectar ao database
\c pdv_system

-- Dar permissões no schema public
GRANT ALL ON SCHEMA public TO pdv_user;

-- Sair
\q
```

### 4. Criar Estrutura do Banco

Crie a pasta `database` na raiz do projeto:

```bash
mkdir database
```

Crie o arquivo `database/schema.sql`:

```sql
-- ===================================
-- SCHEMA PDV SYSTEM
-- ===================================

-- TABELA: familias (categorias de produtos)
CREATE TABLE familias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: produtos
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nome VARCHAR(200) NOT NULL,
    familia_id INTEGER REFERENCES familias(id) ON DELETE SET NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: vendas
CREATE TABLE vendas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    terminal VARCHAR(50)
);

-- TABELA: itens_venda
CREATE TABLE itens_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);

-- ÍNDICES para performance
CREATE INDEX idx_produtos_familia ON produtos(familia_id);
CREATE INDEX idx_produtos_ativo ON produtos(ativo);
CREATE INDEX idx_vendas_data ON vendas(data_venda);
CREATE INDEX idx_itens_venda ON itens_venda(venda_id);

-- ===================================
-- DADOS DE TESTE
-- ===================================

INSERT INTO familias (nome, descricao) VALUES 
('BEBIDAS', 'Bebidas em geral'),
('COMIDAS', 'Pratos e lanches'),
('SOBREMESAS', 'Doces e sobremesas');

INSERT INTO produtos (codigo, nome, familia_id, preco, estoque) VALUES 
('001', 'COCA-COLA 500ML', 1, 50.00, 100),
('002', 'CERVEJA 2M', 1, 80.00, 50),
('003', 'AGUA MINERAL', 1, 30.00, 200),
('004', 'HAMBURGUER', 2, 150.00, 30),
('005', 'PIZZA MARGHERITA', 2, 200.00, 20),
('006', 'FRANGO ASSADO', 2, 180.00, 25),
('007', 'PUDIM', 3, 60.00, 25),
('008', 'SORVETE', 3, 70.00, 40);

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View: Produtos com nome da família
CREATE VIEW v_produtos_completo AS
SELECT 
    p.*,
    f.nome as familia_nome
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id;

-- View: Resumo de vendas
CREATE VIEW v_vendas_resumo AS
SELECT 
    v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    COUNT(iv.id) as total_itens
FROM vendas v
LEFT JOIN itens_venda iv ON v.id = iv.venda_id
GROUP BY v.id, v.numero, v.total, v.data_venda, v.terminal;
```

### 5. Importar Schema

```bash
# No CMD/PowerShell, dentro da pasta do projeto
psql -U postgres -d pdv_system -f database/schema.sql
```

### ✅ Teste Fase 1

```bash
psql -U postgres -d pdv_system

# No PostgreSQL, execute:
SELECT * FROM familias;
SELECT * FROM produtos;
SELECT * FROM v_produtos_completo;

# Deve mostrar os dados de teste!
# Para sair: \q
```

---

## 📱 FASE 2: Estrutura do Projeto Flutter

### 1. Criar Estrutura de Pastas

```bash
# Windows CMD/PowerShell
mkdir lib\app
mkdir lib\app\data
mkdir lib\app\data\models
mkdir lib\app\data\repositories
mkdir lib\app\modules
mkdir lib\app\modules\home
mkdir lib\app\modules\admin
mkdir lib\app\modules\admin\controllers
mkdir lib\app\modules\admin\views
mkdir lib\app\modules\vendas
mkdir lib\app\modules\vendas\controllers
mkdir lib\app\modules\vendas\views
mkdir lib\app\routes
mkdir lib\core
mkdir lib\core\database
mkdir lib\core\theme
mkdir lib\core\utils
```

### 2. Configuração do Banco

Crie `lib/core/database/database_config.dart`:

```dart
class DatabaseConfig {
  // ⚠️ IMPORTANTE: Configure corretamente!
  
  // Se PostgreSQL está na mesma máquina:
  static const String host = 'localhost'; // ou '127.0.0.1'
  
  // Se PostgreSQL está em outro PC da rede:
  // static const String host = '192.168.1.10'; // IP do servidor
  
  static const int port = 5432;
  static const String database = 'pdv_system';
  static const String username = 'postgres';
  static const String password = 'SUA_SENHA_AQUI'; // ⚠️ MUDE AQUI!
  
  // Configurações de conexão
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration queryTimeout = Duration(seconds: 30);
}
```

### 3. Serviço de Conexão

Crie `lib/core/database/database_service.dart`:

```dart
import 'package:postgres/postgres.dart';
import 'package:get/get.dart';
import 'database_config.dart';

class DatabaseService extends GetxService {
  late Connection _connection;
  final RxBool isConnected = false.obs;
  
  Future<DatabaseService> init() async {
    await _connect();
    return this;
  }
  
  Future<void> _connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: DatabaseConfig.host,
          port: DatabaseConfig.port,
          database: DatabaseConfig.database,
          username: DatabaseConfig.username,
          password: DatabaseConfig.password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: DatabaseConfig.connectTimeout,
        ),
      );
      
      isConnected.value = true;
      print('✅ Conectado ao PostgreSQL em ${DatabaseConfig.host}:${DatabaseConfig.port}');
    } catch (e) {
      isConnected.value = false;
      print('❌ Erro ao conectar ao PostgreSQL: $e');
      
      // Tentar reconectar após 5 segundos
      await Future.delayed(Duration(seconds: 5));
      await _connect();
    }
  }
  
  /// Executar query SELECT - retorna lista de mapas
  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await _connection.execute(
        Sql.named(sql),
        parameters: parameters,
      );
      
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      print('❌ Erro na query: $e');
      print('SQL: $sql');
      rethrow;
    }
  }
  
  /// Executar INSERT, UPDATE, DELETE
  Future<void> execute(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _connection.execute(
        Sql.named(sql),
        parameters: parameters,
      );
    } catch (e) {
      print('❌ Erro ao executar: $e');
      print('SQL: $sql');
      rethrow;
    }
  }
  
  /// Executar INSERT e retornar ID gerado
  Future<int> insert(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await _connection.execute(
        Sql.named(sql + ' RETURNING id'),
        parameters: parameters,
      );
      
      if (result.isEmpty) {
        throw Exception('Insert não retornou ID');
      }
      
      return result.first[0] as int;
    } catch (e) {
      print('❌ Erro ao inserir: $e');
      print('SQL: $sql');
      rethrow;
    }
  }
  
  /// Transação (para vendas com múltiplos itens)
  Future<T> transaction<T>(
    Future<T> Function(Connection conn) action,
  ) async {
    return await _connection.runTx((ctx) async {
      return await action(ctx);
    });
  }
  
  Future<void> close() async {
    await _connection.close();
    isConnected.value = false;
  }
}
```

### 4. Models

**Familia Model** - `lib/app/data/models/familia_model.dart`:

```dart
class FamiliaModel {
  final int? id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? createdAt;

  FamiliaModel({
    this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.createdAt,
  });

  factory FamiliaModel.fromMap(Map<String, dynamic> map) {
    return FamiliaModel(
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
  String toString() => 'Familia(id: $id, nome: $nome)';
}
```

**Produto Model** - `lib/app/data/models/produto_model.dart`:

```dart
class ProdutoModel {
  final int? id;
  final String codigo;
  final String nome;
  final int familiaId;
  final double preco;
  final int estoque;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Campo adicional para joins
  final String? familiaNome;

  ProdutoModel({
    this.id,
    required this.codigo,
    required this.nome,
    required this.familiaId,
    required this.preco,
    this.estoque = 0,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
    this.familiaNome,
  });

  factory ProdutoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoModel(
      id: map['id'],
      codigo: map['codigo'],
      nome: map['nome'],
      familiaId: map['familia_id'],
      preco: double.parse(map['preco'].toString()),
      estoque: map['estoque'] ?? 0,
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'].toString()) 
          : null,
      familiaNome: map['familia_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'familia_id': familiaId,
      'preco': preco,
      'estoque': estoque,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Produto(id: $id, codigo: $codigo, nome: $nome, preco: $preco)';
}
```

**Item Venda Model** - `lib/app/data/models/item_venda_model.dart`:

```dart
class ItemVendaModel {
  final int? id;
  final int? vendaId;
  final int produtoId;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;
  
  // Campo adicional
  final String? produtoNome;

  ItemVendaModel({
    this.id,
    this.vendaId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
    this.produtoNome,
  });

  factory ItemVendaModel.fromMap(Map<String, dynamic> map) {
    return ItemVendaModel(
      id: map['id'],
      vendaId: map['venda_id'],
      produtoId: map['produto_id'],
      quantidade: map['quantidade'],
      precoUnitario: double.parse(map['preco_unitario'].toString()),
      subtotal: double.parse(map['subtotal'].toString()),
      produtoNome: map['produto_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venda_id': vendaId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'subtotal': subtotal,
    };
  }
}
```

**Venda Model** - `lib/app/data/models/venda_model.dart`:

```dart
import 'item_venda_model.dart';

class VendaModel {
  final int? id;
  final String numero;
  final double total;
  final DateTime dataVenda;
  final String? terminal;
  
  // Itens da venda
  final List<ItemVendaModel>? itens;

  VendaModel({
    this.id,
    required this.numero,
    required this.total,
    required this.dataVenda,
    this.terminal,
    this.itens,
  });

  factory VendaModel.fromMap(Map<String, dynamic> map) {
    return VendaModel(
      id: map['id'],
      numero: map['numero'],
      total: double.parse(map['total'].toString()),
      dataVenda: DateTime.parse(map['data_venda'].toString()),
      terminal: map['terminal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'total': total,
      'data_venda': dataVenda.toIso8601String(),
      'terminal': terminal,
    };
  }
}
```

### ✅ Teste Fase 2

Crie `lib/main.dart` para testar conexão:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar conexão com banco
  print('🔄 Conectando ao PostgreSQL...');
  try {
    await Get.putAsync(() => DatabaseService().init());
    print('🎉 Sistema iniciado com sucesso!');
  } catch (e) {
    print('❌ Erro ao iniciar: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PDV System - Teste',
      debugShowCheckedModeBanner: false,
      home: TesteConexao(),
    );
  }
}

class TesteConexao extends StatelessWidget {
  final DatabaseService db = Get.find<DatabaseService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste de Conexão'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Icon(
              db.isConnected.value ? Icons.check_circle : Icons.error,
              color: db.isConnected.value ? Colors.green : Colors.red,
              size: 100,
            )),
            SizedBox(height: 20),
            Obx(() => Text(
              db.isConnected.value 
                  ? '✅ Conectado ao PostgreSQL!' 
                  : '❌ Sem conexão',
              style: TextStyle(fontSize: 20),
            )),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                try {
                  final result = await db.query('SELECT COUNT(*) as total FROM produtos');
                  final total = result.first['total'];
                  Get.snackbar(
                    'Sucesso',
                    'Total de produtos: $total',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Erro',
                    'Erro ao consultar: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: Text('Testar Query'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Execute:**

```bash
flutter run -d windows
```

**Resultado esperado:**
- ✅ Ícone verde de conectado
- Botão "Testar Query" deve mostrar total de produtos

---

## 🔧 FASE 3: Repositories e Controllers

### 1. Repositories

**Familia Repository** - `lib/app/data/repositories/familia_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/familia_model.dart';

class FamiliaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Future<List<FamiliaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM familias 
      WHERE ativo = true 
      ORDER BY nome
    ''');
    
    return result.map((map) => FamiliaModel.fromMap(map)).toList();
  }
  
  Future<FamiliaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM familias 
      WHERE id = @id
    ''', parameters: {'id': id});
    
    if (result.isEmpty) return null;
    return FamiliaModel.fromMap(result.first);
  }
  
  Future<int> inserir(FamiliaModel familia) async {
    return await _db.insert('''
      INSERT INTO familias (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: familia.toMap());
  }
  
  Future<void> atualizar(int id, FamiliaModel familia) async {
    await _db.execute('''
      UPDATE familias 
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...familia.toMap(),
      'id': id,
    });
  }
  
  Future<void> deletar(int id) async {
    // Soft delete
    await _db.execute('''
      UPDATE familias SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
```

**Produto Repository** - `lib/app/data/repositories/produto_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Future<List<ProdutoModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT p.*, f.nome as familia_nome
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE p.ativo = true
      ORDER BY p.nome
    ''');
    
    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }
  
  Future<List<ProdutoModel>> listarPorFamilia(int familiaId) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as familia_nome
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE p.familia_id = @familia_id AND p.ativo = true
      ORDER BY p.nome
    ''', parameters: {'familia_id': familiaId});
    
    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }
  
  Future<ProdutoModel?> buscarPorCodigo(String codigo) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as familia_nome
      FROM produtos p
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE p.codigo = @codigo AND p.ativo = true
    ''', parameters: {'codigo': codigo});
    
    if (result.isEmpty) return null;
    return ProdutoModel.fromMap(result.first);
  }
  
  Future<int> inserir(ProdutoModel produto) async {
    return await _db.insert('''
      INSERT INTO produtos (codigo, nome, familia_id, preco, estoque, ativo)
      VALUES (@codigo, @nome, @familia_id, @preco, @estoque, @ativo)
    ''', parameters: produto.toMap());
  }
  
  Future<void> atualizar(int id, ProdutoModel produto) async {
    await _db.execute('''
      UPDATE produtos 
      SET codigo = @codigo,
          nome = @nome,
          familia_id = @familia_id,
          preco = @preco,
          estoque = @estoque,
          ativo = @ativo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...produto.toMap(),
      'id': id,
    });
  }
  
  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE produtos SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
  
  Future<void> atualizarEstoque(int produtoId, int quantidade) async {
    await _db.execute('''
      UPDATE produtos 
      SET estoque = estoque - @quantidade,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      'quantidade': quantidade,
      'id': produtoId,
    });
  }
}
```

**Venda Repository** - `lib/app/data/repositories/venda_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';

class VendaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  Future<int> registrarVenda(VendaModel venda, List<ItemVendaModel> itens) async {
    return await _db.transaction((conn) async {
      // 1. Inserir venda
      final vendaResult = await conn.execute(
        Sql.named('''
          INSERT INTO vendas (numero, total, terminal)
          VALUES (@numero, @total, @terminal)
          RETURNING id
        '''),
        parameters: venda.toMap(),
      );
      
      final vendaId = vendaResult.first[0] as int;
      
      // 2. Inserir itens
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
  
  Future<List<VendaModel>> listarVendas({DateTime? dataInicio, DateTime? dataFim}) async {
    String sql = 'SELECT * FROM vendas WHERE 1=1';
    Map<String, dynamic> params = {};
    
    if (dataInicio != null) {
      sql += ' AND data_venda >= @data_inicio';
      params['data_inicio'] = dataInicio.toIso8601String();
    }
    
    if (dataFim != null) {
      sql += ' AND data_venda <= @data_fim';
      params['data_fim'] = dataFim.toIso8601String();
    }
    
    sql += ' ORDER BY data_venda DESC';
    
    final result = await _db.query(sql, parameters: params);
    return result.map((map) => VendaModel.fromMap(map)).toList();
  }
  
  Future<List<ItemVendaModel>> listarItensVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT iv.*, p.nome as produto_nome
      FROM itens_venda iv
      LEFT JOIN produtos p ON iv.produto_id = p.id
      WHERE iv.venda_id = @venda_id
    ''', parameters: {'venda_id': vendaId});
    
    return result.map((map) => ItemVendaModel.fromMap(map)).toList();
  }
}
```

### 2. Utility - Formatadores

Crie `lib/core/utils/formatters.dart`:

```dart
import 'package:intl/intl.dart';

class Formatters {
  // Formatar moeda Moçambique
  static String formatarMoeda(double valor) {
    return NumberFormat.currency(
      locale: 'pt_MZ',
      symbol: 'MT',
      decimalDigits: 2,
    ).format(valor);
  }
  
  // Formatar data
  static String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(data);
  }
  
  // Formatar data curta
  static String formatarDataCurta(DateTime data) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(data);
  }
}
```

### ✅ Teste Fase 3

Adicione ao `main.dart` para testar repositories:

```dart
// Adicione este botão na tela de teste:
ElevatedButton(
  onPressed: () async {
    final familiaRepo = FamiliaRepository();
    final familias = await familiaRepo.listarTodas();
    
    print('📦 Total de famílias: ${familias.length}');
    for (var f in familias) {
      print('  - ${f.nome}');
    }
    
    final produtoRepo = ProdutoRepository();
    final produtos = await produtoRepo.listarTodos();
    
    print('🛒 Total de produtos: ${produtos.length}');
    for (var p in produtos) {
      print('  - ${p.nome} (${p.familiaNome}) - ${Formatters.formatarMoeda(p.preco)}');
    }
    
    Get.snackbar(
      'Sucesso',
      'Famílias: ${familias.length}, Produtos: ${produtos.length}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  },
  child: Text('Testar Repositories'),
),
```

---

## 🎨 FASE 4: Telas Principais

### 1. Tema e Cores

Crie `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color dangerColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: GoogleFonts.robotoTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
```

### 2. Rotas

Crie `lib/app/routes/app_routes.dart`:

```dart
class AppRoutes {
  static const home = '/home';
  static const admin = '/admin';
  static const vendas = '/vendas';
}
```

Crie `lib/app/routes/app_pages.dart`:

```dart
import 'package:get/get.dart';
import '../modules/home/home_page.dart';
import '../modules/admin/admin_page.dart';
import '../modules/vendas/vendas_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => AdminPage(),
    ),
    GetPage(
      name: AppRoutes.vendas,
      page: () => VendasPage(),
    ),
  ];
}
```

### 3. Tela Home (Escolha: Vendas ou Admin)

Crie `lib/app/modules/home/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou Nome do Sistema
              Icon(
                Icons.point_of_sale,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'SISTEMA PDV',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Frentex e Serviços',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 60),
              
              // Botões principais
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(
                    icon: Icons.shopping_cart,
                    label: 'VENDAS',
                    color: AppTheme.secondaryColor,
                    onTap: () => Get.toNamed(AppRoutes.vendas),
                  ),
                  SizedBox(width: 40),
                  _buildMenuButton(
                    icon: Icons.admin_panel_settings,
                    label: 'ADMIN',
                    color: AppTheme.warningColor,
                    onTap: () => Get.toNamed(AppRoutes.admin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Atualizar main.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar banco de dados
  print('🔄 Conectando ao PostgreSQL...');
  try {
    await Get.putAsync(() => DatabaseService().init());
    print('✅ Conexão estabelecida!');
  } catch (e) {
    print('❌ Erro ao conectar: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PDV System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    );
  }
}
```

### ✅ Teste Fase 4

```bash
flutter run -d windows
```

**Resultado esperado:**
- Tela inicial com 2 botões: VENDAS e ADMIN
- Clicar nos botões deve navegar (telas ainda vazias)

---

## 🛠️ FASE 5: Tela de Admin

### 1. Admin Controller

Crie `lib/app/modules/admin/controllers/admin_controller.dart`:

```dart
import 'package:get/get.dart';
import '../../../data/models/familia_model.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/produto_repository.dart';

class AdminController extends GetxController {
  final FamiliaRepository _familiaRepo = FamiliaRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  
  final familias = <FamiliaModel>[].obs;
  final produtos = <ProdutoModel>[].obs;
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
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // FAMÍLIA
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
  
  // PRODUTO
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

### 2. Admin Page

Crie `lib/app/modules/admin/admin_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/admin_controller.dart';
import 'views/familias_tab.dart';
import 'views/produtos_tab.dart';

class AdminPage extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ADMINISTRAÇÃO'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'FAMÍLIAS'),
              Tab(icon: Icon(Icons.inventory), text: 'PRODUTOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FamiliasTab(),
            ProdutosTab(),
          ],
        ),
      ),
    );
  }
}
```

### 3. Tab Famílias

Crie `lib/app/modules/admin/views/familias_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class FamiliasTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.familias.isEmpty) {
          return Center(
            child: Text('Nenhuma família cadastrada'),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.familias.length,
          itemBuilder: (context, index) {
            final familia = controller.familias[index];
            return Card(
              child: ListTile(
                title: Text(familia.nome),
                subtitle: Text(familia.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialogFamilia(familia),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(familia.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogFamilia(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _mostrarDialogFamilia(familia) {
    final nomeController = TextEditingController(text: familia?.nome ?? '');
    final descController = TextEditingController(text: familia?.descricao ?? '');
    
    Get.dialog(
      AlertDialog(
        title: Text(familia == null ? 'Nova Família' : 'Editar Família'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Descrição'),
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
              
              if (familia == null) {
                controller.adicionarFamilia(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarFamilia(
                  familia.id!,
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
        content: Text('Deseja realmente remover esta família?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarFamilia(id);
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

### 4. Tab Produtos

Crie `lib/app/modules/admin/views/produtos_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/produto_model.dart';
import '../controllers/admin_controller.dart';

class ProdutosTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.produtos.isEmpty) {
          return Center(
            child: Text('Nenhum produto cadastrado'),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.produtos.length,
          itemBuilder: (context, index) {
            final produto = controller.produtos[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(produto.codigo),
                ),
                title: Text(produto.nome),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Família: ${produto.familiaNome ?? "N/A"}'),
                    Text('Estoque: ${produto.estoque}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatarMoeda(produto.preco),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _mostrarDialogProduto(produto),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _confirmarDelete(produto.id!),
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
        onPressed: () => _mostrarDialogProduto(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _mostrarDialogProduto(ProdutoModel? produto) {
    final codigoController = TextEditingController(text: produto?.codigo ?? '');
    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final precoController = TextEditingController(
      text: produto?.preco.toString() ?? '',
    );
    final estoqueController = TextEditingController(
      text: produto?.estoque.toString() ?? '0',
    );
    
    int? familiaIdSelecionada = produto?.familiaId;
    
    Get.dialog(
      AlertDialog(
        title: Text(produto == null ? 'Novo Produto' : 'Editar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoController,
                decoration: InputDecoration(labelText: 'Código'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              SizedBox(height: 10),
              Obx(() => DropdownButtonFormField<int>(
                value: familiaIdSelecionada,
                decoration: InputDecoration(labelText: 'Família'),
                items: controller.familias.map((familia) {
                  return DropdownMenuItem<int>(
                    value: familia.id,
                    child: Text(familia.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  familiaIdSelecionada = value;
                },
              )),
              SizedBox(height: 10),
              TextField(
                controller: precoController,
                decoration: InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: estoqueController,
                decoration: InputDecoration(labelText: 'Estoque'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codigoController.text.isEmpty || 
                  nomeController.text.isEmpty ||
                  familiaIdSelecionada == null) {
                Get.snackbar('Erro', 'Preencha todos os campos obrigatórios');
                return;
              }
              
              final novoProduto = ProdutoModel(
                codigo: codigoController.text,
                nome: nomeController.text,
                familiaId: familiaIdSelecionada!,
                preco: double.tryParse(precoController.text) ?? 0,
                estoque: int.tryParse(estoqueController.text) ?? 0,
              );
              
              if (produto == null) {
                controller.adicionarProduto(novoProduto);
              } else {
                controller.editarProduto(produto.id!, novoProduto);
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
        content: Text('Deseja realmente remover este produto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarProduto(id);
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

### ✅ Teste Fase 5

```bash
flutter run -d windows
```

**Teste:**
1. Ir para ADMIN
2. Criar novas famílias
3. Criar produtos com as famílias
4. Editar e deletar

---

## 💰 FASE 6: Tela de Vendas

### 1. Vendas Controller

Crie `lib/app/modules/vendas/controllers/vendas_controller.dart`:

```dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/familia_model.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/venda_model.dart';
import '../../../data/models/item_venda_model.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/repositories/venda_repository.dart';

class ItemCarrinho {
  final ProdutoModel produto;
  int quantidade;
  
  ItemCarrinho({required this.produto, this.quantidade = 1});
  
  double get subtotal => produto.preco * quantidade;
}

class VendasController extends GetxController {
  final FamiliaRepository _familiaRepo = FamiliaRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final VendaRepository _vendaRepo = VendaRepository();
  
  final familias = <FamiliaModel>[].obs;
  final produtos = <ProdutoModel>[].obs;
  final produtosFiltrados = <ProdutoModel>[].obs;
  final carrinho = <ItemCarrinho>[].obs;
  final isLoading = false.obs;
  
  FamiliaModel? familiaSelecionada;
  
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
      produtosFiltrados.value = produtos;
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void selecionarFamilia(FamiliaModel? familia) {
    familiaSelecionada = familia;
    if (familia == null) {
      produtosFiltrados.value = produtos;
    } else {
      produtosFiltrados.value = produtos
          .where((p) => p.familiaId == familia.id)
          .toList();
    }
  }
  
  void adicionarAoCarrinho(ProdutoModel produto) {
    // Verificar se já está no carrinho
    final index = carrinho.indexWhere((item) => item.produto.id == produto.id);
    
    if (index >= 0) {
      // Aumentar quantidade
      carrinho[index].quantidade++;
      carrinho.refresh();
    } else {
      // Adicionar novo item
      carrinho.add(ItemCarrinho(produto: produto));
    }
    
    Get.snackbar(
      'Adicionado',
      '${produto.nome} adicionado ao carrinho',
      duration: Duration(seconds: 1),
    );
  }
  
  void removerDoCarrinho(int index) {
    carrinho.removeAt(index);
  }
  
  void aumentarQuantidade(int index) {
    carrinho[index].quantidade++;
    carrinho.refresh();
  }
  
  void diminuirQuantidade(int index) {
    if (carrinho[index].quantidade > 1) {
      carrinho[index].quantidade--;
      carrinho.refresh();
    }
  }
  
  double get totalCarrinho {
    return carrinho.fold(0, (sum, item) => sum + item.subtotal);
  }
  
  Future<void> finalizarVenda() async {
    if (carrinho.isEmpty) {
      Get.snackbar('Erro', 'Carrinho vazio');
      return;
    }
    
    try {
      // Gerar número da venda
      final numero = 'VD${DateTime.now().millisecondsSinceEpoch}';
      
      // Criar venda
      final venda = VendaModel(
        numero: numero,
        total: totalCarrinho,
        dataVenda: DateTime.now(),
        terminal: 'CAIXA-01',
      );
      
      // Criar itens
      final itens = carrinho.map((item) {
        return ItemVendaModel(
          produtoId: item.produto.id!,
          quantidade: item.quantidade,
          precoUnitario: item.produto.preco,
          subtotal: item.subtotal,
        );
      }).toList();
      
      // Registrar venda no banco
      final vendaId = await _vendaRepo.registrarVenda(venda, itens);
      
      Get.snackbar(
        'Sucesso',
        'Venda #$vendaId registrada!',
        backgroundColor: Get.theme.primaryColor,
        colorText: Colors.white,
      );
      
      // Limpar carrinho
      carrinho.clear();
      
      // Atualizar produtos (estoque mudou)
      await carregarDados();
      
      // TODO: Chamar impressão
      // await imprimirCupom(venda, itens);
      
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao finalizar venda: $e');
    }
  }
  
  void limparCarrinho() {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja limpar o carrinho?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              carrinho.clear();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('LIMPAR'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Vendas Page

Crie `lib/app/modules/vendas/vendas_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import 'controllers/vendas_controller.dart';

class VendasPage extends StatelessWidget {
  final VendasController controller = Get.put(VendasController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VENDAS'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: controller.carregarDados,
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
                // Filtro por família
                _buildFiltroFamilias(),
                Divider(height: 1),
                // Grid de produtos
                Expanded(child: _buildGridProdutos()),
              ],
            ),
          ),
          
          // LADO DIREITO: Carrinho
          Container(
            width: 400,
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
  
  Widget _buildFiltroFamilias() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Todas
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('TODAS'),
              selected: controller.familiaSelecionada == null,
              onSelected: (_) => controller.selecionarFamilia(null),
            ),
          ),
          // Famílias
          ...controller.familias.map((familia) {
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(familia.nome),
                selected: controller.familiaSelecionada?.id == familia.id,
                onSelected: (_) => controller.selecionarFamilia(familia),
              ),
            );
          }),
        ],
      )),
    );
  }
  
  Widget _buildGridProdutos() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (controller.produtosFiltrados.isEmpty) {
        return Center(
          child: Text('Nenhum produto encontrado'),
        );
      }
      
      return GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone do produto
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.fastfood,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Nome
              Text(
                produto.nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              // Preço
              Text(
                Formatters.formatarMoeda(produto.preco),
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Estoque
              Text(
                'Estoque: ${produto.estoque}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
      padding: EdgeInsets.all(16),
      color: Get.theme.primaryColor,
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'CARRINHO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Obx(() => Text(
            '${controller.carrinho.length} itens',
            style: TextStyle(color: Colors.white),
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
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Carrinho vazio',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }
      
      return ListView.separated(
        padding: EdgeInsets.all(8),
        itemCount: controller.carrinho.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final item = controller.carrinho[index];
          return _buildItemCarrinho(item, index);
        },
      );
    });
  }
  
  Widget _buildItemCarrinho(ItemCarrinho item, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.produto.nome,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Formatters.formatarMoeda(item.produto.preco),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => controller.removerDoCarrinho(index),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              // Botões quantidade
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 18),
                      onPressed: () => controller.diminuirQuantidade(index),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantidade}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => controller.aumentarQuantidade(index),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Subtotal
              Text(
                Formatters.formatarMoeda(item.subtotal),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotalCarrinho() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Obx(() => Text(
            Formatters.formatarMoeda(controller.totalCarrinho),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildBotoesAcao() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: controller.finalizarVenda,
              icon: Icon(Icons.check),
              label: Text(
                'FINALIZAR VENDA',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: controller.limparCarrinho,
              icon: Icon(Icons.clear),
              label: Text('LIMPAR CARRINHO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### ✅ Teste Fase 6

```bash
flutter run -d windows
```

**Teste:**
1. Entrar em VENDAS
2. Filtrar por família
3. Adicionar produtos ao carrinho
4. Aumentar/diminuir quantidades
5. Finalizar venda
6. Verificar no banco se a venda foi registrada

```bash
psql -U postgres -d pdv_system

# Consultar vendas
SELECT * FROM vendas ORDER BY id DESC LIMIT 5;
SELECT * FROM itens_venda WHERE venda_id = 1;

\q
```

---

## 🖨️ FASE 7: Impressão Térmica 80mm

### 1. Serviço de Impressão

Crie `lib/core/utils/printer_service.dart`:

```dart
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:intl/intl.dart';
import '../../app/data/models/venda_model.dart';
import '../../app/data/models/item_venda_model.dart';
import 'formatters.dart';

class PrinterService {
  // Configurações da impressora
  static const String printerIp = '192.168.1.100'; // ⚠️ IP da sua impressora
  static const int printerPort = 9100; // Porta padrão para impressoras térmicas
  
  /// Imprimir cupom de venda
  static Future<bool> imprimirCupom(
    VendaModel venda,
    List<ItemVendaModel> itens,
  ) async {
    try {
      // Conectar à impressora
      final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load());
      
      final result = await printer.connect(printerIp, port: printerPort);
      
      if (result != PosPrintResult.success) {
        print('❌ Erro ao conectar na impressora: $result');
        return false;
      }
      
      // Gerar conteúdo do cupom
      await _gerarCupom(printer, venda, itens);
      
      // Desconectar
      printer.disconnect();
      
      print('✅ Cupom impresso com sucesso!');
      return true;
      
    } catch (e) {
      print('❌ Erro ao imprimir: $e');
      return false;
    }
  }
  
  static Future<void> _gerarCupom(
    NetworkPrinter printer,
    VendaModel venda,
    List<ItemVendaModel> itens,
  ) async {
    // CABEÇALHO
    printer.text(
      'FRENTEX E SERVICOS',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    
    printer.text(
      'Sistema de Gestao PDV',
      styles: PosStyles(align: PosAlign.center),
    );
    
    printer.text(
      'Tel: +258 84 123 4567',
      styles: PosStyles(align: PosAlign.center),
    );
    
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
      // Nome do produto
      printer.text(
        item.produtoNome ?? 'Produto',
        styles: PosStyles(bold: true),
      );
      
      // Quantidade e valor
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
      
      // Preço unitário (se quantidade > 1)
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
    
    printer.text(
      'Sistema PDV - Frentex',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    
    // Cortar papel
    printer.cut();
  }
  
  static String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_MZ',
      symbol: 'MT ',
      decimalDigits: 2,
    ).format(valor);
  }
  
  /// Testar conexão com impressora
  static Future<bool> testarImpressora() async {
    try {
      final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load());
      
      final result = await printer.connect(printerIp, port: printerPort);
      
      if (result == PosPrintResult.success) {
        // Imprimir teste
        printer.text(
          'TESTE DE IMPRESSORA',
          styles: PosStyles(align: PosAlign.center, bold: true),
        );
        printer.text(
          'Conexao OK!',
          styles: PosStyles(align: PosAlign.center),
        );
        printer.emptyLines(2);
        printer.cut();
        
        printer.disconnect();
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('❌ Erro ao testar impressora: $e');
      return false;
    }
  }
  
  /// Buscar impressoras na rede
  static Future<List<String>> buscarImpressoras() async {
    // TODO: Implementar busca por impressoras na rede
    // Usando ping_discover_network
    return [];
  }
}
```

### 2. Integrar Impressão no Controller

Edite `lib/app/modules/vendas/controllers/vendas_controller.dart`:

Adicione no import:
```dart
import '../../../../core/utils/printer_service.dart';
```

Modifique o método `finalizarVenda`:

```dart
Future<void> finalizarVenda() async {
  if (carrinho.isEmpty) {
    Get.snackbar('Erro', 'Carrinho vazio');
    return;
  }
  
  try {
    // Gerar número da venda
    final numero = 'VD${DateTime.now().millisecondsSinceEpoch}';
    
    // Criar venda
    final venda = VendaModel(
      numero: numero,
      total: totalCarrinho,
      dataVenda: DateTime.now(),
      terminal: 'CAIXA-01',
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
    venda = VendaModel(
      id: vendaId,
      numero: numero,
      total: totalCarrinho,
      dataVenda: DateTime.now(),
      terminal: 'CAIXA-01',
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
              await _imprimirEFinalizar(venda, itens);
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

Future<void> _imprimirEFinalizar(VendaModel venda, List<ItemVendaModel> itens) async {
  Get.dialog(
    Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );
  
  final sucesso = await PrinterService.imprimirCupom(venda, itens);
  
  Get.back(); // Fechar loading
  
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

void _finalizarVendaSemImprimir() {
  // Limpar carrinho
  carrinho.clear();
  
  // Atualizar produtos (estoque mudou)
  carregarDados();
}
```

### 3. Configurar IP da Impressora

Edite `lib/core/utils/printer_service.dart`:

```dart
// No topo do arquivo, altere:
static const String printerIp = '192.168.1.100'; // ⚠️ COLOQUE O IP DA SUA IMPRESSORA
```

**Como descobrir o IP da impressora:**

1. Veja no manual da impressora
2. Ou imprima a configuração de rede (geralmente há um botão para isso)
3. Ou use um scanner de rede (como Advanced IP Scanner)

### ✅ Teste Fase 7

**1. Testar Conexão:**

Adicione um botão na tela de Admin para testar:

```dart
ElevatedButton(
  onPressed: () async {
    final sucesso = await PrinterService.testarImpressora();
    Get.snackbar(
      sucesso ? 'Sucesso' : 'Erro',
      sucesso ? 'Impressora conectada!' : 'Erro ao conectar',
      backgroundColor: sucesso ? Colors.green : Colors.red,
      colorText: Colors.white,
    );
  },
  child: Text('TESTAR IMPRESSORA'),
),
```

**2. Fazer uma Venda e Imprimir:**

```bash
flutter run -d windows
```

1. Ir para VENDAS
2. Adicionar produtos
3. Finalizar venda
4. Escolher "SIM" para imprimir
5. Verificar se imprimiu corretamente

---

## ✅ FASE 8: Testes e Validação

### 1. Checklist de Testes

#### **Banco de Dados**
- [ ] PostgreSQL instalado e rodando
- [ ] Database `pdv_system` criado
- [ ] Tabelas criadas corretamente
- [ ] Dados de teste inseridos
- [ ] Consegue conectar via psql

#### **Conexão Flutter**
- [ ] App conecta ao PostgreSQL
- [ ] Queries funcionam corretamente
- [ ] Erros são tratados

#### **Admin - Famílias**
- [ ] Listar famílias
- [ ] Criar nova família
- [ ] Editar família
- [ ] Deletar família

#### **Admin - Produtos**
- [ ] Listar produtos
- [ ] Criar novo produto
- [ ] Editar produto
- [ ] Deletar produto
- [ ] Produtos mostram família correta

#### **Vendas**
- [ ] Listar produtos
- [ ] Filtrar por família
- [ ] Adicionar ao carrinho
- [ ] Aumentar/diminuir quantidade
- [ ] Remover do carrinho
- [ ] Calcular total corretamente
- [ ] Finalizar venda
- [ ] Atualizar estoque
- [ ] Registrar venda no banco

#### **Impressão**
- [ ] Conectar à impressora
- [ ] Imprimir cupom de teste
- [ ] Imprimir cupom de venda
- [ ] Layout correto (80mm)
- [ ] Informações completas

### 2. Testes no Banco de Dados

```bash
# Abrir PostgreSQL
psql -U postgres -d pdv_system

# Verificar registros
SELECT COUNT(*) FROM familias;
SELECT COUNT(*) FROM produtos;
SELECT COUNT(*) FROM vendas;

# Ver últimas vendas
SELECT 
    v.numero,
    v.total,
    v.data_venda,
    COUNT(iv.id) as itens
FROM vendas v
LEFT JOIN itens_venda iv ON v.id = iv.venda_id
GROUP BY v.id
ORDER BY v.data_venda DESC
LIMIT 10;

# Ver produtos mais vendidos
SELECT 
    p.nome,
    SUM(iv.quantidade) as total_vendido
FROM itens_venda iv
JOIN produtos p ON iv.produto_id = p.id
GROUP BY p.id, p.nome
ORDER BY total_vendido DESC;

# Ver estoque atual
SELECT 
    p.nome,
    p.estoque,
    f.nome as familia
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
ORDER BY p.estoque;

\q
```

### 3. Resolução de Problemas Comuns

#### **Erro: "Não consegue conectar ao PostgreSQL"**
```bash
# Verificar se está rodando
# Windows PowerShell (como Admin):
Get-Service -Name postgresql*

# Se não estiver, iniciar:
Start-Service postgresql-x64-15
```

#### **Erro: "password authentication failed"**
- Verifique a senha em `database_config.dart`
- Teste no psql primeiro
- Reinicie o PostgreSQL se necessário

#### **Erro: "could not connect to server"**
- Verifique se o PostgreSQL está aceitando conexões TCP/IP
- Edite `postgresql.conf`: `listen_addresses = '*'`
- Edite `pg_hba.conf`: adicione linha `host all all 0.0.0.0/0 md5`
- Reinicie o PostgreSQL

#### **Erro: "Impressora não conecta"**
- Verifique o IP da impressora
- Teste ping: `ping 192.168.1.100`
- Verifique se está na mesma rede
- Confirme a porta (geralmente 9100)
- Desabilite firewall temporariamente para testar

### 4. Melhorias Futuras

Após ter tudo funcionando, considere adicionar:

- [ ] Autenticação de usuários
- [ ] Diferentes formas de pagamento
- [ ] Relatórios (vendas por período, produtos mais vendidos)
- [ ] Backup automático do banco
- [ ] Sincronização com nuvem (Supabase)
- [ ] Controle de mesas (para restaurante)
- [ ] Comandas
- [ ] Desconto em produtos
- [ ] Cancelamento de vendas
- [ ] Devolução de produtos
- [ ] Gestão de clientes
- [ ] Contas a receber/pagar

---

## 📚 Comandos Úteis de Referência

### PostgreSQL

```bash
# Conectar
psql -U postgres -d pdv_system

# Listar databases
\l

# Listar tabelas
\dt

# Descrever tabela
\d produtos

# Ver queries lentas
\timing

# Exportar dados
\copy produtos TO 'produtos.csv' CSV HEADER;

# Importar dados
\copy produtos FROM 'produtos.csv' CSV HEADER;

# Backup
pg_dump -U postgres pdv_system > backup.sql

# Restaurar
psql -U postgres pdv_system < backup.sql

# Sair
\q
```

### Flutter

```bash
# Rodar no Windows
flutter run -d windows

# Rodar com hot reload
flutter run -d windows --hot

# Limpar build
flutter clean

# Atualizar dependências
flutter pub get

# Ver devices disponíveis
flutter devices

# Build release
flutter build windows

# Analisar código
flutter analyze
```

---

## 🎉 Conclusão

Você agora tem um **sistema PDV completo** com:

✅ **Backend PostgreSQL** rodando localmente  
✅ **Frontend Flutter** com GetX  
✅ **Gestão de Famílias e Produtos**  
✅ **Tela de Vendas funcional**  
✅ **Impressão térmica 80mm**  
✅ **Estrutura escalável** para adicionar mais funcionalidades

**Próximos passos sugeridos:**

1. Adicionar autenticação de usuários
2. Implementar mais relatórios
3. Adicionar backup automático
4. Testar com múltiplos terminais na rede
5. Adicionar suporte para código de barras

**Suporte:**

Se tiver dúvidas ou problemas:
1. Consulte este guia
2. Verifique os logs do console
3. Teste cada fase separadamente
4. Use o PostgreSQL CLI para debugar o banco

---

**Desenvolvido com ❤️ por Claude para Frentex e Serviços**

*Versão 1.0 - Novembro 2025*
