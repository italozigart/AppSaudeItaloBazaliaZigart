import 'package:flutter/services.dart';

/// Monta o texto no padrão (DDD) NNNNN-NNNN a partir de uma sequência
/// de até 11 dígitos já limpa (sem caracteres não numéricos).
String _montarMascara(String digitos) {
  final buffer = StringBuffer();

  for (int i = 0; i < digitos.length; i++) {
    if (i == 0) buffer.write('(');
    buffer.write(digitos[i]);
    if (i == 1) buffer.write(') ');
    if (i == 6) buffer.write('-');
  }

  return buffer.toString();
}

/// Aplica a máscara de telefone brasileiro (DDD) NNNNN-NNNN a uma
/// sequência de dígitos ou a um texto já parcialmente formatado.
/// Ex.: aplicarMascaraTelefone('17997461963') -> '(17) 99746-1963'
String aplicarMascaraTelefone(String valor) {
  final digits = valor.replaceAll(RegExp(r'\D'), '');
  final limitado = digits.length > 11 ? digits.substring(0, 11) : digits;
  return _montarMascara(limitado);
}

/// Formata o campo de telefone em tempo real, enquanto o usuário digita,
/// no padrão (DDD) NNNNN-NNNN — ex.: (17) 99746-1963.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitosAntigos = oldValue.text.replaceAll(RegExp(r'\D'), '');
    var novosDigitos = newValue.text.replaceAll(RegExp(r'\D'), '');

    final apagando = newValue.text.length < oldValue.text.length;

    // Se o usuário apagou só um caractere da máscara (o espaço, o "(",
    // o ")" ou o "-") sem remover nenhum dígito, a quantidade de dígitos
    // não muda — e reformatar devolveria o texto idêntico, travando o
    // apagar. Nesse caso, removemos também o último dígito, "pulando"
    // o caractere de máscara.
    if (apagando &&
        novosDigitos.length == digitosAntigos.length &&
        novosDigitos.isNotEmpty) {
      novosDigitos = novosDigitos.substring(0, novosDigitos.length - 1);
    }

    final limitado = novosDigitos.length > 11
        ? novosDigitos.substring(0, 11)
        : novosDigitos;
    final textoFormatado = _montarMascara(limitado);

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}