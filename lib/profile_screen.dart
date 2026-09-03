import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'model/user_model.dart';
import 'services/user_services.dart';
import 'utils/formatters.dart';
import 'utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();

  UserModel? _usuario;

  bool _editando = false;
  bool _carregandoPerfil = true;
  bool _salvando = false;
  String? _erroCarregamento;

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;
  bool _confirmarNovaSenhaVisivel = false;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      _carregandoPerfil = true;
      _erroCarregamento = null;
    });

    try {
      final usuario = await _userService.getCurrentUserProfile();

      if (!mounted) return;

      if (usuario == null) {
        setState(() {
          _erroCarregamento = 'Não foi possível encontrar seus dados.';
        });
        return;
      }

      setState(() {
        _usuario = usuario;
        _preencherControllers(usuario);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroCarregamento = 'Erro ao carregar seus dados: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  void _preencherControllers(UserModel usuario) {
    _nomeController.text = usuario.name;
    _telefoneController.text = aplicarMascaraTelefone(usuario.phone);
    _emailController.text = usuario.email;
    _senhaAtualController.clear();
    _novaSenhaController.clear();
    _confirmarNovaSenhaController.clear();
  }

  void _iniciarEdicao() {
    setState(() => _editando = true);
  }

  void _cancelarEdicao() {
    if (_usuario != null) {
      _preencherControllers(_usuario!);
    }
    setState(() => _editando = false);
  }

  Future<void> _salvar() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);

    final novoNome = _nomeController.text.trim();
    final novoTelefone = _telefoneController.text.trim();
    final novoEmail = _emailController.text.trim();
    final novaSenha = _novaSenhaController.text.trim();
    final senhaAtual = _senhaAtualController.text.trim();

    final emailMudou = _usuario != null && novoEmail != _usuario!.email;
    final senhaMudou = novaSenha.isNotEmpty;

    try {
      // Nome e telefone não exigem reautenticação: sempre são salvos primeiro.
      await _userService.updateUserProfile(
        name: novoNome,
        phone: novoTelefone,
      );

      // A partir daqui, qualquer erro é sobre e-mail/senha — nome e
      // telefone já foram salvos com sucesso no passo anterior.
      if (emailMudou) {
        await _userService.updateEmail(
          newEmail: novoEmail,
          currentPassword: senhaAtual,
        );
      }

      if (senhaMudou) {
        await _userService.updatePassword(
          newPassword: novaSenha,
          currentPassword: senhaAtual,
        );
      }

      final usuarioAtualizado = UserModel(
        id: _usuario?.id,
        name: novoNome,
        phone: novoTelefone,
        email: novoEmail,
      );

      if (!mounted) return;

      setState(() {
        _usuario = usuarioAtualizado;
        _editando = false;
      });
      _preencherControllers(usuarioAtualizado);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailMudou
                ? 'Dados salvos! Confirme o link enviado para $novoEmail para concluir a troca de e-mail.'
                : 'Dados atualizados com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String detalhe = 'Não foi possível concluir a troca de e-mail/senha.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        detalhe = 'Senha atual incorreta.';
      } else if (e.code == 'requires-recent-login') {
        detalhe = 'Por segurança, informe sua senha atual novamente.';
      } else if (e.code == 'email-already-in-use') {
        detalhe = 'Este e-mail já está em uso por outra conta.';
      } else if (e.code == 'invalid-email') {
        detalhe = 'Informe um e-mail válido.';
      } else if (e.code == 'weak-password') {
        detalhe = 'A nova senha é muito fraca.';
      }

      if (mounted) {
        setState(() {
          if (_usuario != null) {
            _usuario = UserModel(
              id: _usuario!.id,
              name: novoNome,
              phone: novoTelefone,
              email: _usuario!.email,
            );
          }
          _senhaAtualController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nome e telefone salvos. $detalhe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
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
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          if (!_carregandoPerfil && _erroCarregamento == null && !_editando)
            IconButton(
              tooltip: 'Editar perfil',
              onPressed: _iniciarEdicao,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_carregandoPerfil) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroCarregamento != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                _erroCarregamento!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _carregarPerfil,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _editando ? _buildFormEdicao() : _buildVisualizacao(),
        ),
      ),
    );
  }

  Widget _buildCabecalho(String subtitulo) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_circle_outlined,
            size: 40,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _usuario?.name ?? 'Meu Perfil',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildVisualizacao() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildCabecalho('Seus dados cadastrados'),
        const SizedBox(height: 32),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, 'Nome', _usuario!.name),
                const Divider(),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Telefone',
                  aplicarMascaraTelefone(_usuario!.phone),
                ),
                const Divider(),
                _buildInfoRow(Icons.email_outlined, 'E-mail', _usuario!.email),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormEdicao() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildCabecalho('Atualize suas informações'),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              counterText: '',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu nome';
              }
              if (value.trim().length < 3) {
                return 'Nome muito curto';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _telefoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [TelefoneInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Telefone',
              hintText: '(DDD) 9NNNN-NNNN',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu telefone';
              }
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.length != 11) {
                return 'Telefone incompleto';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Informe um e-mail válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Alterar senha (opcional)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Deixe em branco se não quiser trocar sua senha.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _novaSenhaController,
            obscureText: !_novaSenhaVisivel,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              hintText: 'Mín. 6 caracteres, 1 maiúscula e 1 especial',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _novaSenhaVisivel
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _novaSenhaVisivel = !_novaSenhaVisivel);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null; // opcional
              return validarForcaSenha(value);
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _confirmarNovaSenhaController,
            obscureText: !_confirmarNovaSenhaVisivel,
            decoration: InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmarNovaSenhaVisivel
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _confirmarNovaSenhaVisivel = !_confirmarNovaSenhaVisivel;
                  });
                },
              ),
            ),
            validator: (value) {
              if (_novaSenhaController.text.isEmpty) return null;
              if (value != _novaSenhaController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 8),
          TextFormField(
            controller: _senhaAtualController,
            obscureText: !_senhaAtualVisivel,
            decoration: InputDecoration(
              labelText: 'Senha atual',
              hintText: 'Necessária para trocar e-mail ou senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _senhaAtualVisivel
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _senhaAtualVisivel = !_senhaAtualVisivel);
                },
              ),
            ),
            validator: (value) {
              final emailMudou = _usuario != null &&
                  _emailController.text.trim() != _usuario!.email;
              final senhaMudou = _novaSenhaController.text.isNotEmpty;

              if ((emailMudou || senhaMudou) &&
                  (value == null || value.isEmpty)) {
                return 'Informe sua senha atual para confirmar';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _salvando ? null : _cancelarEdicao,
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _salvando ? 'Salvando...' : 'SALVAR',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}