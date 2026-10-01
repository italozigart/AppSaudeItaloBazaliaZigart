import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/treino_model.dart';

/// Erro da API de treinos, com mensagem em português
class TreinoApiException implements Exception {
  final String mensagem;
  TreinoApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// CRUD de treinos pela API REST do MockAPI (igual ao Bibleosity).
///   GET    /treinos      -> listar
///   GET    /treinos/:id  -> buscar
///   POST   /treinos      -> cadastrar
///   PUT    /treinos/:id  -> atualizar
///   DELETE /treinos/:id  -> excluir
class TreinoService {
  // Cole aqui a URL do recurso "treinos" do seu projeto no MockAPI
     static const String baseUrl = 'https://6abee53ac4d5ac548302cba0.mockapi.io/treinos';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Uri _url([String? id]) => Uri.parse(id == null ? baseUrl : '$baseUrl/$id');

  // READ: lista todos, do mais recente para o mais antigo
  Future<List<TreinoModel>> listarTreinos() async {
    final resposta = await _executar(() => http.get(_url()));

    // O MockAPI responde 404 quando o recurso ainda não tem registros
    if (resposta.statusCode == 404) return [];
    _verificar(resposta, 'listar os treinos');

    final lista = _lerJson(resposta) as List<dynamic>;
    final treinos = lista
        .map((item) => TreinoModel.fromMap(item as Map<String, dynamic>))
        .toList();

    treinos.sort((a, b) => b.data.compareTo(a.data));
    return treinos;
  }

  // READ: busca um treino pelo id (null se não existir)
  Future<TreinoModel?> buscarTreino(String id) async {
    final resposta = await _executar(() => http.get(_url(id)));
    if (resposta.statusCode == 404) return null;
    _verificar(resposta, 'buscar o treino');

    return TreinoModel.fromMap(_lerJson(resposta) as Map<String, dynamic>);
  }

  // CREATE
  Future<void> criarTreino(TreinoModel treino) async {
    final resposta = await _executar(
      () => http.post(_url(), headers: _headers, body: jsonEncode(treino.toMap())),
    );
    _verificar(resposta, 'cadastrar o treino');
  }

  // UPDATE
  Future<void> atualizarTreino(TreinoModel treino) async {
    if (treino.id == null) throw TreinoApiException('Treino sem ID');

    final resposta = await _executar(
      () => http.put(_url(treino.id), headers: _headers, body: jsonEncode(treino.toMap())),
    );
    _verificar(resposta, 'atualizar o treino');
  }

  // DELETE
  Future<void> excluirTreino(String id) async {
    final resposta = await _executar(() => http.delete(_url(id)));
    _verificar(resposta, 'excluir o treino');
  }

  // ---------------------------------------------------------------------------

  Future<http.Response> _executar(Future<http.Response> Function() chamada) async {
    try {
      return await chamada().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw TreinoApiException(
        'Não foi possível conectar à API de treinos. Verifique a internet.',
      );
    }
  }

  void _verificar(http.Response resposta, String acao) {
    if (resposta.statusCode == 404) {
      throw TreinoApiException('Treino não encontrado.');
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw TreinoApiException(
        'Não foi possível $acao (erro ${resposta.statusCode}).',
      );
    }
  }

  dynamic _lerJson(http.Response resposta) {
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }
}
