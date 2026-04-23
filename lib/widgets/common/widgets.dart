import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utils/theme.dart';

// ============================================
// GRADIENT BUTTON (primary CTA)
// ============================================
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 50,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyBold(fontSize, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ============================================
// AMBER BUTTON (accent CTA)
// ============================================
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double height;

  const AccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Center(
          child: Text(label, style: AppTextStyles.bodyBold(16, color: Colors.white)),
        ),
      ),
    );
  }
}

// ============================================
// OUTLINED BUTTON
// ============================================
class OutlinedPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color textColor;
  final double? width;

  const OutlinedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Center(
          child: Text(label, style: AppTextStyles.bodySemiBold(16, color: textColor)),
        ),
      ),
    );
  }
}

// ============================================
// APP CARD
// ============================================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007A6E).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ============================================
// GRADIENT HERO HEADER
// ============================================
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final double bottomRadius;

  const GradientHeader({
    super.key,
    required this.child,
    this.height = 200,
    this.bottomRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
      ),
      child: child,
    );
  }
}

// ============================================
// BEACON STATUS PILL
// ============================================
class BeaconStatusPill extends StatelessWidget {
  final bool active;
  final int floor;

  const BeaconStatusPill({super.key, this.active = true, this.floor = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Active · Floor $floor · Strong Signal',
            style: AppTextStyles.bodyMedium(11, color: AppColors.foreground),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.success : AppColors.destructive,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// ROOM LIST TILE
// ============================================
class RoomListTile extends StatelessWidget {
  final String number;
  final String name;
  final String category;
  final VoidCallback onTap;

  const RoomListTile({
    super.key,
    required this.number,
    required this.name,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(number, style: AppTextStyles.headingBold(13, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodySemiBold(14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      category,
                      style: AppTextStyles.bodyMedium(10, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 18),
          ],
        ),
      ),
    );
  }
}

// ============================================
// CUSTOM TOGGLE SWITCH
// ============================================
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// SETTINGS ROW
// ============================================
class SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium(14)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ============================================
// BOTTOM TAB BAR
// ============================================
// REPLACE your AppBottomTabBar with this updated version:
class AppBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomTabBar({super.key, required this.currentIndex, required this.onTap});

  static const _primary = Color(0xFF007A6E);
  static const _muted = Color(0xFF6B7B7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _Tab(icon: Icons.map_outlined, activeIcon: Icons.map_rounded,
                  label: 'Map', active: currentIndex == 0, onTap: () => onTap(0)),
              _Tab(icon: Icons.search_outlined, activeIcon: Icons.search_rounded,
                  label: 'Search', active: currentIndex == 1, onTap: () => onTap(1)),
              _Tab(icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded,
                  label: 'Saved', active: currentIndex == 2, onTap: () => onTap(2)),
              _Tab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'Profile', active: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.icon, required this.activeIcon, required this.label,
    required this.active, required this.onTap});

  static const _primary = Color(0xFF007A6E);
  static const _muted = Color(0xFF6B7B7A);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(active ? activeIcon : icon,
            size: 22, color: active ? _primary : _muted),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? _primary : _muted)),
      ]),
    ),
  );
}

// ============================================
// SHIMMER LOADING SKELETON
// ============================================
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.muted.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
