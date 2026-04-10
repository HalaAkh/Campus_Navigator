import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const OnboardingScreen({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  final _slides = [
    _OnboardingSlide(
      icon: Icons.location_on_outlined,
      color: Color(0xFF007A6E),
      title: 'Find Any Room Instantly',
      body:
          'Bluetooth beacons inside Nicol Hall pinpoint your exact location — no GPS needed.',
    ),
    _OnboardingSlide(
      icon: Icons.route_outlined,
      color: Color(0xFF00BCD4),
      title: 'AI-Powered Turn-by-Turn',
      body:
          'Smart AI guides you step by step through every corridor, junction, and stairway across Floors 4 and 5.',
    ),
    _OnboardingSlide(
      icon: Icons.group_outlined,
      color: Color(0xFF2E7D32),
      title: 'Built for LAU Community',
      body:
          'Sign in with your @lau.edu.lb email. Exclusively for LAU students, faculty, and staff.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    _slideAnim = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() async {
    if (_page < 2) {
      _animController.reset();
      setState(() => _page++);
      _animController.forward();
    } else {
      widget.onGetStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 12,
              right: 20,
              child: TextButton(
                onPressed: widget.onLogin,
                child: Text(
                  'Skip',
                  style: AppTextStyles.bodyMedium(14,
                      color: AppColors.mutedForeground),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 60),

                // Illustration area
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (_, __) => Opacity(
                      opacity: _fadeAnim.value,
                      child: Transform.translate(
                        offset: Offset(_slideAnim.value, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon illustration
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: slide.color.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 72,
                                  color: slide.color,
                                ),
                              ),
                              const SizedBox(height: 40),

                              Text(
                                slide.title,
                                style: AppTextStyles.headingBold(26),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              Text(
                                slide.body,
                                style: AppTextStyles.bodyRegular(15,
                                    color: AppColors.mutedForeground),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Progress dots + buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? AppColors.accent
                                  : AppColors.muted,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      if (_page < 2) ...[
                        GradientButton(label: 'Next →', onPressed: _next),
                      ] else ...[
                        AccentButton(
                          label: 'Get Started',
                          onPressed: widget.onGetStarted,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: widget.onLogin,
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: AppTextStyles.bodyRegular(14,
                                  color: AppColors.mutedForeground),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: AppTextStyles.bodySemiBold(14,
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
