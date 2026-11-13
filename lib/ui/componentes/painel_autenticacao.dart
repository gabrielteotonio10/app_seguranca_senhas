import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dados/biometria/biometria_servico.dart';
import '../../dominio/sessao_store.dart';
import '../textos.dart';
import 'entrada_pin.dart';
import 'scanner_face_id.dart';

/// O coração do app: pede o Face ID e, se não der, oferece o PIN.
///
/// Usado na tela de bloqueio (para abrir o cofre) e na folha de
/// confirmação (para revelar, copiar ou excluir uma senha).
class PainelAutenticacao extends StatefulWidget {
  const PainelAutenticacao({
    super.key,
    required this.motivo,
    required this.aoConfirmar,
    this.tamanhoScanner = 150,
    this.acaoBiometrica,
    this.permitirPin = true,
  });

  final String motivo;
  final VoidCallback aoConfirmar;
  final double tamanhoScanner;

  /// O que rodar ao escanear. Padrão: SessaoStore.autenticarBiometria.
  /// Ao ativar a biometria em Ajustes, passa SessaoStore.ativarBiometria.
  final Future<StatusBiometria> Function()? acaoBiometrica;

  /// false = só biometria (usado para provar que o sensor funciona).
  final bool permitirPin;

  @override
  State<PainelAutenticacao> createState() => _PainelAutenticacaoState();
}

class _PainelAutenticacaoState extends State<PainelAutenticacao> {
  late bool _usandoPin;
  EstadoScanner _estado = EstadoScanner.parado;
  String _mensagem = '';

  @override
  void initState() {
    super.initState();
    final sessao = context.read<SessaoStore>();
    _usandoPin = widget.permitirPin && !sessao.usarBiometria;
    _mensagem = 'Toque para usar o ${sessao.nomeBiometria}';
    // Já começa escaneando, como no iPhone. Espera o primeiro quadro.
    if (!_usandoPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _escanear());
    }
  }

  Future<void> _escanear() async {
    if (!mounted || _estado == EstadoScanner.escaneando) return;
    final sessao = context.read<SessaoStore>();
    setState(() {
      _estado = EstadoScanner.escaneando;
      _mensagem = sessao.modoDemo
          ? 'Escaneando rosto…'
          : 'Siga as instruções do sistema para confirmar';
    });

    final acao = widget.acaoBiometrica ?? () => sessao.autenticarBiometria(widget.motivo);
    final status = await acao();
    if (!mounted) return;

    if (status == StatusBiometria.sucesso) {
      setState(() {
        _estado = EstadoScanner.sucesso;
        _mensagem = 'Identidade confirmada';
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) widget.aoConfirmar();
      return;
    }

    setState(() {
      _estado = status == StatusBiometria.cancelado ? EstadoScanner.parado : EstadoScanner.falha;
      _mensagem = mensagemBiometria(status, sessao.nomeBiometria);
      // Sem biometria possível, vai direto para o PIN.
      if (widget.permitirPin &&
          (status == StatusBiometria.indisponivel || status == StatusBiometria.bloqueado)) {
        _usandoPin = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoStore>();
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    if (_usandoPin) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EntradaPin(motivo: widget.motivo, aoAcertar: widget.aoConfirmar),
          if (sessao.usarBiometria)
            TextButton.icon(
              onPressed: () {
                setState(() => _usandoPin = false);
                _escanear();
              },
              icon: const Icon(Icons.face_outlined),
              label: Text('Usar ${sessao.nomeBiometria}'),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Tocar para escanear',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _estado == EstadoScanner.escaneando ? null : _escanear,
            child: ScannerFaceId(estado: _estado, tamanho: widget.tamanhoScanner),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: Text(
            _mensagem,
            textAlign: TextAlign.center,
            style: textos.bodyLarge?.copyWith(
              color: _estado == EstadoScanner.falha ? cores.error : cores.onSurfaceVariant,
            ),
          ),
        ),
        if (widget.permitirPin) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _estado == EstadoScanner.sucesso
                ? null
                : () => setState(() => _usandoPin = true),
            icon: const Icon(Icons.dialpad),
            label: const Text('Usar PIN'),
          ),
        ],
      ],
    );
  }
}
