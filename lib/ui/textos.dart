import '../dados/biometria/biometria_servico.dart';

/// Textos e formatações usados por várias telas.

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String formatarData(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';

String formatarDataHora(DateTime d) =>
    '${formatarData(d)} às ${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

/// 52256179 -> "52.256.179"
String formatarNumero(int n) => n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

/// Mensagem de erro é instrução: diz o que fazer (Aula 05).
String mensagemBiometria(StatusBiometria status, String nomeBiometria) =>
    switch (status) {
      StatusBiometria.sucesso => 'Identidade confirmada',
      StatusBiometria.falhou => nomeBiometria == 'Face ID'
          ? 'Rosto não reconhecido. Toque para tentar de novo.'
          : 'Não reconhecido. Toque para tentar de novo.',
      StatusBiometria.cancelado => 'Verificação cancelada. Toque para tentar de novo.',
      StatusBiometria.indisponivel => 'Biometria indisponível neste aparelho. Use o PIN.',
      StatusBiometria.bloqueado =>
        'O sistema bloqueou a biometria após muitas tentativas. Use o PIN.',
    };
