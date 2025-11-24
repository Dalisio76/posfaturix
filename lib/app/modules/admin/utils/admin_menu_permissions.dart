/// Mapeamento de permissões necessárias para cada item do menu Admin
class AdminMenuPermissions {
  static const Map<int, List<String>> menuPermissions = {
    0: [], // Empresa - todos podem ver
    1: ['registar_familias'], // Famílias
    2: ['registar_produtos'], // Produtos
    3: [], // Formas de Pagamento - todos podem ver
    4: ['registar_setores'], // Setores
    5: ['registar_setores'], // Áreas (usa mesma permissão de setores)
    6: ['registar_clientes'], // Clientes
    7: ['registar_despesas'], // Despesas
    8: ['registar_fornecedores'], // Fornecedores
    9: ['entrada_stock'], // Faturas de Entrada
    10: ['gestao_mesas'], // Mesas
    11: ['relatorios'], // Relatórios
    12: ['reportar_margens_fecho'], // Margens/Lucros
    13: ['acerto_stock'], // Acerto de Stock
    14: ['ver_stock'], // Relatório de Stock
    15: ['gestao_usuarios'], // Usuários
    16: ['gestao_perfis'], // Perfis de Usuário
    17: ['gestao_permissoes'], // Configurar Permissões
    18: ['configuracoes_sistema'], // Configurações do Sistema
  };

  /// Retorna as permissões necessárias para acessar um menu
  static List<String> getPermissions(int menuIndex) {
    return menuPermissions[menuIndex] ?? [];
  }

  /// Verifica se pelo menos uma das permissões é necessária
  static bool requiresPermission(int menuIndex) {
    final perms = getPermissions(menuIndex);
    return perms.isNotEmpty;
  }
}
