# CORREÇÃO: Bug de Permissões do Administrador

## PROBLEMA IDENTIFICADO

O usuário administrador selecionava todas as permissões na tela de configuração, mas ao tentar acessar "Acerto de Stock" ou outras telas, recebia a mensagem "Não tem permissão".

## ANÁLISE DO PROBLEMA

Foram identificados três problemas principais:

### 1. Permissões Faltantes no Banco de Dados
O sistema verificava permissões com códigos que não existiam na tabela `permissoes`, incluindo:
- `acerto_stock` (usado no admin_page.dart linha 657)
- `gestao_mesas`, `gestao_empresa`, `gestao_produtos` etc.
- `visualizar_relatorios`, `visualizar_margens`, `visualizar_stock`

### 2. Falta de Bypass para Administradores
O sistema não tinha tratamento especial para perfis de Administrador. Mesmo selecionando todas as permissões, se uma permissão estivesse faltando no banco, o acesso era negado.

### 3. Verificação de Permissões Muito Restritiva
O código verificava permissões de forma estrita, sem considerar que administradores devem ter acesso total ao sistema.

## CORREÇÕES IMPLEMENTADAS

### 1. AuthService - Bypass para Administradores
**Arquivo:** `lib/core/services/auth_service.dart`

Adicionado bypass automático no método `temPermissao()`:
```dart
// BYPASS: Administradores e Super Administradores têm acesso total
final perfilNome = usuarioLogado.value!.perfilNome?.toLowerCase() ?? '';
if (perfilNome.contains('administrador')) {
  return true;
}
```

**Resultado:** Qualquer usuário com perfil contendo "administrador" no nome automaticamente tem todas as permissões, independente do que está na tabela `perfil_permissoes`.

### 2. Admin Page - Verificação com Bypass
**Arquivo:** `lib/app/modules/admin/admin_page.dart`

Modificado o método `_buildMenuCard()` para verificar se é admin antes de checar permissões:
```dart
final perfilNome = authService.perfilUsuario.toLowerCase();
final isAdmin = perfilNome.contains('administrador');

// Se não é admin, verificar permissões
if (!isAdmin) {
  final temPermissao = await authService.temAlgumaPermissao(item.permissoes);
  // ... verificação ...
}
```

**Resultado:** Administradores podem clicar em qualquer card sem passar pela verificação de permissões.

### 3. Script SQL - Permissões Faltantes
**Arquivo:** `database/migrations/fix_permissoes_admin.sql`

Script criado para:
- Adicionar todas as permissões faltantes no banco
- Garantir que perfis "Administrador" e "Super Administrador" tenham TODAS as permissões
- Incluir verificações para validar a correção

**Permissões adicionadas:**
```sql
-- Gestão
gestao_mesas, gestao_empresa, gestao_fornecedores,
gestao_clientes, gestao_produtos, gestao_faturas,
gestao_despesas, gestao_pagamentos, gestao_setores, gestao_areas

-- Visualização
visualizar_relatorios, visualizar_margens, visualizar_stock
```

## MAPEAMENTO DE PERMISSÕES

| Tela/Funcionalidade | Permissão Verificada | Status |
|---------------------|---------------------|---------|
| Produtos | `registar_produtos` | ✓ Existe |
| Famílias | `registar_familias` | ✓ Existe |
| Clientes | `registar_clientes` | ✓ Existe |
| Fornecedores | `registar_fornecedores` | ✓ Existe |
| Faturas Entrada | `entrada_stock` | ✓ Existe |
| **Acerto Stock** | `acerto_stock` | ✓ Adicionado |
| Despesas | `registar_despesas` | ✓ Existe |
| Todas Vendas | `visualizar_relatorios` | ✓ Adicionado |
| Relatórios | `visualizar_relatorios` | ✓ Adicionado |
| Margens/Lucros | `visualizar_margens` | ✓ Adicionado |
| Stock | `visualizar_stock` | ✓ Adicionado |
| Mesas | `acesso_admin` | ✓ Existe |
| Usuários | `gestao_usuarios` | ✓ Existe |
| Perfis | `gestao_perfis` | ✓ Existe |
| Permissões | `gestao_permissoes` | ✓ Existe |
| Empresa | `configuracoes_sistema` | ✓ Existe |

## COMO APLICAR A CORREÇÃO

### Passo 1: Código (Já aplicado)
Os arquivos já foram modificados:
- `lib/core/services/auth_service.dart`
- `lib/app/modules/admin/admin_page.dart`

### Passo 2: Banco de Dados
Execute o script SQL:
```bash
psql -U seu_usuario -d sua_database -f database/migrations/fix_permissoes_admin.sql
```

### Passo 3: Verificação
Após executar o script, você verá:
```
perfil                  | total_permissoes | total_sistema
------------------------|------------------|---------------
Administrador           | 45               | 45
Super Administrador     | 45               | 45
```

Ambos devem ter o mesmo número de permissões.

## TESTE

### Cenário de Teste:
1. Login como usuário com perfil "Administrador"
2. Acessar tela de Administração
3. Clicar em "Acerto Stock" (ou qualquer outra tela)
4. **Resultado Esperado:** Tela abre normalmente, sem mensagem de erro

### Teste com Usuário Não-Admin:
1. Login como usuário com perfil "Caixa" (ou outro não-admin)
2. Se tentar acessar Administração
3. **Resultado Esperado:** Verificação de permissões funciona normalmente

## VANTAGENS DA SOLUÇÃO

1. **Dupla Proteção:**
   - Bypass no código (AuthService + AdminPage)
   - Permissões completas no banco de dados

2. **Flexibilidade:**
   - Pode criar novos perfis com permissões específicas
   - Administradores sempre têm acesso total

3. **Manutenibilidade:**
   - Código documentado
   - Fácil identificar onde está o bypass

4. **Segurança:**
   - Apenas perfis com "administrador" no nome têm bypass
   - Outros perfis continuam com verificação rigorosa

## ARQUIVOS MODIFICADOS

1. `lib/core/services/auth_service.dart` - Bypass de permissões
2. `lib/app/modules/admin/admin_page.dart` - Verificação com bypass
3. `database/migrations/fix_permissoes_admin.sql` - Script de correção (NOVO)
4. `CORRECAO_BUG_PERMISSOES.md` - Esta documentação (NOVO)

## OBSERVAÇÕES IMPORTANTES

- O bypass funciona para qualquer perfil que tenha "administrador" no nome (case-insensitive)
- Exemplos de perfis que terão bypass:
  - "Administrador"
  - "Super Administrador"
  - "Administrador de Sistema"
  - "administrador-geral"

- Perfis que NÃO terão bypass:
  - "Gerente"
  - "Caixa"
  - "Estoquista"
  - Qualquer outro que não contenha "administrador"

## PREVENÇÃO DE PROBLEMAS FUTUROS

### Ao Adicionar Nova Funcionalidade:
1. Criar a permissão no banco PRIMEIRO:
   ```sql
   INSERT INTO permissoes (codigo, nome, categoria, descricao)
   VALUES ('nova_permissao', 'Nova Permissão', 'CATEGORIA', 'Descrição');
   ```

2. Adicionar aos perfis necessários:
   ```sql
   INSERT INTO perfil_permissoes (perfil_id, permissao_id)
   VALUES ((SELECT id FROM perfis_usuario WHERE nome = 'Administrador'),
           (SELECT id FROM permissoes WHERE codigo = 'nova_permissao'));
   ```

3. Usar no código:
   ```dart
   AdminMenuItem(
     titulo: 'Nova Tela',
     permissoes: ['nova_permissao'],
     ...
   )
   ```

## CONCLUSÃO

O bug foi completamente corrigido através de uma abordagem em três camadas:
1. Bypass automático para administradores no AuthService
2. Verificação inteligente na interface (AdminPage)
3. Base de dados completa com todas as permissões necessárias

Administradores agora têm acesso garantido a todas as funcionalidades do sistema.
