import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model/treino_model.dart';
import 'services/treino_service.dart';
import 'treinos_screen.dart';

class TreinoFormScreen extends StatefulWidget {
  // null = cadastro novo; preenchido = edição
  final TreinoModel? treino;

  const TreinoFormScreen({super.key, this.treino});

  @override
  State<TreinoFormScreen> createState() => _TreinoFormScreenState();
}

class _TreinoFormScreenState extends State<TreinoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TreinoService _treinoService = TreinoService();

  final _dataController = TextEditingController();
  final _tipoPersonalizadoController = TextEditingController();
  final _nomePersonalController = TextEditingController();
  final _duracaoController = TextEditingController();
  final _fotoUrlController = TextEditingController();

  late DateTime _data;
  String? _tipo;
  bool _temPersonal = false;
  String? _urlPrevia;
  bool _salvando = false;

  bool get _editando => widget.treino != null;

  @override
  void initState() {
    super.initState();

    final treino = widget.treino;
    final hoje = DateTime.now();

    _data = treino?.data ?? DateTime(hoje.year, hoje.month, hoje.day);
    _dataController.text = TreinoModel.formatarData(_data);

    if (treino != null) {
      _tipo = treino.tipo;
      _tipoPersonalizadoController.text = treino.tipoPersonalizado ?? '';
      _temPersonal = treino.temPersonalTrainer;
      _nomePersonalController.text = treino.nomePersonalTrainer ?? '';
      _duracaoController.text = treino.duracaoMinutos.toString();
      _fotoUrlController.text = treino.fotoUrl ?? '';
      _urlPrevia = treino.fotoUrl;
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _tipoPersonalizadoController.dispose();
    _nomePersonalController.dispose();
    _duracaoController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();

    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59),
      helpText: 'Data do treino',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (escolhida == null) return;

    setState(() {
      _data = escolhida;
      _dataController.text = TreinoModel.formatarData(escolhida);
    });
  }

  // Link é opcional; se preenchido, precisa ser http/https
  String? _validarUrl(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) return null;

    final uri = Uri.tryParse(texto);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Informe um link válido (começando com http:// ou https://)';
    }

    return null;
  }

  void _atualizarPrevia() {
    final url = _fotoUrlController.text.trim();
    final erro = _validarUrl(url);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _urlPrevia = url.isEmpty ? null : url);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);

    final fotoUrl = _fotoUrlController.text.trim();

    final treino = TreinoModel(
      id: widget.treino?.id,
      data: _data,
      tipo: _tipo!,
      tipoPersonalizado:
          _tipo == 'Outros' ? _tipoPersonalizadoController.text.trim() : null,
      temPersonalTrainer: _temPersonal,
      nomePersonalTrainer:
          _temPersonal ? _nomePersonalController.text.trim() : null,
      duracaoMinutos: int.parse(_duracaoController.text),
      fotoUrl: fotoUrl.isEmpty ? null : fotoUrl,
    );

    try {
      if (_editando) {
        await _treinoService.atualizarTreino(treino);
      } else {
        await _treinoService.criarTreino(treino);
      }

      if (!mounted) return;

      Navigator.of(context).pop(
        _editando
            ? 'Treino atualizado com sucesso!'
            : 'Treino registrado com sucesso!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir treino'),
        content: const Text('Deseja realmente excluir este treino?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _salvando = true);

    try {
      await _treinoService.excluirTreino(widget.treino!.id!);

      if (!mounted) return;

      Navigator.of(context).pop('Treino excluído.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        title: Text(
          _editando ? 'Editar Treino' : 'Novo Treino',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir treino',
              onPressed: _salvando ? null : _excluir,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Dados do Treino', Icons.fitness_center),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _dataController,
                      readOnly: true,
                      onTap: _selecionarData,
                      decoration: const InputDecoration(
                        labelText: 'Data do treino',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.edit_calendar_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de treino',
                        prefixIcon: Icon(Icons.directions_run),
                      ),
                      items: TreinoModel.tipos
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _tipo = value),
                      validator: (value) =>
                          value == null ? 'Selecione o tipo de treino' : null,
                    ),
                    if (_tipo == 'Outros') ...[
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _tipoPersonalizadoController,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          labelText: 'Qual treino?',
                          hintText: 'Descreva o tipo de treino',
                          prefixIcon: Icon(Icons.edit_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Descreva o tipo de treino';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _duracaoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Duração (minutos)',
                        hintText: 'Ex: 45',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a duração';
                        }

                        final minutos = int.tryParse(value);
                        if (minutos == null || minutos <= 0) {
                          return 'Informe uma duração válida';
                        }

                        if (minutos > 1440) {
                          return 'A duração não pode passar de 24 horas (1440 min)';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    _buildSectionTitle('Personal Trainer', Icons.person_outline),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: SwitchListTile(
                        title: const Text('Treinou com personal trainer?'),
                        value: _temPersonal,
                        onChanged: (value) =>
                            setState(() => _temPersonal = value),
                      ),
                    ),
                    if (_temPersonal) ...[
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nomePersonalController,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          labelText: 'Nome do personal trainer',
                          prefixIcon: Icon(Icons.badge_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome do personal trainer';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 25),
                    _buildSectionTitle('Foto (opcional)', Icons.image_outlined),
                    const SizedBox(height: 10),
                    Text(
                      'Cole o link de uma imagem que já esteja na internet. '
                      'O link precisa apontar direto para o arquivo da imagem.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fotoUrlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Link da foto',
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: IconButton(
                          tooltip: 'Ver prévia',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: _atualizarPrevia,
                        ),
                      ),
                      validator: _validarUrl,
                      onFieldSubmitted: (_) => _atualizarPrevia(),
                      onChanged: (value) {
                        if (value.trim().isEmpty && _urlPrevia != null) {
                          setState(() => _urlPrevia = null);
                        }
                      },
                    ),
                    if (_urlPrevia != null) ...[
                      const SizedBox(height: 15),
                      FotoTreino(
                        url: _urlPrevia,
                        largura: double.infinity,
                        altura: 200,
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _salvando ? null : _salvar,
                        icon: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _salvando
                              ? 'Salvando...'
                              : (_editando
                                  ? 'SALVAR ALTERAÇÕES'
                                  : 'REGISTRAR TREINO'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.redAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
