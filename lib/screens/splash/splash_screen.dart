import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoAlpha;

  late AnimationController _nameController;
  late Animation<double> _nameAlpha;
  late Animation<double> _nameY;

  late AnimationController _taglineController;
  late Animation<double> _taglineAlpha;
  late Animation<double> _taglineY;

  @override
  void initState() {
    super.initState();

    // Logo: alpha + scale (0.5 to 1.0) for 600ms
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // App name: alpha + translateY (20px to 0px) for 500ms, starts at 300ms
    _nameController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _nameAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _nameController, curve: Curves.easeIn));
    _nameY = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _nameController, curve: Curves.easeOut));

    // Tagline: alpha + translateY (10px to 0px) for 500ms, starts at 600ms
    _taglineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _taglineAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineController, curve: Curves.easeIn));
    _taglineY = Tween<double>(begin: 10.0, end: 0.0).animate(
        CurvedAnimation(parent: _taglineController, curve: Curves.easeOut));

    _runSequence();
  }

  void _runSequence() async {
    // Logo starts immediately (0ms)
    _logoController.forward();

    // App name starts at 300ms delay
    await Future.delayed(const Duration(milliseconds: 300));
    _nameController.forward();

    // Tagline starts at 600ms delay
    await Future.delayed(const Duration(milliseconds: 300));
    _taglineController.forward();

    // Navigate after 2200ms total
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
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
              Color(0xFF114C44),
              Color(0xFF249C8F),
              Color(0xFF4DD0E1),
            ],
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo: alpha + scale animation
            AnimatedBuilder(
              animation: Listenable.merge([_logoController]),
              builder: (_, __) {
                return Opacity(
                  opacity: _logoAlpha.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      'assets/images/pin.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      semanticLabel: 'Campus Navigator Pin',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // App name: alpha + translate Y
            AnimatedBuilder(
              animation: _nameController,
              builder: (_, __) {
                return Opacity(
                  opacity: _nameAlpha.value,
                  child: Transform.translate(
                    offset: Offset(0, _nameY.value),
                    child: Text(
                      'Campus Navigator',
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 5),

            // Tagline: alpha + translate Y
            AnimatedBuilder(
              animation: _taglineController,
              builder: (_, __) {
                return Opacity(
                  opacity: _taglineAlpha.value,
                  child: Transform.translate(
                    offset: Offset(0, _taglineY.value),
                    child: Text(
                      'Find your way, always!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFCFE3DE),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Bouncing dots
            const _BouncingDots(),

            const SizedBox(height: 48),

          ],
        ),
      ),
    );
  }
}

// ── Bouncing dots (3 dots, staggered animation) ────────
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

    // Stagger the animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }

    _animations = _controllers
        .map((controller) => Tween<double>(begin: 0, end: -8).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _animations[index].value),
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
