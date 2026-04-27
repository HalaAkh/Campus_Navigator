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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      icon: Icons.explore_rounded,
      color: const Color(0xFF007A6E),
      title: 'Locate Rooms',
      body: 'MOKO SMART Bluetooth Low Energy beacons pinpoint your exact location inside Nicol Hall instantly.',
    ),
    _OnboardingSlideData(
      icon: Icons.navigation_rounded,
      color: const Color(0xFF028E7F),
      title: 'Smart Navigation',
      body: 'Get precise turn-by-turn directions across Floors 4 and 5 powered by AI.',
    ),
    _OnboardingSlideData(
      icon: Icons.school_rounded,
      color: const Color(0xFF2B5C2B),
      title: 'LAU Community',
      body: 'Exclusive access for LAU students and staff using your university email.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 20,
              child: TextButton(
                onPressed: widget.onLogin,
                child: Text(
                  'Skip',
                  style: AppTextStyles.bodyMedium(14, color: AppColors.mutedForeground),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 40),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _OnboardingSlide(data: _slides[index]);
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage ? AppColors.primary : AppColors.muted,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      if (_currentPage < _slides.length - 1) ...[
                        GradientButton(
                          label: 'Next', 
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        ),
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
                              style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: AppTextStyles.bodySemiBold(14, color: AppColors.primary),
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

class _OnboardingSlideData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _OnboardingSlideData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingSlideData data;

  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: data.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: AppTextStyles.headingBold(22, color: AppColors.foreground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.body,
            style: AppTextStyles.bodyRegular(15, color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
