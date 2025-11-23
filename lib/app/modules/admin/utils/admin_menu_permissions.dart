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
    10: ['relatorios'], // Relatórios
    11: ['reportar_margens_fecho'], // Margens/Lucros
    12: ['acerto_stock'], // Acerto de Stock
    13: ['ver_stock'], // Relatório de Stock
    14: ['gestao_usuarios'], // Usuários
    15: ['gestao_perfis'], // Perfis de Usuário
    16: ['gestao_permissoes'], // Configurar Permissões
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
