# 💰 Sistema de Anuidade e Atualização

**Data:** 04/12/2025

---

## 📋 ÍNDICE

1. [Como Funciona a Anuidade](#como-funciona-a-anuidade)
2. [Gerar Códigos de Ativação](#gerar-códigos-de-ativação)
3. [Renovação pelo Cliente](#renovação-pelo-cliente)
4. [Processo de Atualização](#processo-de-atualização)
5. [FAQ](#faq)

---

## 🔐 COMO FUNCIONA A ANUIDADE

### Sistema de Licenciamento

O sistema possui controle de anuidade **automático** e **local** (não requer internet):

**Características:**
- ✅ Licença de **365 dias** (1 ano)
- ✅ Aviso **30 dias antes** do vencimento
- ✅ Alerta **diário** quando faltam menos de 30 dias
- ✅ Bloqueio **total** após vencimento
- ✅ Renovação via **código de ativação**

### Ciclo de Vida da Licença

```
DIA 0 (Instalação)
├─ Sistema ativado automaticamente
├─ Válido por 365 dias
│
DIA 335 (30 dias antes)
├─ 📢 Alerta diário aparece
├─ ⚠️ "Sua licença vence em X dias"
├─ Sistema continua funcionando normalmente
│
DIA 365 (Vencimento)
├─ 🔴 Sistema bloqueado
├─ Mensagem: "LICENÇA VENCIDA"
├─ Só permite renovar ou sair
│
RENOVAÇÃO
├─ Cliente insere código de ativação
├─ Nova licença de 365 dias
└─ Sistema desbloqueado
```

### Alertas ao Usuário

**30 a 1 dia antes:**
```
⚠️ LICENÇA PRÓXIMA DO VENCIMENTO

Sua licença vence em 15 dia(s).

Para evitar interrupções, renove sua anuidade o quanto antes.

Telefone: [SEU TELEFONE]
Email: [SEU EMAIL]
```
- ✅ Dialog pode ser fechado
- ✅ Sistema continua funcionando
- ✅ Aparece 1 vez por dia

**Após vencimento:**
```
🔴 LICENÇA VENCIDA

Sua licença do sistema expirou.

Para continuar usando o sistema, entre em contato para renovar.
```
- ❌ Dialog NÃO pode ser fechado
- ❌ Sistema bloqueado
- ✅ Só aceita código de ativação ou sair

---

## 🔑 GERAR CÓDIGOS DE ATIVAÇÃO

### Método 1: Programaticamente (Recomendado)

Execute no seu ambiente de desenvolvimento:

```dart
import 'package:posfaturix/core/services/licenca_service.dart';

void main() {
  final licencaService = LicencaService();

  // Gerar código válido por 1 ano a partir de hoje
  final codigo = licencaService.gerarCodigoAtivacao();

  print('📝 Código de Ativação: $codigo');
  // Exemplo: 2026-0105-AB3F
}
```

**Formato do Código:**
```
AAAA-MMDD-XXXX
│    │    └─ Hash de validação (4 caracteres hexadecimais)
│    └────── Mês e dia de vencimento (MMDD)
└───────── Ano de vencimento (AAAA)
```

**Exemplo:**
- Código: `2026-0105-AB3F`
- Vence em: `05/01/2026`
- Válido por: 1 ano a partir da ativação

### Método 2: Ferramenta de Geração

Crie um executável simples para gerar códigos:

**Arquivo:** `tools/gerador_codigos.dart`
```dart
import 'dart:io';
import 'package:posfaturix/core/services/licenca_service.dart';

void main() {
  print('═══════════════════════════════════════');
  print('   GERADOR DE CÓDIGOS DE ATIVAÇÃO     ');
  print('═══════════════════════════════════════');
  print('');

  final licencaService = LicencaService();

  // Gerar 5 códigos
  for (int i = 1; i <= 5; i++) {
    final codigo = licencaService.gerarCodigoAtivacao();
    print('Código $i: $codigo');
  }

  print('');
  print('Cada código é válido por 365 dias a partir da ativação.');
  print('');
}
```

**Executar:**
```bash
dart run tools/gerador_codigos.dart
```

### Método 3: Interface Web/Desktop

Crie uma ferramenta interna com interface gráfica:

```dart
// Exemplo de tela de geração
ElevatedButton(
  onPressed: () {
    final codigo = licencaService.gerarCodigoAtivacao();
    Clipboard.setData(ClipboardData(text: codigo));

    Get.snackbar('Código Gerado', 'Código copiado: $codigo');
  },
  child: Text('GERAR CÓDIGO'),
)
```

---

## 🔄 RENOVAÇÃO PELO CLIENTE

### Passo a Passo para o Cliente

**1. Cliente Recebe Alerta**

30 dias antes do vencimento, o sistema mostra alerta diário.

**2. Cliente Entra em Contato**

Cliente liga/envia email solicitando renovação:
- Nome da empresa
- Data de vencimento atual
- Forma de pagamento

**3. Você Gera e Envia o Código**

Após confirmar pagamento:
```
Assunto: Código de Ativação - Renovação Anual

Olá [CLIENTE],

Segue o código de ativação para renovar sua licença do sistema:

┌─────────────────────────────┐
│   2026-0105-AB3F           │
└─────────────────────────────┘

Válido até: 05/01/2026

Como ativar:
1. Abra o sistema
2. Clique em "Renovar Licença" ou aguarde o alerta
3. Digite o código acima
4. Clique em "ATIVAR"

Qualquer dúvida, estamos à disposição!
```

**4. Cliente Ativa no Sistema**

No alerta de vencimento:
1. Cliente vê campo "Código de Ativação"
2. Digita: `2026-0105-AB3F`
3. Clica em "ATIVAR"
4. Sistema valida e renova automaticamente
5. Mensagem: "✅ Licença ativada com sucesso!"

---

## 🔧 PROCESSO DE ATUALIZAÇÃO DO SISTEMA

### Opção 1: Atualização Manual (Simples)

**Para o Cliente:**

1. **Baixar nova versão**
   - Você envia pasta atualizada por email/link
   - Exemplo: `PosFaturix_v2.0.zip`

2. **Fazer backup** (importante!)
   ```
   C:\PosFaturix\         → Renomear para C:\PosFaturix_backup\
   ```

3. **Instalar nova versão**
   - Descompactar `PosFaturix_v2.0.zip` em `C:\PosFaturix\`
   - Executar `posfaturix.exe`

4. **Verificar funcionamento**
   - Sistema usa mesmo banco de dados
   - Licença permanece válida
   - Configurações mantidas

**Vantagens:**
- ✅ Simples e direto
- ✅ Cliente faz sozinho
- ✅ Não requer internet

**Desvantagens:**
- ❌ Cliente pode errar
- ❌ Não é automático

### Opção 2: Atualização Semi-Automática (Recomendado)

Crie um **script de atualização** que você envia junto:

**Arquivo:** `atualizar.bat`
```batch
@echo off
echo ════════════════════════════════════════
echo    ATUALIZACAO POSFATURIX
echo ════════════════════════════════════════
echo.

:: Parar processos em execução
echo Encerrando aplicacao...
taskkill /F /IM posfaturix.exe 2>nul

:: Fazer backup
echo Criando backup...
if not exist "C:\PosFaturix_backup\" mkdir "C:\PosFaturix_backup\"
xcopy "C:\PosFaturix\*" "C:\PosFaturix_backup\" /E /I /Y

:: Instalar nova versão
echo Instalando atualizacao...
xcopy "nova_versao\*" "C:\PosFaturix\" /E /I /Y

echo.
echo ✅ Atualizacao concluida com sucesso!
echo.
echo Pressione qualquer tecla para iniciar o sistema...
pause >nul

:: Iniciar sistema atualizado
start "" "C:\PosFaturix\posfaturix.exe"
```

**Como usar:**
1. Você cria pasta `PosFaturix_v2.0\`
2. Coloca executável atualizado em `PosFaturix_v2.0\nova_versao\`
3. Coloca `atualizar.bat` na raiz
4. Envia tudo para o cliente
5. Cliente executa `atualizar.bat`

**Vantagens:**
- ✅ Automático
- ✅ Faz backup automático
- ✅ Menos erros

### Opção 3: Atualização Automática (Avançado)

Implementar sistema de auto-atualização:

**Funcionalidades:**
- Verificar atualizações via servidor
- Download automático
- Instalação com um clique
- Rollback se falhar

**Exemplo:**
```dart
class UpdateService {
  static const String updateUrl = 'https://seusite.com/updates/latest.json';

  Future<bool> verificarAtualizacao() async {
    final response = await http.get(Uri.parse(updateUrl));
    final info = json.decode(response.body);

    final versaoAtual = '1.0.0';
    final versaoNova = info['version'];

    return versaoNova != versaoAtual;
  }

  Future<void> baixarEInstalar() async {
    // Baixar novo executável
    // Substituir arquivo
    // Reiniciar aplicação
  }
}
```

**Requer:**
- Servidor para hospedar atualizações
- Conexão com internet
- Implementação mais complexa

---

## 📦 ESTRUTURA DE RELEASE

Quando for lançar uma atualização:

### Checklist de Release

- [ ] Testar todas funcionalidades
- [ ] Incrementar versão no `pubspec.yaml`
- [ ] Compilar para Windows Release
- [ ] Criar pasta de distribuição
- [ ] Gerar changelog
- [ ] Testar instalação limpa
- [ ] Testar atualização de versão anterior
- [ ] Documentar mudanças

### Estrutura de Pasta para Cliente

```
PosFaturix_v2.0/
├── posfaturix.exe
├── data/
├── flutter_windows.dll
├── pdfium.dll
├── printing_plugin.dll
├── CHANGELOG.md              ← O que mudou
├── INSTRUCOES_ATUALIZACAO.md ← Como atualizar
└── atualizar.bat            ← Script automático
```

### Changelog Exemplo

**Arquivo:** `CHANGELOG.md`
```markdown
# Versão 2.0.0 - 05/01/2026

## ✨ Novidades
- Relatório de Produtos com Stock Baixo
- Relatório de Vendedor/Operador
- Relatório de Produtos Pedidos
- Sistema de anuidade/licenciamento

## 🔧 Melhorias
- Interface mais compacta (estilo Windows)
- Numeração de vendas simplificada (1, 2, 3...)
- Tela de configuração de banco de dados
- Detecção de instância única

## 🐛 Correções
- Corrigido erro de múltiplas janelas
- Corrigido erro em relatórios
- Melhorado tratamento de conexão

## ⚠️ Importante
- Execute migrations SQL antes de usar
- Licença válida por 365 dias
```

---

## 💡 FAQ

### Como saber quando a licença do cliente vence?

**Opção 1:** Cliente informa quando solicita renovação

**Opção 2:** Implementar relatório remoto (avançado)
```dart
// Cliente envia log para servidor
POST https://seusite.com/api/licencas
{
  "cliente_id": "12345",
  "data_vencimento": "2026-01-05",
  "dias_restantes": 15
}
```

### O que acontece se o cliente mudar de computador?

**Resposta:** A licença é **local** (salva no computador):
- No PC antigo: Licença permanece
- No PC novo: Precisa ativar novamente com código

**Solução:** Gere novo código gratuito para migração.

### Posso oferecer períodos diferentes (6 meses, 2 anos)?

**Sim!** Modifique em `licenca_service.dart`:
```dart
// Para 6 meses
static const int diasLicenca = 180;

// Para 2 anos
static const int diasLicenca = 730;
```

Ou crie planos diferentes:
```dart
enum TipoPlano {
  mensal(30),
  semestral(180),
  anual(365),
  bienal(730);

  final int dias;
  const TipoPlano(this.dias);
}
```

### Como testar o sistema de licença?

**Método 1:** Reduzir dias temporariamente
```dart
static const int diasLicenca = 2; // 2 dias para teste
static const int diasAvisoAntecipado = 1; // Avisar 1 dia antes
```

**Método 2:** Usar método de reset
```dart
final licencaService = Get.find<LicencaService>();
await licencaService.resetarLicenca();
```

**Método 3:** Modificar data manualmente
```dart
// Em desenvolvimento apenas!
final prefs = await SharedPreferences.getInstance();
final dataVencida = DateTime.now().subtract(Duration(days: 10));
await prefs.setString('data_ativacao', dataVencida.toIso8601String());
```

### Como fazer upgrade de plano (mensal para anual)?

Gere código com validade estendida:
```dart
// Cliente tem licença até 01/02/2026 (mensal)
// Quer upgrade para anual (mais 11 meses)

final dataAtual = DateTime(2026, 2, 1); // Data de vencimento atual
final novaData = dataAtual.add(Duration(days: 11 * 30)); // +11 meses

// Gerar código manualmente para esta data
```

### Posso desativar o sistema de licença?

**Sim**, mas não recomendado:

```dart
// Em licenca_service.dart
Future<void> verificarLicenca() async {
  // Comentar tudo e forçar válida
  licencaValida.value = true;
  diasRestantes.value = 999999;
  mostrarAlerta.value = false;
  return;
}
```

### Como migrar banco de dados entre atualizações?

**Usando Migrations:**
1. Crie arquivo SQL na pasta `database/migrations/`
2. Numere sequencialmente: `008_nova_feature.sql`
3. Cliente executa antes de usar nova versão

**Exemplo:**
```sql
-- database/migrations/008_add_campo_x.sql
ALTER TABLE produtos ADD COLUMN campo_novo VARCHAR(255);
```

---

## ✅ RESUMO

### Para Você (Desenvolvedor/Fornecedor):

1. **Gerar códigos** quando cliente solicitar renovação
2. **Enviar código** por email/WhatsApp
3. **Criar atualizações** com changelog e instruções
4. **Distribuir** via email, link ou pen drive

### Para o Cliente:

1. **Receber alerta** 30 dias antes
2. **Entrar em contato** para renovar
3. **Receber código** após pagamento
4. **Ativar** no sistema (simples!)
5. **Continuar usando** por mais 1 ano

### Fluxo Completo:

```
CLIENTE                    VOCÊ
   │                        │
   ├─ Alerta 30 dias        │
   │                        │
   ├─ Solicita renovação ──>│
   │                        │
   │                  Confirma pagamento
   │                        │
   │                  Gera código
   │                        │
   │<──── Envia código ─────┤
   │                        │
   ├─ Ativa no sistema      │
   │                        │
   └─ ✅ Renovado!          │
```

---

**O sistema está pronto para monetizar! 💰**

Todos os arquivos criados:
1. ✅ `licenca_service.dart` - Lógica de licenciamento
2. ✅ `licenca_dialog.dart` - Interface de ativação
3. ✅ `main.dart` - Integração no startup
4. ✅ Esta documentação completa

**Próximo passo:** Compilar e testar!
