# Correções Sistema de Auditoria

## Problema Identificado

A tabela `usuarios` não possui coluna `username`, possui apenas `codigo`.

**Estrutura real da tabela:**
```sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    perfil_id INTEGER NOT NULL,
    codigo VARCHAR(8) NOT NULL,  -- Esta é a coluna correta!
    ativo BOOLEAN DEFAULT true,
    ...
);
```

## ✅ Correções Aplicadas

### 1. SQL: `database/sistema_auditoria.sql`

#### Correção 1: View vw_auditoria_detalhada (linha 169)
**ANTES:**
```sql
u.username as usuario_username,
```

**DEPOIS:**
```sql
u.codigo as usuario_codigo,
```

#### Correção 2: View vw_logins_falhados (linha 255)
**ANTES:**
```sql
u.username,
```

**DEPOIS:**
```sql
u.codigo as usuario_codigo,
```

#### Correção 3: Função registrar_login_falhado (linha 302-312)
**ANTES:**
```sql
CREATE OR REPLACE FUNCTION registrar_login_falhado(
  p_username VARCHAR(100),
  ...
)
...
  SELECT id INTO v_usuario_id FROM usuarios WHERE username = p_username;
```

**DEPOIS:**
```sql
CREATE OR REPLACE FUNCTION registrar_login_falhado(
  p_codigo VARCHAR(100),
  ...
)
...
  SELECT id INTO v_usuario_id FROM usuarios WHERE codigo = p_codigo;
```

### 2. Dart: `lib/app/data/models/auditoria_model.dart`

#### Correção: LogAcessoModel
**ANTES:**
```dart
class LogAcessoModel {
  ...
  final String? username;
  ...
  LogAcessoModel({
    ...
    this.username,
    ...
  });

  factory LogAcessoModel.fromMap(Map<String, dynamic> map) {
    return LogAcessoModel(
      ...
      username: map['username'] as String?,
      ...
    );
  }
}
```

**DEPOIS:**
```dart
class LogAcessoModel {
  ...
  final String? usuarioCodigo;
  ...
  LogAcessoModel({
    ...
    this.usuarioCodigo,
    ...
  });

  factory LogAcessoModel.fromMap(Map<String, dynamic> map) {
    return LogAcessoModel(
      ...
      usuarioCodigo: map['usuario_codigo'] as String?,
      ...
    );
  }
}
```

### 3. Dart: `lib/app/data/repositories/auditoria_repository.dart`

#### Correção 1: Query listarLogsAcesso (linha 236)
**ANTES:**
```dart
'''
SELECT
  l.*,
  u.nome as usuario_nome,
  u.username
FROM logs_acesso l
...
'''
```

**DEPOIS:**
```dart
'''
SELECT
  l.*,
  u.nome as usuario_nome,
  u.codigo as usuario_codigo
FROM logs_acesso l
...
'''
```

#### Correção 2: Função registrarLoginFalhado (linha 304-315)
**ANTES:**
```dart
Future<void> registrarLoginFalhado(
  String username,
  String motivo, {
  ...
}) async {
  await _db.query(
    '''
    SELECT registrar_login_falhado(@username, @motivo, ...)
    ''',
    parameters: {
      'username': username,
      ...
    },
  );
}
```

**DEPOIS:**
```dart
Future<void> registrarLoginFalhado(
  String codigo,
  String motivo, {
  ...
}) async {
  await _db.query(
    '''
    SELECT registrar_login_falhado(@codigo, @motivo, ...)
    ''',
    parameters: {
      'codigo': codigo,
      ...
    },
  );
}
```

### 4. Dart: `lib/app/modules/admin/views/auditoria_tab.dart`

#### Correção: _buildLogAcessoCard (linha 409)
**ANTES:**
```dart
'${log.tipoLegivel} - ${log.usuarioNome ?? log.username ?? 'Desconhecido'}',
```

**DEPOIS:**
```dart
'${log.tipoLegivel} - ${log.usuarioNome ?? log.usuarioCodigo ?? 'Desconhecido'}',
```

## 📝 Executar Agora

```bash
cd database
psql -U postgres -d posfaturix -f sistema_auditoria.sql
```

Deve executar SEM ERROS e mostrar:

```
NOTICE:  trigger "..." for relation "..." does not exist, skipping  (normal na primeira vez)
✅ Sistema de Auditoria instalado com sucesso!
   - Tabela auditoria criada
   - Tabela logs_acesso criada
   - Triggers instalados em 11 tabelas
   - 7 views de consulta criadas
   - 6 funções auxiliares criadas

Tabelas monitoradas:
   ✓ produtos, vendas, itens_venda
   ✓ usuarios, perfil_permissoes
   ✓ clientes, familias
   ✓ impressoras, areas, mesas
```

## ✅ Tudo Corrigido!

Todas as referências a `username` foram substituídas por `codigo` conforme a estrutura real da tabela `usuarios`.
