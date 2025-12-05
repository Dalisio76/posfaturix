import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/data/models/definicao_model.dart';

/// Serviço para gerenciar definições/configurações do sistema
class DefinicoesService {
  static const String _keyDefinicoes = 'definicoes_sistema';

  /// Salvar definições
  static Future<void> salvar(DefinicaoModel definicoes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(definicoes.toJson());
      await prefs.setString(_keyDefinicoes, json);
    } catch (e) {
      print('Erro ao salvar definições: $e');
      rethrow;
    }
  }

  /// Carregar definições
  static Future<DefinicaoModel> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyDefinicoes);

      if (json == null) {
        // Retornar definições padrão e salvá-las
        final defPadrao = DefinicaoModel();
        await salvar(defPadrao);
        return defPadrao;
      }

      final Map<String, dynamic> data = jsonDecode(json);
      final definicoes = DefinicaoModel.fromJson(data);

      // Migração: Se algum campo novo não existir no JSON, salvar novamente com todos os campos
      if (!data.containsKey('timeoutAtivo') ||
          !data.containsKey('timeoutSegundos') ||
          !data.containsKey('mostrarBotaoPedidos') ||
          !data.containsKey('mostrarStockEmVendas')) {
        print('Migrando definições para incluir novos campos...');
        await salvar(definicoes);
      }

      return definicoes;
    } catch (e) {
      print('Erro ao carregar definições: $e');
      // Retornar definições padrão em caso de erro
      return DefinicaoModel();
    }
  }

  /// Atualizar apenas a opção de perguntar antes de imprimir
  static Future<void> setPerguntarAntesDeImprimir(bool valor) async {
    try {
      final definicoes = await carregar();
      final novasDefinicoes = definicoes.copyWith(
        perguntarAntesDeImprimir: valor,
      );
      await salvar(novasDefinicoes);
    } catch (e) {
      print('Erro ao atualizar definição de impressão: $e');
      rethrow;
    }
  }

  /// Limpar todas as definições (resetar para padrão)
  static Future<void> limpar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDefinicoes);
    } catch (e) {
      print('Erro ao limpar definições: $e');
      rethrow;
    }
  }
}
