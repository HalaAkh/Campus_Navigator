import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../data/rooms.dart';

// ============================================
// FLOOR TRANSITION SCREEN
// ============================================
class FloorTransitionScreen extends StatefulWidget {
  final int fromFloor;
  final int toFloor;
  final String currentBeaconMac;
  final VoidCallback onContinueMainStairs;
  final VoidCallback onContinueBackStairs;

  const FloorTransitionScreen({
    super.key,
    required this.fromFloor,
    required this.toFloor,
    required this.currentBeaconMac,
    required this.onContinueMainStairs,
    required this.onContinueBackStairs,
  });

  @override
  State<FloorTransitionScreen> createState() => _FloorTransitionScreenState();
}

class _FloorTransitionScreenState extends State<FloorTransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Staircase illustration
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stairs_outlined, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 16),

                Text(
                  'Switch to Floor ${widget.toFloor}',
                  style: AppTextStyles.headingBold(20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your destination is on Floor ${widget.toFloor}. Choose your staircase:',
                  style: AppTextStyles.bodyRegular(13, color: AppColors.mutedForeground),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Main stairs option
                GestureDetector(
                  onTap: widget.onContinueMainStairs,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('🏃', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Main Stairs (near Elevator)',
                                  style: AppTextStyles.bodySemiBold(13)),
                              Text('Beacon C6:2A area · ~10m away',
                                  style: AppTextStyles.bodyRegular(11,
                                      color: AppColors.mutedForeground)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text('Recommended',
                              style: AppTextStyles.bodyBold(9, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Back stairs option
                GestureDetector(
                  onTap: widget.onContinueBackStairs,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('🚶', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Back Stairs (Stairs 2)',
                                  style: AppTextStyles.bodySemiBold(13)),
                              Text(
                                widget.fromFloor == 4
                                    ? 'Near Room 408 · Turn RIGHT · +20m'
                                    : 'Near Room 511 · Turn LEFT · +20m',
                                style: AppTextStyles.bodyRegular(11,
                                    color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GradientButton(
                  label: 'Continue via Main Stairs →',
                  onPressed: widget.onContinueMainStairs,
                ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: widget.onContinueBackStairs,
                  child: Text('Choose differently',
                      style: AppTextStyles.bodyMedium(13, color: AppColors.mutedForeground)),
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'F4: Back Stairs = RIGHT from Room 408\nF5: Back Stairs = LEFT from Room 511',
                    style: AppTextStyles.bodyRegular(9, color: AppColors.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// ARRIVED SCREEN
// ============================================
class ArrivedScreen extends StatefulWidget {
  final String roomNumber;
  final VoidCallback onNavigateAgain;
  final VoidCallback onHome;

  const ArrivedScreen({
    super.key,
    required this.roomNumber,
    required this.onNavigateAgain,
    required this.onHome,
  });

  @override
  State<ArrivedScreen> createState() => _ArrivedScreenState();
}

class _ArrivedScreenState extends State<ArrivedScreen> with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _confettiAnim;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    _checkScale = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _confettiAnim = Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    _checkCtrl.forward();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = getRoomByNumber(widget.roomNumber);

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated checkmark + confetti
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Confetti particles
                    ...List.generate(12, (i) {
                      return AnimatedBuilder(
                        animation: _confettiAnim,
                        builder: (_, __) {
                          final angle = i * 30.0 * (3.14159 / 180);
                          final radius = 60.0 * _confettiAnim.value;
                          return Positioned(
                            left: 60 + radius * _cosApprox(angle),
                            top: 60 + radius * _sinApprox(angle),
                            child: Opacity(
                              opacity: (1 - _confettiAnim.value).clamp(0, 1),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i % 3 == 0
                                      ? AppColors.primary
                                      : i % 3 == 1
                                      ? AppColors.accent
                                      : AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    // Check circle
                    ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 48, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text("You've Arrived! 🎉", style: AppTextStyles.headingBold(28)),
              const SizedBox(height: 16),

              // Destination card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('Room ${widget.roomNumber}',
                        style: AppTextStyles.headingBold(20, color: Colors.white)),
                    Text(
                      'Floor ${room?.floor ?? 4} · Nicol Hall',
                      style: AppTextStyles.bodyMedium(13,
                          color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Trip stats
              Row(
                children: [
                  _StatCard(value: '45m', label: 'Distance'),
                  const SizedBox(width: 10),
                  _StatCard(value: '4', label: 'Steps'),
                  const SizedBox(width: 10),
                  _StatCard(value: '1:32', label: 'Time'),
                ],
              ),
              const SizedBox(height: 28),

              GradientButton(label: 'Navigate Again →', onPressed: widget.onNavigateAgain),
              const SizedBox(height: 12),
              OutlinedPillButton(label: 'Back to Home', onPressed: widget.onHome),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text('Rate this route ⭐',
                    style: AppTextStyles.bodyMedium(13, color: AppColors.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _cosApprox(double angle) {
    const terms = [1.0, -0.5, 0.041667, -0.001389];
    double result = 0;
    for (int i = 0; i < terms.length; i++) {
      double power = 1.0;
      for (int j = 0; j < i * 2; j++) power *= angle;
      result += terms[i] * power;
    }
    return result;
  }

  double _sinApprox(double angle) {
    const terms = [1.0, -0.166667, 0.008333, -0.000198];
    double result = 0;
    for (int i = 0; i < terms.length; i++) {
      double power = angle;
      for (int j = 0; j < i * 2; j++) power *= angle;
      result += terms[i] * power;
    }
    return result;
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headingBold(20)),
            Text(label,
                style: AppTextStyles.bodyRegular(10,
                    color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// BEACON LOST SCREEN
// ============================================
class BeaconLostScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onManualSelect;

  const BeaconLostScreen({
    super.key,
    required this.onRetry,
    required this.onManualSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      {'emoji': '📶', 'text': 'Check Bluetooth is ON'},
      {'emoji': '🚶', 'text': 'Move closer to the main corridor'},
      {'emoji': '🚪', 'text': 'Avoid standing near metal doors'},
    ];

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_disabled,
                    size: 40, color: AppColors.accent),
              ),
              const SizedBox(height: 16),

              Text('Signal Lost',
                  style: AppTextStyles.headingBold(24, color: AppColors.accent)),
              const SizedBox(height: 8),
              Text(
                'We lost track of your position inside Nicol Hall.',
                style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Tips
              ...tips.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(t['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(t['text']!, style: AppTextStyles.bodyMedium(14)),
                  ],
                ),
              )),
              const SizedBox(height: 20),

              // Beacon info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Looking for beacons:',
                        style: AppTextStyles.bodyRegular(11,
                            color: AppColors.mutedForeground)),
                    const SizedBox(height: 4),
                    Text('C6:2A · E5:65:DD · C8:93:08 (F4)',
                        style: AppTextStyles.mono(10)),
                    Text('FC:17:8A · F3:55:BD · C7:A4:5A (F5)',
                        style: AppTextStyles.mono(10)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              AccentButton(label: 'Retry Detection', onPressed: onRetry),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onManualSelect,
                child: Text('Select Floor Manually',
                    style: AppTextStyles.bodyMedium(14,
                        color: AppColors.mutedForeground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}