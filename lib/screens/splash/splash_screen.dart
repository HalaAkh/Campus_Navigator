import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late Animation<double> _entryAlpha;
  late Animation<double> _entryScale;

  late AnimationController _spinCtrl;
  late Animation<double> _spinAngle;

  late AnimationController _settleCtrl;
  late Animation<double> _settleY;
  late Animation<double> _settleScale;

  late AnimationController _nameCtrl;
  late Animation<double> _nameAlpha;
  late Animation<double> _nameY;

  late AnimationController _taglineCtrl;
  late Animation<double> _taglineAlpha;
  late Animation<double> _taglineY;

  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _spinAngle = Tween<double>(begin: 0.0, end: math.pi * 2.0).animate(
        CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOut));

    _settleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _settleY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 14.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 14.0, end: -5.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: -5.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(_settleCtrl);
    _settleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.97), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 25),
    ]).animate(_settleCtrl);

    _nameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _nameAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _nameCtrl, curve: Curves.easeIn));
    _nameY = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));

    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _taglineAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn));
    _taglineY = Tween<double>(begin: 10.0, end: 0.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    _dotControllers = List.generate(3,
            (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 600)));
    _dotAnims = _dotControllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    _runSequence();
  }

  void _runSequence() async {
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _spinCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    _settleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _nameCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _taglineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _dotControllers[i].repeat(reverse: true);
      });
    }
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _spinCtrl.dispose();
    _settleCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    for (var c in _dotControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF114C44), // Original deep teal
              Color(0xFF249C8F), // Original medium teal
              Color(0xFF4DD0E1), // Original light cyan
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_entryCtrl, _spinCtrl, _settleCtrl]),
              builder: (_, __) {
                final double alpha = _entryAlpha.value.clamp(0.0, 1.0);
                final double entryS = _entryScale.value;
                final double settleS = _settleCtrl.isAnimating || _settleCtrl.isCompleted
                    ? _settleScale.value
                    : 1.0;
                final double settleOffsetY = _settleCtrl.isAnimating || _settleCtrl.isCompleted
                    ? _settleY.value
                    : 0.0;
                final double angle = _spinAngle.value;

                return Opacity(
                  opacity: alpha,
                  child: Transform.translate(
                    offset: Offset(0, settleOffsetY),
                    child: Transform.scale(
                      scale: entryS * settleS,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateY(angle),
                        child: Image.asset(
                          'assets/images/pin.png',
                          width: 180,
                          height: 200,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          semanticLabel: 'Campus Navigator Pin',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _nameCtrl,
              builder: (_, __) => Opacity(
                opacity: _nameAlpha.value,
                child: Transform.translate(
                  offset: Offset(0, _nameY.value),
                  child: Text(
                    'CAMPUS NAVIGATOR',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w300, // Very light font weight
                      color: Colors.white,
                      letterSpacing: 3.5, // Increased spacing for a light, elegant look
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _taglineCtrl,
              builder: (_, __) => Opacity(
                opacity: _taglineAlpha.value,
                child: Transform.translate(
                  offset: Offset(0, _taglineY.value),
                  child: Text(
                    'Find your way, always!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1 ,
                      color: const Color(0xFFCFE3DE),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            const _BouncingDots(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
            (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
