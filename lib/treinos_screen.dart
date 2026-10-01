import 'package:flutter/material.dart';

import 'model/treino_model.dart';
import 'services/treino_service.dart';
import 'treino_form_screen.dart';

class TreinosScreen extends StatefulWidget {
  const TreinosScreen({super.key});

  @override
  State<TreinosScreen> createState() => _TreinosScreenState();
}

class _TreinosScreenState extends State<TreinosScreen> {
  final TreinoService _treinoService = TreinoService();
  late Future<List<TreinoModel>> _treinosFuture;

  @override
  void initState() {
    super.initState();
    _treinosFuture = _treinoService.listarTreinos();
  }

  // Busca a lista de novo na API (depois de salvar/excluir, ou ao puxar a tela)
  Future<void> _recarregar() async {
    final futuro = _treinoService.listarTreinos();
    setState(() => _treinosFuture = futuro);

    try {
      await futuro;
    } catch (_) {
      // o erro já aparece na tela pelo FutureBuilder
    }
  }

  // Sem parâmetro = cadastro novo; com treino = edição
  Future<void> _abrirFormulario([TreinoModel? treino]) async {
    final mensagem = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => TreinoFormScreen(treino: treino)),
    );

    if (mensagem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.green,
        ),
      );
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Meus Treinos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar lista',
            onPressed: _recarregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo treino',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _recarregar,
          child: FutureBuilder<List<TreinoModel>>(
            future: _treinosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildMensagem(
                  icon: Icons.error_outline,
                  titulo: 'Erro ao carregar treinos',
                  descricao: '${snapshot.error}\n\nPuxe a tela para baixo para tentar de novo.',
                );
              }

              final treinos = snapshot.data ?? [];

              if (treinos.isEmpty) {
                return _buildMensagem(
                  icon: Icons.fitness_center,
                  titulo: 'Nenhum treino registrado',
                  descricao: 'Toque em "Novo treino" para cadastrar o primeiro.',
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                // espaço extra embaixo para o botão flutuante não cobrir o último card
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: treinos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: _buildCard(treinos[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(TreinoModel treino) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _abrirFormulario(treino),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FotoTreino(url: treino.fotoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treino.tipoExibicao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildInfo(
                          Icons.calendar_today_outlined,
                          treino.dataFormatada,
                        ),
                        _buildInfo(
                          Icons.timer_outlined,
                          '${treino.duracaoMinutos} min',
                        ),
                      ],
                    ),
                    if (treino.temPersonalTrainer) ...[
                      const SizedBox(height: 4),
                      _buildInfo(
                        Icons.person_outline,
                        'Personal: ${treino.nomePersonalTrainer ?? ''}',
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // Fica dentro de uma lista rolável para o "puxar para atualizar" funcionar
  Widget _buildMensagem({
    required IconData icon,
    required String titulo,
    required String descricao,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 36, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descricao,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Exibe a imagem a partir do link salvo no Firestore.
// Usado na lista e na prévia do formulário.
class FotoTreino extends StatelessWidget {
  final String? url;
  final double largura;
  final double altura;

  const FotoTreino({
    super.key,
    required this.url,
    this.largura = 72,
    this.altura = 72,
  });

  Widget _placeholder(IconData icon) {
    return Container(
      width: largura,
      height: altura,
      color: Colors.redAccent.withOpacity(0.1),
      child: Icon(icon, color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link = url?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: link.isEmpty
          ? _placeholder(Icons.fitness_center)
          : Image.network(
              link,
              width: largura,
              height: altura,
              fit: BoxFit.cover,
              // No Chrome, se o site da imagem bloquear (CORS), exibe via <img>
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              loadingBuilder: (context, child, progresso) {
                if (progresso == null) return child;
                return SizedBox(
                  width: largura,
                  height: altura,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              // Link quebrado ou que não é imagem: mostra ícone em vez de travar
              errorBuilder: (context, error, stackTrace) =>
                  _placeholder(Icons.broken_image_outlined),
            ),
    );
  }
}
