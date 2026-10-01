import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'imc_screen.dart';
import 'login_screen.dart';
import 'model/user_model.dart';
import 'profile_screen.dart';
import 'services/user_services.dart';
import 'treinos_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  late Stream<UserModel?> _perfilStream;

  @override
  void initState() {
    super.initState();
    _perfilStream = _userService.streamUserProfile();
  }

  Future<void> _abrirPerfil() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    if (!mounted) return;

    // Busca o perfil de novo na API para mostrar o nome atualizado
    setState(() => _perfilStream = _userService.streamUserProfile());
  }

  void _abrirImc() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImcScreen()),
    );
  }

  void _abrirTreinos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TreinosScreen()),
    );
  }

  Future<void> _deslogar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Sistema Único de Saúde - System Of Down',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Meu perfil',
            onPressed: _abrirPerfil,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _deslogar,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<UserModel?>(
                    stream: _perfilStream,
                    builder: (context, snapshot) {
                      final nome = snapshot.data?.name.trim() ?? '';
                      final primeiroNome =
                          nome.isEmpty ? '' : nome.split(' ').first;

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
                              Icons.health_and_safety_outlined,
                              size: 38,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            primeiroNome.isEmpty
                                ? 'Olá!'
                                : 'Olá, $primeiroNome!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'O que você quer fazer hoje?',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildOpcao(
                    icon: Icons.calculate_outlined,
                    titulo: 'Calcular IMC',
                    descricao: 'Descubra seu índice de massa corporal',
                    onTap: _abrirImc,
                  ),
                  const SizedBox(height: 16),
                  _buildOpcao(
                    icon: Icons.fitness_center,
                    titulo: 'Registrar Treino',
                    descricao: 'Cadastre e acompanhe seus treinos',
                    onTap: _abrirTreinos,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpcao({
    required IconData icon,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
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
}
