import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../dados/biometria/biometria_servico.dart';
import '../../dominio/seguranca.dart';
import '../../dominio/sessao_store.dart';
import '../componentes/scanner_face_id.dart';
import '../rotas.dart';
import '../textos.dart';

/// Primeiro uso, em duas etapas:
///   1. criar o PIN (formulário validado, Aula 05)
///   2. ativar o Face ID (ou a simulação, se o aparelho não tiver)
class TelaCriarPin extends StatefulWidget {
  const TelaCriarPin({super.key});

  @override
  State<TelaCriarPin> createState() => _TelaCriarPinState();
}

class _TelaCriarPinState extends State<TelaCriarPin> {
  final _chave = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _confirmacao = TextEditingController();

  int _etapa = 0;
  bool _ocupado = false;
  EstadoScanner _scanner = EstadoScanner.parado;
  String? _erroBiometria;

  @override
  void dispose() {
    _pin.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _salvarPin() async {
    if (!_chave.currentState!.validate()) return;
    setState(() => _ocupado = true);
    await context.read<SessaoStore>().criarPin(_pin.text);
    if (!mounted) return;
    // O PIN não fica guardado nem nos campos da tela.
    _pin.clear();
    _confirmacao.clear();
    setState(() {
      _ocupado = false;
      _etapa = 1;
    });
  }

  Future<void> _ativarBiometria({bool simulada = false}) async {
    final sessao = context.read<SessaoStore>();
    if (simulada) await sessao.definirModoDemo(true);
    setState(() {
      _ocupado = true;
      _scanner = EstadoScanner.escaneando;
      _erroBiometria = null;
    });

    final status = await sessao.ativarBiometria();
    if (!mounted) return;

    if (status == StatusBiometria.sucesso) {
      setState(() => _scanner = EstadoScanner.sucesso);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) _irParaCofre();
    } else {
      setState(() {
        _ocupado = false;
        _scanner = EstadoScanner.falha;
        _erroBiometria = mensagemBiometria(status, sessao.nomeBiometria);
      });
    }
  }

  void _irParaCofre() => Navigator.pushReplacementNamed(context, Rotas.principal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _etapa == 0 ? _formularioPin() : _etapaBiometria(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formularioPin() {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    InputDecoration campo(String rotulo) => InputDecoration(
          labelText: rotulo,
          prefixIcon: const Icon(Icons.pin_outlined),
          counterText: '',
        );

    return Form(
      key: _chave,
      child: Column(
        key: const ValueKey('pin'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline, size: 56, color: cores.primary),
          const SizedBox(height: 16),
          Text('Crie seu PIN', textAlign: TextAlign.center, style: textos.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'O PIN é a chave reserva do cofre, para quando o Face ID não '
            'estiver disponível. O app nunca guarda o PIN: guarda só um hash dele.',
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            maxLength: tamanhoPin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: campo('PIN de $tamanhoPin números'),
            validator: (v) => problemaNoPin(v ?? ''),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmacao,
            obscureText: true,
            maxLength: tamanhoPin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: campo('Repita o PIN'),
            validator: (v) => v != _pin.text ? 'Os PINs não conferem. Digite o mesmo PIN.' : null,
            onFieldSubmitted: (_) => _salvarPin(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ocupado ? null : _salvarPin,
            child: _ocupado
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _etapaBiometria() {
    final sessao = context.watch<SessaoStore>();
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final real = sessao.biometriaRealDisponivel;
    final nome = real ? sessao.nomeBiometria : 'Face ID';

    return Column(
      key: const ValueKey('biometria'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: ScannerFaceId(estado: _scanner, tamanho: 130)),
        const SizedBox(height: 24),
        Text('Ativar $nome?', textAlign: TextAlign.center, style: textos.headlineSmall),
        const SizedBox(height: 8),
        Text(
          real
              ? 'Abra o cofre e revele senhas só olhando para a tela. Seu rosto '
                  'nunca sai do aparelho: o app só recebe "confirmado" ou "negado".'
              : 'Este aparelho não tem biometria disponível. Para a apresentação, '
                  'use o Face ID simulado. Dá para desligar depois, em Ajustes.',
          textAlign: TextAlign.center,
          style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
        ),
        if (_erroBiometria != null) ...[
          const SizedBox(height: 12),
          Text(_erroBiometria!, textAlign: TextAlign.center, style: TextStyle(color: cores.error)),
        ],
        const SizedBox(height: 32),
        if (real)
          FilledButton.icon(
            onPressed: _ocupado ? null : () => _ativarBiometria(),
            icon: const Icon(Icons.face),
            label: Text('Ativar $nome'),
          )
        else
          FilledButton.icon(
            onPressed: _ocupado ? null : () => _ativarBiometria(simulada: true),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Usar Face ID simulado'),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _ocupado ? null : _irParaCofre,
          child: const Text('Agora não, usar só o PIN'),
        ),
      ],
    );
  }
}
