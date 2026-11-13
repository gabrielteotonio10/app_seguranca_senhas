import 'package:flutter/material.dart';

import '../componentes/largura_maxima.dart';

/// Tela de apoio para a apresentação: as camadas de proteção do app.
class TelaComoFunciona extends StatelessWidget {
  const TelaComoFunciona({super.key});

  static const _passos = [
    (
      icone: Icons.face_retouching_natural,
      titulo: 'O app nunca vê o seu rosto',
      texto: 'Quem compara o rosto é o sistema operacional, dentro de um chip '
          'isolado (Secure Enclave no iPhone, TEE no Android, TPM no Windows). '
          'O modelo do rosto nunca sai dali. O app só recebe a resposta: '
          'confirmado ou negado.',
    ),
    (
      icone: Icons.pin_outlined,
      titulo: 'O PIN não é guardado',
      texto: 'Guardamos só um hash SHA-256 do PIN, misturado com um sal '
          'aleatório e repetido 10.000 vezes. A comparação é feita em tempo '
          'constante, para o tempo de resposta não dar pistas.',
    ),
    (
      icone: Icons.block,
      titulo: 'Força bruta bloqueada',
      texto: 'Depois de 5 PINs errados, o cofre trava por 30 segundos. A '
          'contagem fica gravada: fechar o app não zera as tentativas.',
    ),
    (
      icone: Icons.enhanced_encryption_outlined,
      titulo: 'Senhas cifradas pelo sistema',
      texto: 'As senhas vão para o Keystore (Android), Keychain (iOS), DPAPI '
          '(Windows) ou WebCrypto (navegador), e não para um banco comum. '
          'Cada senha só é lida depois da biometria.',
    ),
    (
      icone: Icons.timer_outlined,
      titulo: 'Exposição mínima',
      texto: 'A senha revelada some em 20 segundos, a área de transferência '
          'é limpa em 30 segundos e o cofre tranca sozinho quando você sai do app.',
    ),
    (
      icone: Icons.policy_outlined,
      titulo: 'Vazamentos com anonimato-k',
      texto: 'Para consultar se uma senha vazou, só os 5 primeiros caracteres '
          'do hash SHA-1 dela vão para a internet. Nem o servidor sabe qual '
          'senha foi consultada.',
    ),
    (
      icone: Icons.receipt_long_outlined,
      titulo: 'Tudo fica registrado',
      texto: 'Cada tentativa de acesso, liberada ou negada, entra no histórico. '
          'Apagar o histórico também exige confirmar a identidade.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Como funciona')),
      body: LarguraMaxima(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _passos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final passo = _passos[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: cores.primaryContainer,
                      foregroundColor: cores.onPrimaryContainer,
                      child: Icon(passo.icone),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${passo.titulo}', style: textos.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            passo.texto,
                            style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
