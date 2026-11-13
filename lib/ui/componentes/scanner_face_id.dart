import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

enum EstadoScanner { parado, escaneando, sucesso, falha }

/// O desenho animado do reconhecimento facial:
///   parado     -> moldura e rosto em cinza
///   escaneando -> linha de varredura subindo e descendo
///   sucesso    -> o rosto vira um "check"
///   falha      -> o desenho treme e fica vermelho
///
/// É só a parte visual. Quem decide se o rosto confere é o sistema
/// (ou a simulação, no modo demonstração).
class ScannerFaceId extends StatefulWidget {
  const ScannerFaceId({super.key, required this.estado, this.tamanho = 150});

  final EstadoScanner estado;
  final double tamanho;

  @override
  State<ScannerFaceId> createState() => _ScannerFaceIdState();
}

class _ScannerFaceIdState extends State<ScannerFaceId> with TickerProviderStateMixin {
  late final AnimationController _varredura;
  late final AnimationController _tremor;
  late final AnimationController _confirmacao;

  @override
  void initState() {
    super.initState();
    _varredura = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    _tremor = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _confirmacao = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _aplicar(widget.estado);
  }

  @override
  void didUpdateWidget(covariant ScannerFaceId antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.estado != widget.estado) _aplicar(widget.estado);
  }

  void _aplicar(EstadoScanner estado) {
    if (estado == EstadoScanner.escaneando) {
      _varredura.repeat(reverse: true);
    } else {
      _varredura.stop();
    }
    if (estado == EstadoScanner.sucesso) {
      _confirmacao.forward(from: 0);
    } else {
      _confirmacao.value = 0;
    }
    if (estado == EstadoScanner.falha) _tremor.forward(from: 0);
  }

  @override
  void dispose() {
    _varredura.dispose();
    _tremor.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final cor = switch (widget.estado) {
      EstadoScanner.parado => cores.onSurfaceVariant,
      EstadoScanner.escaneando || EstadoScanner.sucesso => cores.primary,
      EstadoScanner.falha => cores.error,
    };
    final rotulo = switch (widget.estado) {
      EstadoScanner.parado => 'Reconhecimento facial pronto',
      EstadoScanner.escaneando => 'Escaneando rosto',
      EstadoScanner.sucesso => 'Rosto reconhecido',
      EstadoScanner.falha => 'Rosto não reconhecido',
    };

    return Semantics(
      label: rotulo,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: cor),
        duration: const Duration(milliseconds: 250),
        builder: (context, corAtual, _) => AnimatedBuilder(
          animation: Listenable.merge([_varredura, _tremor, _confirmacao]),
          builder: (context, _) {
            final t = _tremor.value;
            final deslocamento = sin(t * pi * 6) * 14 * (1 - t);
            final c = corAtual ?? cor;
            return Transform.translate(
              offset: Offset(deslocamento, 0),
              child: Container(
                padding: EdgeInsets.all(widget.tamanho * 0.16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.withValues(alpha: 0.08),
                ),
                child: CustomPaint(
                  size: Size.square(widget.tamanho),
                  painter: _PintorFaceId(
                    cor: c,
                    escaneando: widget.estado == EstadoScanner.escaneando,
                    varredura: _varredura.value,
                    confirmacao: _confirmacao.value,
                    triste: widget.estado == EstadoScanner.falha,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PintorFaceId extends CustomPainter {
  _PintorFaceId({
    required this.cor,
    required this.escaneando,
    required this.varredura,
    required this.confirmacao,
    required this.triste,
  });

  final Color cor;
  final bool escaneando;
  final double varredura; // 0..1, posição da linha
  final double confirmacao; // 0..1, quanto do "check" já foi desenhado
  final bool triste;

  Paint _caneta(double espessura, [double opacidade = 1]) => Paint()
    ..color = cor.withValues(alpha: opacidade)
    ..style = PaintingStyle.stroke
    ..strokeWidth = espessura
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final traco = s * 0.045;

    // 1. A moldura: quatro cantos arredondados que "respiram" ao escanear.
    final respiro = escaneando ? sin(varredura * pi) * s * 0.025 : 0.0;
    final m = traco / 2 + respiro;
    _cantos(canvas, Rect.fromLTRB(m, m, s - m, s - m), s * 0.22, s * 0.13, _caneta(traco));

    // 2. A linha de varredura, com um brilho em volta.
    if (escaneando) {
      final y = lerpDouble(s * 0.18, s * 0.82, Curves.easeInOut.transform(varredura))!;
      final faixa = Rect.fromLTRB(s * 0.12, y - s * 0.09, s * 0.88, y + s * 0.09);
      canvas.drawRect(
        faixa,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cor.withValues(alpha: 0),
              cor.withValues(alpha: 0.22),
              cor.withValues(alpha: 0),
            ],
          ).createShader(faixa),
      );
      canvas.drawLine(Offset(s * 0.12, y), Offset(s * 0.88, y), _caneta(s * 0.014));
    }

    // 3. O rosto, que some enquanto o "check" aparece.
    final opacidadeRosto = 1 - confirmacao;
    if (opacidadeRosto > 0) {
      final p = _caneta(traco, opacidadeRosto);
      canvas.drawLine(Offset(s * .36, s * .36), Offset(s * .36, s * .45), p); // olho esq.
      canvas.drawLine(Offset(s * .64, s * .36), Offset(s * .64, s * .45), p); // olho dir.
      canvas.drawPath(
        Path()
          ..moveTo(s * .5, s * .37)
          ..lineTo(s * .5, s * .55)
          ..quadraticBezierTo(s * .5, s * .585, s * .455, s * .585),
        p,
      ); // nariz
      if (triste) {
        canvas.drawLine(Offset(s * .39, s * .69), Offset(s * .61, s * .69), p);
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(s * .36, s * .66)
            ..quadraticBezierTo(s * .5, s * .77, s * .64, s * .66),
          p,
        ); // sorriso
      }
    }

    // 4. O "check" de liberado, desenhado aos poucos.
    if (confirmacao > 0) {
      final check = Path()
        ..moveTo(s * .3, s * .52)
        ..lineTo(s * .44, s * .66)
        ..lineTo(s * .71, s * .37);
      final metrica = check.computeMetrics().first;
      final parcial = metrica.extractPath(
        0,
        metrica.length * Curves.easeOut.transform(confirmacao),
      );
      canvas.drawPath(parcial, _caneta(traco * 1.3));
    }
  }

  void _cantos(Canvas canvas, Rect r, double perna, double raio, Paint p) {
    final curva = Radius.circular(raio);
    final caminho = Path()
      ..moveTo(r.left, r.top + perna)
      ..lineTo(r.left, r.top + raio)
      ..arcToPoint(Offset(r.left + raio, r.top), radius: curva)
      ..lineTo(r.left + perna, r.top)
      ..moveTo(r.right - perna, r.top)
      ..lineTo(r.right - raio, r.top)
      ..arcToPoint(Offset(r.right, r.top + raio), radius: curva)
      ..lineTo(r.right, r.top + perna)
      ..moveTo(r.right, r.bottom - perna)
      ..lineTo(r.right, r.bottom - raio)
      ..arcToPoint(Offset(r.right - raio, r.bottom), radius: curva)
      ..lineTo(r.right - perna, r.bottom)
      ..moveTo(r.left + perna, r.bottom)
      ..lineTo(r.left + raio, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - raio), radius: curva)
      ..lineTo(r.left, r.bottom - perna);
    canvas.drawPath(caminho, p);
  }

  @override
  bool shouldRepaint(_PintorFaceId antigo) =>
      antigo.cor != cor ||
      antigo.escaneando != escaneando ||
      antigo.varredura != varredura ||
      antigo.confirmacao != confirmacao ||
      antigo.triste != triste;
}
