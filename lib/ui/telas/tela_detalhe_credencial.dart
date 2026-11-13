import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../dominio/cofre_store.dart';
import '../../dominio/credencial.dart';
import '../../dominio/sessao_store.dart';
import '../componentes/confirmar_identidade.dart';
import '../componentes/largura_maxima.dart';
import '../textos.dart';

enum _Verificacao { parado, carregando, segura, vazada, erro }

/// Detalhe de uma conta. A senha começa escondida e só aparece depois do
/// Face ID (ou PIN). Ela some sozinha depois de alguns segundos.
class TelaDetalheCredencial extends StatefulWidget {
  const TelaDetalheCredencial({super.key, required this.credencial});

  final Credencial credencial; // chega de fora, e não muda

  @override
  State<TelaDetalheCredencial> createState() => _TelaDetalheCredencialState();
}

class _TelaDetalheCredencialState extends State<TelaDetalheCredencial> {
  static const _tempoVisivel = 20; // segundos
  static const _tempoAreaTransferencia = Duration(seconds: 30);

  String? _senha; // só existe enquanto está revelada
  int _segundosRestantes = 0;
  Timer? _relogio;

  _Verificacao _verificacao = _Verificacao.parado;
  int _vezesVazada = 0;

  Credencial get _c => widget.credencial;

  @override
  void dispose() {
    _relogio?.cancel();
    _senha = null;
    super.dispose();
  }

  /// Lê a senha do armazenamento cifrado, mas só depois da biometria.
  Future<String?> _lerComConfirmacao(String motivo) async {
    if (_senha != null) return _senha; // acabou de confirmar
    final confirmado = await confirmarIdentidade(context, motivo: motivo);
    if (!confirmado || !mounted) return null;
    return context.read<CofreStore>().lerSenha(_c.id);
  }

  Future<void> _revelar() async {
    final senha = await _lerComConfirmacao('Revelar a senha de ${_c.servico}');
    if (senha == null || !mounted) return;
    setState(() {
      _senha = senha;
      _segundosRestantes = _tempoVisivel;
    });
    _relogio?.cancel();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _segundosRestantes--);
      if (_segundosRestantes <= 0) _esconder();
    });
  }

  void _esconder() {
    _relogio?.cancel();
    setState(() {
      _senha = null;
      _segundosRestantes = 0;
    });
  }

  Future<void> _copiarSenha() async {
    final senha = await _lerComConfirmacao('Copiar a senha de ${_c.servico}');
    if (senha == null || !mounted) return;
    await Clipboard.setData(ClipboardData(text: senha));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Senha copiada. A área de transferência será limpa em '
          '${_tempoAreaTransferencia.inSeconds} s.',
        ),
      ),
    );
    // Outros apps podem ler a área de transferência: limpamos depois.
    Future<void>.delayed(_tempoAreaTransferencia, () async {
      try {
        final atual = await Clipboard.getData(Clipboard.kTextPlain);
        if (atual?.text == senha) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {
        // Sem permissão para ler (ex.: navegador): deixa como está.
      }
    });
  }

  Future<void> _copiarUsuario() async {
    await Clipboard.setData(ClipboardData(text: _c.usuario));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário copiado')),
    );
  }

  Future<void> _verificarVazamento() async {
    final cofre = context.read<CofreStore>();
    if (_senha == null) {
      final ok = await confirmarIdentidade(
        context,
        motivo: 'Verificar se a senha de ${_c.servico} vazou',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _verificacao = _Verificacao.carregando);
    try {
      final vezes = await cofre.verificarVazamento(_c.id);
      if (!mounted) return;
      setState(() {
        _vezesVazada = vezes;
        _verificacao = vezes > 0 ? _Verificacao.vazada : _Verificacao.segura;
      });
    } catch (_) {
      if (mounted) setState(() => _verificacao = _Verificacao.erro);
    }
  }

  Future<void> _excluir() async {
    final cofre = context.read<CofreStore>();
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    final querExcluir = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Excluir ${_c.servico}?'),
        content: const Text('A senha será apagada do cofre. Não dá para desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (querExcluir != true || !mounted) return;
    final confirmado = await confirmarIdentidade(context, motivo: 'Excluir a senha de ${_c.servico}');
    if (!confirmado) return;

    await cofre.remover(_c.id); // a loja muda a lista, não o botão
    navegador.pop();
    mensageiro.showSnackBar(SnackBar(content: Text('${_c.servico} excluído do cofre')));
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_c.servico),
        actions: [
          IconButton(
            tooltip: 'Excluir',
            onPressed: _excluir,
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LarguraMaxima(
        largura: 560,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Cabecalho(credencial: _c),
            const SizedBox(height: 44),
            Text(_c.servico, style: textos.headlineSmall),
            Text(
              'Guardada em ${formatarData(_c.criadaEm)}',
              style: textos.bodySmall?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Usuário'),
                subtitle: Text(_c.usuario),
                trailing: IconButton(
                  tooltip: 'Copiar usuário',
                  onPressed: _copiarUsuario,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _cartaoSenha(context),
            const SizedBox(height: 12),
            _cartaoVazamento(context),
          ],
        ),
      ),
    );
  }

  Widget _cartaoSenha(BuildContext context) {
    final sessao = context.watch<SessaoStore>();
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final revelada = _senha != null;
    final metodo = sessao.usarBiometria ? sessao.nomeBiometria : 'PIN';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key_outlined),
                const SizedBox(width: 12),
                Text('Senha', style: textos.titleSmall),
                const Spacer(),
                if (revelada)
                  Text(
                    'Oculta em $_segundosRestantes s',
                    style: textos.labelMedium?.copyWith(color: cores.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: revelada
                  ? SelectableText(
                      _senha!,
                      key: const ValueKey('visivel'),
                      style: textos.titleLarge?.copyWith(fontFamily: 'monospace'),
                    )
                  : Text(
                      '•' * 12,
                      key: const ValueKey('oculta'),
                      style: textos.titleLarge?.copyWith(letterSpacing: 3),
                    ),
            ),
            if (revelada) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _segundosRestantes / _tempoVisivel),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: revelada ? _esconder : _revelar,
                    icon: Icon(revelada ? Icons.visibility_off : Icons.face),
                    label: Text(revelada ? 'Ocultar' : 'Revelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copiarSenha,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar'),
                  ),
                ),
              ],
            ),
            if (!revelada) ...[
              const SizedBox(height: 8),
              Text(
                'Exige $metodo a cada acesso',
                style: textos.bodySmall?.copyWith(color: cores.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Os quatro estados de uma tela que busca na rede (Aula 10).
  Widget _cartaoVazamento(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final conteudo = switch (_verificacao) {
      _Verificacao.parado => Text(
          'Confira se esta senha já apareceu em vazamentos públicos. Só os 5 '
          'primeiros caracteres do hash dela saem do aparelho (anonimato-k).',
          style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
        ),
      _Verificacao.carregando => const Row(
          children: [
            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Consultando Have I Been Pwned…'),
          ],
        ),
      _Verificacao.segura => _Linha(
          icone: Icons.check_circle,
          cor: cores.primary,
          texto: 'Nenhum vazamento conhecido para esta senha.',
        ),
      _Verificacao.vazada => _Linha(
          icone: Icons.warning_amber_rounded,
          cor: cores.error,
          texto: 'Esta senha apareceu ${formatarNumero(_vezesVazada)} vezes em '
              'vazamentos. Troque-a o quanto antes.',
        ),
      _Verificacao.erro => _Linha(
          icone: Icons.wifi_off,
          cor: cores.error,
          texto: 'Não foi possível consultar. Verifique a internet e tente de novo.',
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.policy_outlined),
                const SizedBox(width: 12),
                Text('Vazamentos de dados', style: textos.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.only(right: 8), child: conteudo),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _verificacao == _Verificacao.carregando ? null : _verificarVazamento,
                child: Text(
                  _verificacao == _Verificacao.parado ? 'Verificar agora' : 'Verificar de novo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.cor, required this.texto});

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: cor))),
        ],
      );
}

/// Faixa colorida com o avatar sobreposto (Stack + Positioned, Aula 04).
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.credencial});

  final Credencial credencial;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [cores.primaryContainer, cores.tertiaryContainer],
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 20,
          child: Row(
            children: [
              Icon(Icons.lock, size: 16, color: cores.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                'Cifrada',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: cores.onPrimaryContainer),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          bottom: -32,
          child: CircleAvatar(
            radius: 34,
            backgroundColor: cores.primary,
            foregroundColor: cores.onPrimary,
            child: Text(
              credencial.inicial,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: cores.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
