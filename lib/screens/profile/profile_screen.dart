import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common/widgets.dart';

class ProfileScreen extends StatelessWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onSettings;
  final VoidCallback onSavedRooms;
  final VoidCallback onAbout;
  final VoidCallback onHelp;
  final VoidCallback onFeedback;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.onTabChange,
    required this.onSettings,
    required this.onSavedRooms,
    required this.onAbout,
    required this.onHelp,
    required this.onFeedback,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final initials = state.userName.isNotEmpty
        ? state.userName.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'AH';

    final menuItems = [
      _MenuItem(icon: Icons.accessibility_new_outlined, label: 'Accessibility', onTap: onSettings),
      _MenuItem(icon: Icons.bluetooth_outlined, label: 'Bluetooth & Beacons', onTap: onSettings),
      _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: onSettings),
      _MenuItem(icon: Icons.favorite_outline, label: 'Saved Rooms', onTap: onSavedRooms),
      _MenuItem(icon: Icons.info_outline, label: 'About', onTap: onAbout),
      _MenuItem(icon: Icons.help_outline, label: 'Help & FAQ', onTap: onHelp),
      _MenuItem(icon: Icons.chat_bubble_outline, label: 'Feedback', onTap: onFeedback),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Gradient banner
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient2),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 12,
                          left: 20,
                          right: 20,
                        ),
                        child: Row(
                          children: [
                            // Logo
                            Container(
                              width: 36,
                              height: 36,
                              child: Image.asset(
                                'assets/images/pin1.png',
                                fit: BoxFit.scaleDown,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(state.userName,
                                    style: AppTextStyles.headingBold(18, color: Colors.white)),
                                Text(state.userEmail,
                                    style: AppTextStyles.bodyRegular(12,
                                        color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Avatar
                      Positioned(
                        bottom: -40,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.card, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(initials,
                                style: AppTextStyles.headingBold(24, color: AppColors.primary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),

                  // LAU badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text('LAU Student',
                        style: AppTextStyles.bodyBold(12, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _StatTile(value: '${state.navigationCount}', label: 'Navigations'),
                        const SizedBox(width: 10),
                        _StatTile(value: '${state.savedRooms.length}', label: 'Saved'),
                        const SizedBox(width: 10),
                        _StatTile(value: 'Floor 4', label: 'Favourite'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: menuItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: item.onTap,
                          child: Row(
                            children: [
                              Icon(item.icon, size: 18, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item.label, style: AppTextStyles.bodyMedium(14)),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: AppColors.mutedForeground),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign out
                  TextButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, size: 16, color: AppColors.destructive),
                    label: Text('Sign Out',
                        style: AppTextStyles.bodyMedium(14, color: AppColors.destructive)),
                  ),
                  const SizedBox(height: 8),

                  Text('v1.0.0 · LAU Beirut Campus',
                      style: AppTextStyles.bodyRegular(10,
                          color: AppColors.mutedForeground.withOpacity(0.6))),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomTabBar(currentIndex: 2, onTap: (i) {
        if (i == 0) onTabChange(0);
        if (i == 1) onTabChange(1);  // ← This triggers savedRoomsNav in navigator
      }),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headingBold(16)),
            Text(label,
                style: AppTextStyles.bodyRegular(9, color: AppColors.mutedForeground),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});
}
