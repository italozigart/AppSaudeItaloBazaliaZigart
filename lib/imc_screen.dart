import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'profile_screen.dart';

class ImcScreen extends StatefulWidget {
  const ImcScreen({super.key});

  @override
  State<ImcScreen> createState() => _ImcScreenState();
}

class _ImcScreenState extends State<ImcScreen> {
  final _formKey = GlobalKey<FormState>();

  final _alturaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _pesoController = TextEditingController();

  double? _imc;
  String? _resultado;

  @override
  void dispose() {
    _alturaController.dispose();
    _nomeController.dispose();
    _pesoController.dispose();

    super.dispose();
  }

  void calcularIMC() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double altura =
        double.parse(_alturaController.text.replaceAll(',', '.'));

    final double peso =
        double.parse(_pesoController.text.replaceAll(',', '.'));

    final double imc = peso / (altura * altura);

    setState(() {
  _imc = imc;

  if (imc < 18.5) {
    _resultado = 'Abaixo do Peso';
  } else if (imc < 25) {
    _resultado = 'Peso Normal';
  } else if (imc < 30) {
    _resultado = 'Sobrepeso';
  } else if (imc < 35) {
    _resultado = 'Obesidade Grau I';
  } else if (imc < 40) {
    _resultado = 'Obesidade Grau II';
  } else {
    _resultado = 'Obesidade Grau III';
  }
});
  }

  void limparCampos() {
    _formKey.currentState?.reset();

    _alturaController.clear();
    _nomeController.clear();
    _pesoController.clear();

    setState(() {
      _imc = null;
      _resultado = null;
    });
  }

  void _abrirPerfil() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
            tooltip: 'Limpar formulário',
            onPressed: limparCampos,
            icon: const Icon(Icons.refresh),
          ),
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
              constraints: const BoxConstraints(
                maxWidth: 650,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              size: 38,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cálculo de IMC',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Informe os dados do paciente (peso e altura) para calcular o IMC.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle(
                      'Dados do Paciente',
                      Icons.person,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _alturaController,
                      label: 'Altura (m)',
                      hint: 'Digite a altura em metros',
                      icon: Icons.height_outlined,
                    ),
                    _buildTextField(
                      controller: _pesoController,
                      label: 'Peso (kg)',
                      hint: 'Digite o peso em quilogramas',
                      icon: Icons.monitor_weight_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildSectionTitle(
                      'IMC',
                      Icons.grade_outlined,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: calcularIMC,
                        icon: const Icon(Icons.calculate),
                        label: const Text(
                          'CALCULAR IMC',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (_imc != null) _buildResultado(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.redAccent,
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Campo obrigatório';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildResultado() {
  Color cor;

  if (_resultado == 'Peso Normal') {
    cor = Colors.green;
  } else if (_resultado == 'Abaixo do Peso' ||
      _resultado == 'Sobrepeso') {
    cor = Colors.orange;
  } else {
    cor = Colors.red;
  }

  return Card(
    elevation: 4,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Resultado do IMC',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 42,
            backgroundColor: cor.withOpacity(0.12),
            child: Icon(
              Icons.monitor_weight_outlined,
              size: 50,
              color: cor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _nomeController.text.isEmpty
                ? 'Resultado'
                : _nomeController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Altura: ${_alturaController.text} m | '
            'Peso: ${_pesoController.text} kg',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(height: 30),
          const Text(
            'Seu IMC',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _imc!.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _resultado!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
    }
}