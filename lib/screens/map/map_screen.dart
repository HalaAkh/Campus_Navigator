import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';

class MapScreen extends StatefulWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onSearchTap;

  const MapScreen({
    super.key,
    required this.onTabChange,
    required this.onSearchTap,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedFloor = 4;
  bool _sheetOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full-screen campus map background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 12),
                  Text('LAU Beirut Campus Map',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            ),
          ),

          // Building labels overlay
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _BuildingBadge(
              name: 'Nicol Hall',
              isActive: true,
              onTap: () => setState(() => _sheetOpen = true),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: MediaQuery.of(context).size.width * 0.55,
            child: const _BuildingBadge(name: 'Sage Hall'),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: MediaQuery.of(context).size.width * 0.6,
            child: const _BuildingBadge(name: 'Irwin Hall'),
          ),

          // Floating search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: widget.onSearchTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.mutedForeground, size: 18),
                    const SizedBox(width: 10),
                    Text('Search buildings...',
                        style: AppTextStyles.bodyRegular(14,
                            color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            ),
          ),

          // My location button
          Positioned(
            bottom: _sheetOpen ? 220 : 100,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.my_location, color: Colors.white, size: 22),
            ),
          ),

          // Bottom sheet
          if (_sheetOpen)
            Positioned(
              bottom: 64,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('Nicol Hall', style: AppTextStyles.headingBold(20)),
                    const SizedBox(height: 4),
                    Text('Floors 4 & 5 Available',
                        style: AppTextStyles.bodyRegular(13,
                            color: AppColors.mutedForeground)),
                    const SizedBox(height: 14),

                    // Floor pills
                    Row(
                      children: [4, 5].map((f) {
                        final isActive = f == _selectedFloor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFloor = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isActive ? AppColors.primaryGradient : null,
                              color: isActive ? null : AppColors.muted,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text('Floor $f',
                                style: AppTextStyles.bodySemiBold(13,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.mutedForeground)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    GradientButton(
                      label: 'Start Navigating →',
                      onPressed: widget.onSearchTap,
                    ),
                  ],
                ),
              ),
            ),

          // Bottom tab bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomTabBar(currentIndex: 2, onTap: widget.onTabChange),
          ),
        ],
      ),
    );
  }
}

class _BuildingBadge extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback? onTap;

  const _BuildingBadge({required this.name, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          isActive ? '📍 $name' : name,
          style: AppTextStyles.bodyBold(11,
              color: isActive ? Colors.white : AppColors.foreground),
        ),
      ),
    );
  }
}
