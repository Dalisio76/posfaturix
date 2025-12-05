; =====================================================
; INNO SETUP - INSTALADOR PROFISSIONAL POSFATURIX
; =====================================================
; Este script cria um instalador .exe profissional
;
; REQUISITOS:
; 1. Inno Setup 6 instalado: https://jrsoftware.org/isdl.php
; 2. Flutter build completo em: build\windows\x64\runner\Release
; 3. Ícone em: assets\favicon.ico
;
; COMO USAR:
; 1. Faça o build: flutter build windows --release
; 2. Abra este arquivo no Inno Setup
; 3. Clique em "Compile" (F9)
; 4. Instalador será gerado em: installer\Output\
; =====================================================

#define MyAppName "PosFaturix"
#define MyAppVersion "2.5.0"
#define MyAppPublisher "Faturix Solutions"
#define MyAppURL "https://faturix.com"
#define MyAppExeName "posfaturix.exe"
#define MyAppDescription "Sistema POS Profissional para Restaurantes"

[Setup]
; Informações básicas
AppId={{B8F4E9D2-7A3C-4F5E-9B8D-1C2E3F4A5B6C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppComments={#MyAppDescription}

; Diretório de instalação padrão
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

; Ícone do instalador
SetupIconFile=..\assets\favicon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; Diretório de saída
OutputDir=Output
OutputBaseFilename=PosFaturix_Setup_{#MyAppVersion}

; Compressão
Compression=lzma2/max
SolidCompression=yes

; Privilégios administrativos
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; Interface moderna
WizardStyle=modern

; Configurações de desinstalação
UninstallDisplayName={#MyAppName}
UninstallFilesDir={app}\uninstall

; Criar atalhos
AllowNoIcons=yes
DisableProgramGroupPage=yes
DisableReadyPage=no

; Arquitetura
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "portugues"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "quicklaunchicon"; Description: "Criar ícone na Barra de Tarefas"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "startup"; Description: "Iniciar com o Windows"; GroupDescription: "Inicialização automática:"; Flags: unchecked

[Files]
; Executável principal e DLLs
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; Data folder (recursos do Flutter)
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Ícone
Source: "..\assets\favicon.ico"; DestDir: "{app}"; Flags: ignoreversion

; Arquivos de configuração e scripts
Source: "database_inicial.sql"; DestDir: "{app}\database"; Flags: ignoreversion
Source: "configurar_database.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "README_INSTALACAO.txt"; DestDir: "{app}"; Flags: ignoreversion isreadme

; Documentação
Source: "..\GUIA_IMPRESSORAS_REDE.md"; DestDir: "{app}\docs"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\SISTEMA_IMPRESSORAS.md"; DestDir: "{app}\docs"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
; Atalho no Menu Iniciar
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\favicon.ico"; Comment: "{#MyAppDescription}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{group}\Configurar Base de Dados"; Filename: "{app}\configurar_database.bat"; IconFilename: "{sys}\imageres.dll"; IconIndex: 109

; Atalho na Área de Trabalho
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\favicon.ico"; Tasks: desktopicon

; Atalho na Barra de Tarefas (Windows 7+)
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\favicon.ico"; Tasks: quicklaunchicon

; Iniciar com Windows
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startup

[Run]
; Executar após instalação
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; Abrir README
Filename: "{app}\README_INSTALACAO.txt"; Description: "Ver instruções de configuração"; Flags: postinstall shellexec skipifsilent unchecked

[UninstallDelete]
; Limpar arquivos criados pelo app
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\logs"
Type: files; Name: "{app}\*.log"

[Code]
var
  DatabasePage: TInputQueryWizardPage;
  UsuarioAdminPage: TInputQueryWizardPage;
  ConfiguracaoPage: TOutputMsgWizardPage;

// =====================================================
// PÁGINA: Configuração da Base de Dados
// =====================================================
procedure InitializeWizard;
begin
  // Página para configurar conexão com PostgreSQL
  DatabasePage := CreateInputQueryPage(wpSelectDir,
    'Configuração da Base de Dados',
    'Configure a conexão com o PostgreSQL',
    'O PosFaturix requer PostgreSQL instalado. Se ainda não tem, baixe em: https://www.postgresql.org/download/');

  DatabasePage.Add('Servidor PostgreSQL (host):', False);
  DatabasePage.Add('Porta:', False);
  DatabasePage.Add('Nome da base de dados:', False);
  DatabasePage.Add('Usuário PostgreSQL:', False);
  DatabasePage.Add('Senha PostgreSQL:', True);

  // Valores padrão
  DatabasePage.Values[0] := 'localhost';
  DatabasePage.Values[1] := '5432';
  DatabasePage.Values[2] := 'pdv_system';
  DatabasePage.Values[3] := 'postgres';
  DatabasePage.Values[4] := '';

  // Página para criar usuário administrador
  UsuarioAdminPage := CreateInputQueryPage(DatabasePage.ID,
    'Usuário Administrador',
    'Crie o usuário super administrador do sistema',
    'Este usuário terá acesso total ao sistema. O código deve ter 4 dígitos.');

  UsuarioAdminPage.Add('Nome do administrador:', False);
  UsuarioAdminPage.Add('Código de acesso (4 dígitos):', False);

  // Valores padrão
  UsuarioAdminPage.Values[0] := 'Admin';
  UsuarioAdminPage.Values[1] := '0000';

  // Página informativa
  ConfiguracaoPage := CreateOutputMsgPage(UsuarioAdminPage.ID,
    'Configuração Completa',
    'Próximos passos após a instalação',
    'Após concluir a instalação:' + #13#10 + #13#10 +
    '1. Execute "Configurar Base de Dados" no Menu Iniciar' + #13#10 +
    '2. Ou execute manualmente o script: database\database_inicial.sql' + #13#10 +
    '3. Configure a impressora padrão no Admin > Configurações' + #13#10 +
    '4. Faça login com o código configurado' + #13#10 + #13#10 +
    'IMPORTANTE: PostgreSQL 12+ deve estar instalado!');
end;

// Validar entrada da página de database
function NextButtonClick(CurPageID: Integer): Boolean;
var
  Codigo: String;
begin
  Result := True;

  // Validar configuração de database
  if CurPageID = DatabasePage.ID then
  begin
    if (DatabasePage.Values[0] = '') or
       (DatabasePage.Values[1] = '') or
       (DatabasePage.Values[2] = '') or
       (DatabasePage.Values[3] = '') or
       (DatabasePage.Values[4] = '') then
    begin
      MsgBox('Preencha todos os campos da configuração da base de dados!', mbError, MB_OK);
      Result := False;
    end;
  end;

  // Validar usuário admin
  if CurPageID = UsuarioAdminPage.ID then
  begin
    Codigo := UsuarioAdminPage.Values[1];

    if UsuarioAdminPage.Values[0] = '' then
    begin
      MsgBox('Digite o nome do administrador!', mbError, MB_OK);
      Result := False;
    end
    else if Length(Codigo) <> 4 then
    begin
      MsgBox('O código deve ter exatamente 4 dígitos!', mbError, MB_OK);
      Result := False;
    end
    else if (Pos(Codigo[1], '0123456789') = 0) or
            (Pos(Codigo[2], '0123456789') = 0) or
            (Pos(Codigo[3], '0123456789') = 0) or
            (Pos(Codigo[4], '0123456789') = 0) then
    begin
      MsgBox('O código deve conter apenas números!', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

// Salvar configurações após instalação
procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigFile: String;
  ConfigContent: TArrayOfString;
begin
  if CurStep = ssPostInstall then
  begin
    // Criar arquivo de configuração com os dados informados
    ConfigFile := ExpandConstant('{app}\installer_config.txt');

    SetArrayLength(ConfigContent, 7);
    ConfigContent[0] := 'DB_HOST=' + DatabasePage.Values[0];
    ConfigContent[1] := 'DB_PORT=' + DatabasePage.Values[1];
    ConfigContent[2] := 'DB_NAME=' + DatabasePage.Values[2];
    ConfigContent[3] := 'DB_USER=' + DatabasePage.Values[3];
    ConfigContent[4] := 'DB_PASS=' + DatabasePage.Values[4];
    ConfigContent[5] := 'ADMIN_NAME=' + UsuarioAdminPage.Values[0];
    ConfigContent[6] := 'ADMIN_CODE=' + UsuarioAdminPage.Values[1];

    SaveStringsToFile(ConfigFile, ConfigContent, False);

    // Informar ao usuário
    MsgBox('Configurações salvas em: ' + ConfigFile + #13#10 + #13#10 +
           'Execute "Configurar Base de Dados" para criar a base de dados automaticamente.',
           mbInformation, MB_OK);
  end;
end;

[Messages]
; Mensagens customizadas em português
WelcomeLabel2=Este assistente irá instalar o [name/ver] no seu computador.%n%nÉ recomendado que feche todas as outras aplicações antes de continuar.%n%nIMPORTANTE: Certifique-se de que o PostgreSQL está instalado!
FinishedLabel=O [name] foi instalado com sucesso no seu computador.%n%nPara começar a usar, execute "Configurar Base de Dados" e depois inicie a aplicação.

[UninstallRun]
; Opcional: Limpar dados ao desinstalar (perguntar ao usuário)
; Filename: "{cmd}"; Parameters: "/c echo Deseja remover também a base de dados? && pause"; Flags: runhidden waituntilterminated

; =====================================================
; FIM DO SCRIPT INNO SETUP
; =====================================================
