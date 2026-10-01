class TreinoModel {
  // Opções que aparecem na lista de tipo de treino
  static const List<String> tipos = [
    'Corrida',
    'Bicicleta estática',
    'Bicicleta',
    'Natação',
    'Esportes gerais',
    'Treino de membros superiores',
    'Treino de membros inferiores',
    'Outros',
  ];

  final String? id;
  final DateTime data;
  final String tipo;
  final String? tipoPersonalizado;
  final bool temPersonalTrainer;
  final String? nomePersonalTrainer;
  final int duracaoMinutos;
  final String? fotoUrl;

  TreinoModel({
    this.id,
    required this.data,
    required this.tipo,
    this.tipoPersonalizado,
    required this.temPersonalTrainer,
    this.nomePersonalTrainer,
    required this.duracaoMinutos,
    this.fotoUrl,
  });

  // Quando o tipo é "Outros", mostra o texto que o usuário digitou
  String get tipoExibicao {
    final personalizado = tipoPersonalizado?.trim() ?? '';
    if (tipo == 'Outros' && personalizado.isNotEmpty) {
      return personalizado;
    }
    return tipo;
  }

  String get dataFormatada => formatarData(data);

  // Formata a data no padrão dd/MM/aaaa
  static String formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  // Data no formato enviado para a API: AAAA-MM-DD (ex.: 2026-09-29)
  static String dataParaApi(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }

  // Lê a data vinda da API. Aceita "2026-09-29", data com hora
  // ou número (segundos), que é como o MockAPI guarda campos do tipo Date
  static DateTime _lerData(dynamic valor) {
    if (valor is String) {
      final data = DateTime.tryParse(valor.trim());
      if (data != null) {
        final local = data.isUtc ? data.toLocal() : data;
        return DateTime(local.year, local.month, local.day);
      }
    }
    if (valor is num) {
      final local = DateTime.fromMillisecondsSinceEpoch((valor * 1000).toInt());
      return DateTime(local.year, local.month, local.day);
    }
    return DateTime.now();
  }

  // Converter para JSON (enviar para a API)
  Map<String, dynamic> toMap() {
    return {
      'data': dataParaApi(data),
      'tipo': tipo,
      'tipoPersonalizado': tipoPersonalizado,
      'temPersonalTrainer': temPersonalTrainer,
      'nomePersonalTrainer': nomePersonalTrainer,
      'duracaoMinutos': duracaoMinutos,
      'fotoUrl': fotoUrl, // apenas o link (String) da imagem na internet
    };
  }

  // Criar o objeto a partir do JSON da API (Ler / Listar)
  factory TreinoModel.fromMap(Map<String, dynamic> map) {
    final personal = map['temPersonalTrainer'];
    final duracao = map['duracaoMinutos'];

    return TreinoModel(
      id: map['id']?.toString(),
      data: _lerData(map['data']),
      tipo: map['tipo'] as String? ?? 'Outros',
      tipoPersonalizado: map['tipoPersonalizado'] as String?,
      temPersonalTrainer: personal == true || personal == 'true',
      nomePersonalTrainer: map['nomePersonalTrainer'] as String?,
      duracaoMinutos: duracao is num
          ? duracao.toInt()
          : int.tryParse('${duracao ?? ''}') ?? 0,
      fotoUrl: map['fotoUrl'] as String?,
    );
  }
}
