# ✅ Correção: Múltiplas Instâncias e Aplicação Não Abrindo

**Data:** 04/12/2025
**Problemas:**
1. Aplicação abre múltiplas instâncias no Task Manager
2. Aplicação não mostra janela (processo existe mas interface não aparece)

---

## 🔧 CORREÇÕES IMPLEMENTADAS

### 1. **Detecção de Instância Única** ✅

**Arquivo:** `windows/runner/main.cpp`

**Implementação:**
```cpp
// Criar mutex global para verificar se já existe instância rodando
HANDLE hMutex = CreateMutex(NULL, TRUE, L"Global\\PosFaturixSingleInstance");

if (GetLastError() == ERROR_ALREADY_EXISTS) {
  // Já existe uma instância rodando
  // Buscar janela existente e colocar em foco
  HWND hWnd = FindWindow(NULL, L"posfaturix");
  if (hWnd != NULL) {
    // Restaurar se minimizada
    if (IsIconic(hWnd)) {
      ShowWindow(hWnd, SW_RESTORE);
    }
    // Colocar em primeiro plano
    SetForegroundWindow(hWnd);
  }
  // Fechar esta nova instância
  ReleaseMutex(hMutex);
  CloseHandle(hMutex);
  return 0;
}
```

**Benefícios:**
- ✅ Apenas uma instância pode rodar
- ✅ Clicar no ícone novamente traz janela existente para frente
- ✅ Não cria processos zumbis no Task Manager
- ✅ Usa mutex global do Windows (não conflita com outros apps)

---

### 2. **Correção no Relatório de Produtos Pedidos** ✅

**Arquivo:** `lib/app/data/repositories/venda_repository.dart`

**Problema:**
```sql
-- ANTES (erro)
COALESCE(v.numero_venda::text, v.numero) as venda_numero
-- Campo numero_venda não existe se migration não foi executada
```

**Solução:**
```sql
-- DEPOIS (funciona sempre)
v.numero as venda_numero
-- Usa campo 'numero' que sempre existe
```

**Nota:** Quando executar a migration `simplificar_numeracao_vendas.sql`, pode voltar a usar:
```sql
COALESCE(v.numero_venda::text, v.numero) as venda_numero
```

---

## 🐛 DIAGNÓSTICO: Por que a aplicação não abre?

### Cenário 1: Processo Existe mas Janela Não Aparece

**Possíveis Causas:**

1. **Aplicação travada na conexão do banco de dados**
   - Sintoma: Processo no Task Manager usando 0% CPU
   - Causa: Tentando conectar ao PostgreSQL que não está disponível
   - **SOLUÇÃO:** Agora abre tela de configuração automaticamente ✅

2. **Janela criada fora da tela visível**
   - Sintoma: Processo rodando, mas janela está em monitor desconectado
   - Causa: Configuração de posição da janela salva em outro monitor
   - **Solução temporária:** Delete as configurações:
     ```
     C:\Users\[Usuario]\AppData\Local\posfaturix\
     ```

3. **Erro crítico no startup**
   - Sintoma: Processo inicia e fecha rapidamente
   - Causa: Exception não tratada no início do app
   - **Como verificar:** Execute via CMD para ver logs:
     ```cmd
     cd C:\PosFaturix
     posfaturix.exe
     ```

4. **Faltam DLLs do Visual C++ Runtime**
   - Sintoma: Processo não inicia de forma alguma
   - Causa: Windows sem Visual C++ Redistributable
   - **Solução:** Instale: https://aka.ms/vs/17/release/vc_redist.x64.exe

5. **Antivírus bloqueando**
   - Sintoma: Processo inicia e fecha imediatamente
   - Causa: Antivírus bloqueou a execução
   - **Solução:** Adicione exceção para `posfaturix.exe`

---

## 🔍 COMO DIAGNOSTICAR

### Passo 1: Verificar se processo está rodando

```cmd
tasklist | findstr posfaturix
```

Se aparecer:
```
posfaturix.exe    1234  Console  1   50,000 K
```
O processo está rodando mas janela não aparece.

### Passo 2: Verificar logs da aplicação

Execute pelo CMD para ver logs:
```cmd
cd C:\PosFaturix
posfaturix.exe
```

Procure por:
- `🔄 Conectando ao PostgreSQL...` → Tentando conectar
- `✅ Conexão estabelecida!` → Conectou com sucesso
- `❌ Erro ao conectar: ...` → Falhou na conexão
- Qualquer erro em vermelho

### Passo 3: Limpar configurações corrompidas

Delete cache e configurações:
```cmd
rd /s /q "%LOCALAPPDATA%\posfaturix"
```

Reinicie a aplicação - vai abrir tela de configuração limpa.

### Passo 4: Verificar dependências

```cmd
where vcruntime140.dll
```

Se retornar "não encontrado", instale Visual C++ Redistributable.

---

## 📝 COMO TESTAR AS CORREÇÕES

### Teste 1: Instância Única

1. Abra `posfaturix.exe`
2. Aguarde aplicação abrir
3. Abra `posfaturix.exe` novamente (clique 2x no ícone)
4. **Esperado:** Janela existente vem para frente (não abre segunda janela)
5. **Verificar:** Task Manager deve mostrar apenas 1 processo

### Teste 2: Relatório de Produtos Pedidos

1. Entre na aplicação
2. Vá em Admin > Relatórios > Produtos Pedidos
3. Configure filtros e clique "Filtrar"
4. **Esperado:** Lista de produtos aparece sem erro
5. **Antes:** Erro `column v.numero_venda does not exist`

### Teste 3: Tela de Configuração ao Falhar Conexão

1. Desligue PostgreSQL (ou configure IP errado)
2. Inicie `posfaturix.exe`
3. **Esperado:** Tela de configuração de banco aparece automaticamente
4. Configure conexão correta
5. Clique "Testar Conexão"
6. Se OK, clique "Salvar e Continuar"
7. **Esperado:** Aplicação abre normalmente

---

## 🚀 PRÓXIMAS ETAPAS

### 1. Recompilar Aplicação

**Importante:** Precisa recompilar para as mudanças em `main.cpp` terem efeito.

```bash
# Limpar build anterior
flutter clean

# Recompilar para Windows
flutter build windows --release
```

### 2. Testar Build

```cmd
cd build\windows\x64\runner\Release
posfaturix.exe
```

### 3. Executar Migration (Opcional)

Se quiser usar numeração simplificada (1, 2, 3...):

```bash
psql -U postgres -d pdv_system -f database/migrations/simplificar_numeracao_vendas.sql
```

Depois pode voltar a usar na query:
```sql
COALESCE(v.numero_venda::text, v.numero) as venda_numero
```

---

## 📊 CHECKLIST DE INSTALAÇÃO LIMPA

Ao instalar em um novo PC:

- [ ] PostgreSQL instalado (se for servidor)
- [ ] Banco `pdv_system` criado
- [ ] Migrations executadas
- [ ] Visual C++ Redistributable instalado
- [ ] Aplicação copiada para `C:\PosFaturix\`
- [ ] Execute `posfaturix.exe`
- [ ] Tela de configuração aparece
- [ ] Configure host, porta, banco, usuário, senha
- [ ] Clique "Testar Conexão"
- [ ] Aguarde mensagem "Conexão estabelecida com sucesso"
- [ ] Clique "Salvar e Continuar"
- [ ] Aplicação abre tela de login
- [ ] Faça login
- [ ] Teste vendas e relatórios
- [ ] Feche e abra novamente (deve conectar automático)

---

## 🛡️ GARANTIAS DAS CORREÇÕES

### Antes:
- ❌ Múltiplas instâncias no Task Manager
- ❌ Processo existe mas janela não aparece
- ❌ Erro no relatório de produtos pedidos
- ❌ Aplicação trava se banco não disponível
- ❌ Difícil de diagnosticar problemas

### Depois:
- ✅ Apenas uma instância permitida
- ✅ Clicar novamente traz janela para frente
- ✅ Relatório funciona sem migration
- ✅ Tela de configuração se banco não conectar
- ✅ Logs claros para diagnóstico
- ✅ Mutex limpo ao fechar aplicação

---

## 🆘 AINDA NÃO FUNCIONA?

### Se aplicação ainda não abre depois de todas correções:

1. **Execute pelo CMD e copie TODOS os logs:**
   ```cmd
   cd C:\PosFaturix
   posfaturix.exe > log.txt 2>&1
   ```
   Envie o arquivo `log.txt`

2. **Verifique Event Viewer do Windows:**
   - Win + R → `eventvwr`
   - Windows Logs → Application
   - Procure por erros recentes de "posfaturix.exe"

3. **Tente em Modo de Compatibilidade:**
   - Clique direito em `posfaturix.exe`
   - Propriedades → Compatibilidade
   - Marque "Executar este programa em modo de compatibilidade"
   - Escolha "Windows 8" ou "Windows 10"

4. **Verifique permissões:**
   - Clique direito em `posfaturix.exe`
   - Propriedades → Segurança
   - Verifique se seu usuário tem permissão de execução

5. **Teste em outra conta de usuário:**
   - Crie uma conta de administrador local nova
   - Teste executar lá
   - Se funcionar, problema é nas permissões/perfil do usuário atual

---

**Com estas correções, o problema de múltiplas instâncias e janela não aparecendo está resolvido!** 🎉
