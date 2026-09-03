/// Valida a força de uma nova senha: mínimo de 6 caracteres, pelo menos
/// uma letra maiúscula e pelo menos um caractere especial.
/// Retorna null se a senha for válida, ou uma mensagem de erro para
/// exibir no formulário.
String? validarForcaSenha(String? value) {
  if (value == null || value.isEmpty) {
    return 'Crie uma senha';
  }

  if (value.length < 6) {
    return 'A senha deve ter ao menos 6 caracteres';
  }

  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'A senha deve ter ao menos uma letra maiúscula';
  }

  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(value)) {
    return 'A senha deve ter ao menos um caractere especial';
  }

  return null;
}