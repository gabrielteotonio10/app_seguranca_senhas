import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/cofre_store.dart';
import '../../dominio/seguranca.dart';
import '../componentes/indicador_forca.dart';
import '../componentes/largura_maxima.dart';

/// Formulário para guardar uma nova conta no cofre.
class TelaNovaCredencial extends StatefulWidget {
  const TelaNovaCredencial({super.key});

  @override
  State<TelaNovaCredencial> createState() => _TelaNovaCredencialState();
}

class _TelaNovaCredencialState extends State<TelaNovaCredencial> {
  final _chave = GlobalKey<FormState>();
  final _servico = TextEditingController();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  bool _mostrarSenha = false;
  bool _salvando = false;

  @override
  void dispose() {
    _servico.dispose();
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _gerarSenha() {
    setState(() {
      _senha.text = gerarSenhaForte();
      _mostrarSenha = true;
    });
  }

  Future<void> _salvar() async {
    if (!_chave.currentState!.validate()) return;
    setState(() => _salvando = true);
    await context.read<CofreStore>().adicionar(
          servico: _servico.text,
          usuario: _usuario.text,
          senha: _senha.text,
        );
    if (!mounted) return;
    Navigator.pop(context, true); // avisa a lista que deu certo
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nova senha')),
      body: LarguraMaxima(
        largura: 560,
        child: Form(
          key: _chave,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _servico,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Serviço',
                  hintText: 'Ex.: Gmail, banco, Netflix',
                  prefixIcon: Icon(Icons.apps),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Informe o nome do serviço (ao menos 2 letras)'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usuario,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Usuário ou e-mail',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o usuário ou o e-mail da conta'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senha,
                obscureText: !_mostrarSenha,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                    onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                    icon: Icon(_mostrarSenha ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                onChanged: (_) => setState(() {}), // atualiza a barra de força
                onFieldSubmitted: (_) => _salvar(),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Informe a senha ou toque em "Gerar senha forte"';
                  }
                  if (v.length < 6) return 'Use ao menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              IndicadorForca(senha: _senha.text),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _gerarSenha,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Gerar senha forte'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: const Icon(Icons.lock),
                label: const Text('Guardar no cofre'),
              ),
              const SizedBox(height: 16),
              Text(
                'A senha é cifrada pelo sistema (Keystore, Keychain, DPAPI ou '
                'WebCrypto) e só volta a aparecer depois do Face ID.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cores.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
