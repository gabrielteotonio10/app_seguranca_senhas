import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../dominio/seguranca.dart';
import '../../dominio/sessao_store.dart';

/// Bolinhas + teclado numérico para digitar o PIN.
///
/// A regra (conferir o hash, contar erros, bloquear) está na SessaoStore.
/// Este widget só coleta os dígitos e mostra o resultado. Também aceita o
/// teclado físico, útil no navegador.
class EntradaPin extends StatefulWidget {
  const EntradaPin({super.key, required this.motivo, required this.aoAcertar});

  final String motivo;
  final VoidCallback aoAcertar;

  @override
  State<EntradaPin> createState() => _EntradaPinState();
}

class _EntradaPinState extends State<EntradaPin> {
  final _foco = FocusNode();
  String _digitado = '';
  String? _erro;
  bool _verificando = false;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    _vigiarBloqueio();
    // Pede o foco depois do primeiro quadro, para o teclado físico funcionar
    // mesmo quando o foco estava no botão que acabou de sumir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _foco.dispose();
    super.dispose();
  }

  /// Enquanto o PIN estiver bloqueado, redesenha a contagem a cada segundo.
  void _vigiarBloqueio() {
    _relogio?.cancel();
    final sessao = context.read<SessaoStore>();
    if (sessao.tempoRestanteBloqueio == null) return;
    _relogio = Timer.periodic(const Duration(seconds: 1), (relogio) {
      if (!mounted) {
        relogio.cancel();
        return;
      }
      if (sessao.tempoRestanteBloqueio == null) relogio.cancel();
      setState(() {});
    });
  }

  void _digitar(String digito) {
    if (_verificando || _digitado.length >= tamanhoPin) return;
    if (context.read<SessaoStore>().tempoRestanteBloqueio != null) return;
    setState(() {
      _digitado += digito;
      _erro = null;
    });
    if (_digitado.length == tamanhoPin) _verificar();
  }

  void _apagar() {
    if (_verificando || _digitado.isEmpty) return;
    setState(() => _digitado = _digitado.substring(0, _digitado.length - 1));
  }

  Future<void> _verificar() async {
    setState(() => _verificando = true);
    // Um instante para a última bolinha aparecer antes do cálculo do hash.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final sessao = context.read<SessaoStore>();
    final resultado = await sessao.verificarPin(_digitado, motivo: widget.motivo);
    if (!mounted) return;
    setState(() {
      _verificando = false;
      _digitado = '';
      _erro = switch (resultado) {
        ResultadoPin.incorreto =>
          'PIN incorreto. Restam ${sessao.tentativasRestantes} tentativa(s) antes do bloqueio.',
        _ => null,
      };
    });
    switch (resultado) {
      case ResultadoPin.correto:
        widget.aoAcertar();
      case ResultadoPin.bloqueado:
        _vigiarBloqueio();
      case ResultadoPin.incorreto:
        HapticFeedback.heavyImpact();
    }
  }

  KeyEventResult _tecladoFisico(FocusNode no, KeyEvent evento) {
    if (evento is! KeyDownEvent) return KeyEventResult.ignored;
    final caractere = evento.character;
    if (caractere != null && RegExp(r'^\d$').hasMatch(caractere)) {
      _digitar(caractere);
      return KeyEventResult.handled;
    }
    if (evento.logicalKey == LogicalKeyboardKey.backspace) {
      _apagar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoStore>();
    final cores = Theme.of(context).colorScheme;
    final restante = sessao.tempoRestanteBloqueio;
    final bloqueado = restante != null;
    final temAviso = bloqueado || _erro != null;
    final mensagem = bloqueado
        ? 'Muitas tentativas erradas. Tente de novo em ${restante.inSeconds + 1} s.'
        : _erro ?? 'Digite seu PIN de $tamanhoPin dígitos';

    return Focus(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: _tecladoFisico,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bolinhas(preenchidas: _digitado.length, comErro: _erro != null),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: temAviso ? cores.error : cores.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          TecladoPin(
            habilitado: !bloqueado && !_verificando,
            aoDigitar: _digitar,
            aoApagar: _apagar,
          ),
        ],
      ),
    );
  }
}

class _Bolinhas extends StatelessWidget {
  const _Bolinhas({required this.preenchidas, required this.comErro});

  final int preenchidas;
  final bool comErro;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final corAtiva = comErro ? cores.error : cores.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tamanhoPin; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < preenchidas ? corAtiva : Colors.transparent,
              border: Border.all(color: comErro ? cores.error : cores.outline, width: 1.5),
            ),
          ),
      ],
    );
  }
}

class TecladoPin extends StatelessWidget {
  const TecladoPin({
    super.key,
    required this.aoDigitar,
    required this.aoApagar,
    this.habilitado = true,
  });

  final ValueChanged<String> aoDigitar;
  final VoidCallback aoApagar;
  final bool habilitado;

  static const _linhas = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '<'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final linha in _linhas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tecla in linha)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _tecla(context, tecla),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tecla(BuildContext context, String tecla) {
    const tamanho = 68.0;
    final cores = Theme.of(context).colorScheme;
    if (tecla.isEmpty) return const SizedBox.square(dimension: tamanho);
    if (tecla == '<') {
      return SizedBox.square(
        dimension: tamanho,
        child: IconButton(
          tooltip: 'Apagar',
          onPressed: habilitado ? aoApagar : null,
          icon: const Icon(Icons.backspace_outlined),
        ),
      );
    }
    return SizedBox.square(
      dimension: tamanho,
      child: Material(
        color: cores.surfaceContainerHighest,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: habilitado ? () => aoDigitar(tecla) : null,
          child: Center(
            child: Text(
              tecla,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: habilitado ? cores.onSurface : cores.onSurface.withValues(alpha: 0.38),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
