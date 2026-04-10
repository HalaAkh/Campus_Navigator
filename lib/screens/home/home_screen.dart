import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common/widgets.dart';
import '../../data/rooms.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onTabChange;
  final ValueChanged<String> onRoomTap;
  final VoidCallback onSearchTap;
  final VoidCallback onMapTap;

  const HomeScreen({
    super.key,
    required this.onTabChange,
    required this.onRoomTap,
    required this.onSearchTap,
    required this.onMapTap,
  });

  static const _quickDestinations = [
    {'emoji': '🖥', 'label': 'CS Lab 408', 'room': '408'},
    {'emoji': '📚', 'label': 'Room 501', 'room': '501'},
    {'emoji': '🎙', 'label': 'Journalism 516', 'room': '516'},
    {'emoji': '🏛', 'label': "Dean's 522", 'room': '522'},
    {'emoji': '📋', 'label': 'Conf. 406', 'room': '406'},
    {'emoji': '🔬', 'label': 'Lab 511', 'room': '511'},
  ];

  static const _recentSearches = ['Room 412', 'Room 511', 'Room 424'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Hero header
          GradientHeader(
            bottomRadius: 28,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${state.userName} 🎓',
                                style: AppTextStyles.headingBold(20, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nicol Hall · Floor ${state.currentFloor}',
                                style: AppTextStyles.bodyMedium(13,
                                    color: Colors.white.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              state.userName.isNotEmpty
                                  ? state.userName[0].toUpperCase()
                                  : 'A',
                              style: AppTextStyles.headingBold(18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '3 beacons active',
                          style: AppTextStyles.bodyMedium(12,
                              color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        GestureDetector(
                          onTap: onSearchTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(9999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                                const SizedBox(width: 12),
                                Text('Where are you headed?',
                                    style: AppTextStyles.bodyRegular(14,
                                        color: AppColors.mutedForeground)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // BLE status
                        BeaconStatusPill(active: true, floor: state.currentFloor),
                        const SizedBox(height: 20),

                        // Campus map card
                        GestureDetector(
                          onTap: onMapTap,
                          child: Container(
                            height: 176,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Stack(
                              children: [
                                // Map placeholder
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                                    child: const Center(
                                      child: Icon(Icons.map_outlined, size: 64,
                                          color: Colors.white54),
                                    ),
                                  ),
                                ),
                                // Overlay gradient
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                                    ),
                                  ),
                                ),
                                // Labels
                                Positioned(
                                  bottom: 12,
                                  left: 16,
                                  child: Text(
                                    'LAU Beirut Campus',
                                    style: AppTextStyles.headingBold(14, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text('Explore →',
                                        style: AppTextStyles.bodyBold(11, color: Colors.white)),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: const Text('📍 Nicol Hall',
                                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Destinations
                        Text('Quick Destinations', style: AppTextStyles.headingBold(15)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _quickDestinations.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final d = _quickDestinations[i];
                              return GestureDetector(
                                onTap: () => onRoomTap(d['room']!),
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(d['emoji']!, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(height: 4),
                                      Text(
                                        d['label']!,
                                        style: AppTextStyles.bodyMedium(9),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recent Searches
                        Text('Recent Searches', style: AppTextStyles.headingBold(15)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentSearches.map((s) {
                            return GestureDetector(
                              onTap: () => onRoomTap(s.replaceAll('Room ', '')),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text('🕐 $s',
                                    style: AppTextStyles.bodySemiBold(12,
                                        color: AppColors.accent)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomTabBar(
        currentIndex: 0,
        onTap: onTabChange,
      ),
    );
  }
}
