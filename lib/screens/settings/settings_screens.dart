import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common/widgets.dart';
import '../../services/beacon_service.dart';

// SETTINGS SCREEN
class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.card,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                ),
                Text('Settings', style: AppTextStyles.headingBold(18)),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionLabel('Navigation'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Default floor
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Default Floor', style: AppTextStyles.bodyMedium(14)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [4, 5].map((f) {
                                  final isActive = state.defaultFloor == f;
                                  return GestureDetector(
                                    onTap: () => state.setDefaultFloor(f),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: isActive ? AppColors.primaryGradient : null,
                                        borderRadius: BorderRadius.circular(9999),
                                      ),
                                      child: Text('F$f',
                                          style: AppTextStyles.bodyBold(12,
                                              color: isActive
                                                  ? Colors.white
                                                  : AppColors.mutedForeground)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Divider(),
                      SettingsRow(
                        label: 'Auto-detect floor',
                        trailing: AppToggle(value: state.autoDetect, onChanged: state.setAutoDetect),
                      ),
                      _Divider(),
                      SettingsRow(
                        label: 'Show beacon zones',
                        trailing: AppToggle(value: state.showBeaconZones, onChanged: state.setShowBeaconZones),
                      ),
                      _Divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            Expanded(child: Text('Voice hints', style: AppTextStyles.bodyMedium(14))),
                            Text('Coming soon',
                                style: AppTextStyles.bodyRegular(12,
                                    color: AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _SectionLabel('Bluetooth'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan Interval', style: AppTextStyles.bodyMedium(14)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Battery Saver',
                                    style: AppTextStyles.bodyRegular(10,
                                        color: AppColors.mutedForeground)),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.primary,
                                      thumbColor: AppColors.primary,
                                      inactiveTrackColor: AppColors.muted,
                                    ),
                                    child: Slider(value: 0.5, onChanged: (_) {}),
                                  ),
                                ),
                                Text('Accurate',
                                    style: AppTextStyles.bodyRegular(10,
                                        color: AppColors.mutedForeground)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _Divider(),
                      SettingsRow(
                        label: 'Background scanning',
                        trailing: AppToggle(value: state.bgScanning, onChanged: state.setBgScanning),
                      ),
                      _Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Beacons', style: AppTextStyles.bodyMedium(14)),
                            const SizedBox(height: 8),
                            ...AppBeacons.all.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text('${b.mac} — ${b.location}',
                                  style: AppTextStyles.mono(9)),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _SectionLabel('Accessibility'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsRow(label: 'Large text', trailing: AppToggle(value: state.largeText, onChanged: state.setLargeText)),
                      _Divider(),
                      SettingsRow(label: 'High contrast', trailing: AppToggle(value: state.highContrast, onChanged: state.setHighContrast)),
                      _Divider(),
                      SettingsRow(label: 'Reduced motion', trailing: AppToggle(value: state.reducedMotion, onChanged: state.setReducedMotion)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _SectionLabel('Account'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsRow(
                        label: 'Change password',
                        trailing: const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedForeground),
                        onTap: () {},
                      ),
                      _Divider(),
                      SettingsRow(
                        label: 'Delete account',
                        trailing: const SizedBox.shrink(),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.bodyMedium(11, color: AppColors.mutedForeground)
            .copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16);
}

// SAVED ROOMS SCREEN
class SavedRoomsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onNavigate;

  const SavedRoomsScreen({super.key, required this.onBack, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                ),
                Text('Saved Rooms', style: AppTextStyles.headingBold(18)),
              ],
            ),
          ),
          Expanded(
            child: state.savedRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_outline, size: 48,
                            color: AppColors.accent.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('No saved rooms', style: AppTextStyles.headingBold(16)),
                        Text('Star a room to find it faster',
                            style: AppTextStyles.bodyRegular(14,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.savedRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final room = state.savedRooms[i];
                      return AppCard(
                        padding: const EdgeInsets.all(14),
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
                                child: Text(room.number,
                                    style: AppTextStyles.headingBold(13, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(room.name, style: AppTextStyles.bodySemiBold(14)),
                                  Text('Floor ${room.floor} · Nicol Hall',
                                      style: AppTextStyles.bodyRegular(11,
                                          color: AppColors.mutedForeground)),
                                ],
                              ),
                            ),
                            const Icon(Icons.favorite, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => onNavigate(room.number),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text('Navigate →',
                                    style: AppTextStyles.bodyBold(11, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => state.removeRoom(room.number),
                              child: Icon(Icons.delete_outline, size: 16,
                                  color: AppColors.destructive.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// HELP & FAQ SCREEN
class HelpScreen extends StatefulWidget {
  final VoidCallback onBack;
  const HelpScreen({super.key, required this.onBack});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _openIdx;
  String _search = '';

  static const _faqs = [
    _FAQ('How does indoor navigation work?',
        'We use BLE (Bluetooth Low Energy) beacons from MOKO placed throughout Nicol Hall. Your phone detects these beacons to determine your approximate position on Floor 4 or Floor 5, then AI provides step-by-step directions.'),
    _FAQ('Why does the app need Bluetooth?',
        'Bluetooth is essential for detecting the BLE beacons installed in Nicol Hall. Without it, the app cannot determine your indoor position since GPS doesn\'t work well indoors.'),
    _FAQ('What if my position is wrong?',
        'Try moving to the nearest corridor or open area. Beacon signals can be weakened by walls and metal doors. You can also manually select your floor and retry detection.'),
    _FAQ('Which floors are supported?',
        'Floor 4 (29 rooms, 3 beacons) and Floor 5 (28 rooms, 3 beacons) in Nicol Hall, LAU Beirut Campus.'),
    _FAQ('How do floor transitions work?',
        'When navigating between floors, use the Main Stairs (near the elevator, Beacon C6:2A / FC:17:8A area) or Back Stairs (from Room 408 turn RIGHT on F4, from Room 511 turn LEFT on F5).'),
    _FAQ('What are the beacon MAC addresses?',
        'Floor 4: C6:2A (Elevator), E5:65:DD (Room 408), C8:93:08 (Left Corridor). Floor 5: FC:17:8A (Elevator), F3:55:BD (Left Corridor), C7:A4:5A (Room 511).'),
    _FAQ('The app can\'t find me — what do I do?',
        '1) Ensure Bluetooth is ON. 2) Move to the main corridor. 3) Avoid metal doors or thick walls. 4) Try manually selecting your floor. 5) Restart the app if issues persist.'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _faqs
        : _faqs.where((f) =>
            f.q.toLowerCase().contains(_search.toLowerCase()) ||
            f.a.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                    ),
                    Text('Help & FAQ', style: AppTextStyles.headingBold(18)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setState(() { _search = v; _openIdx = null; }),
                  decoration: AppDecorations.pillInputDecoration(
                    hint: 'Search help topics...',
                    prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.mutedForeground),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...filtered.asMap().entries.map((e) {
                  final i = e.key;
                  final faq = e.value;
                  final isOpen = _openIdx == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _openIdx = isOpen ? null : i),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(faq.q, style: AppTextStyles.bodySemiBold(14)),
                                  ),
                                  Icon(
                                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 18, color: AppColors.mutedForeground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isOpen)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(faq.a,
                                  style: AppTextStyles.bodyRegular(13,
                                      color: AppColors.mutedForeground)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Still need help? Contact us →',
                        style: AppTextStyles.bodySemiBold(14, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQ {
  final String q;
  final String a;
  const _FAQ(this.q, this.a);
}

// FEEDBACK SCREEN
class FeedbackScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const FeedbackScreen({super.key, required this.onBack, required this.onHome});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _category = '';
  String _message = '';
  int _rating = 0;
  bool _submitted = false;

  static const _categories = ['Bug Report', 'Wrong Directions', 'Feature Request', 'Other'];

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: AppColors.card,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Thank you!', style: AppTextStyles.headingBold(22)),
              const SizedBox(height: 8),
              Text('Your feedback helps us improve.',
                  style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground)),
              const SizedBox(height: 28),
              GradientButton(label: 'Back to Home', onPressed: widget.onHome, width: 200),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 12),
            child: Row(
              children: [
                IconButton(onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: AppColors.foreground)),
                Text('Send Feedback 📣', style: AppTextStyles.headingBold(18)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Categories
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final isActive = _category == c;
                    return GestureDetector(
                      onTap: () => setState(() => _category = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.primaryGradient : null,
                          color: isActive ? null : AppColors.muted,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(c,
                            style: AppTextStyles.bodySemiBold(12,
                                color: isActive ? Colors.white : AppColors.mutedForeground)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Textarea
                TextField(
                  onChanged: (v) => setState(() => _message = v),
                  maxLines: 5,
                  decoration: AppDecorations.inputDecoration(
                    hint: 'Tell us what you think...',
                  ).copyWith(
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text('📍', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('Room 408 · Floor 4', style: AppTextStyles.bodyMedium(13)),
                      const Spacer(),
                      Text('✏️', style: AppTextStyles.bodyMedium(14, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Star rating
                Center(
                  child: Column(
                    children: [
                      Text('Rate your experience',
                          style: AppTextStyles.bodyMedium(13, color: AppColors.mutedForeground)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                i < _rating ? Icons.star : Icons.star_border,
                                color: AppColors.accent,
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                AccentButton(label: 'Submit', onPressed: () => setState(() => _submitted = true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ABOUT SCREEN
class AboutScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AboutScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final beacons = ['C6:2A', 'E5:65:DD', 'C8:93:08', 'FC:17:8A', 'F3:55:BD', 'C7:A4:5A'];
    final details = [
      _Detail('Institution', 'Lebanese American University'),
      _Detail('Coverage', 'Nicol Hall — Floor 4 (29 rooms) · Floor 5 (28 rooms)'),
      _Detail('Technology', 'BLE Beacons (MOKO) + OpenAI GPT-4o-mini + Flutter'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 32),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Campus Navigator LAU',
                      style: AppTextStyles.headingBold(20, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text('v1.0.0', style: AppTextStyles.bodyBold(12, color: Colors.white)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Navigator is an indoor BLE beacon navigation app designed exclusively for Lebanese American University\'s Beirut Campus. Navigate Nicol Hall\'s Floors 4 and 5 with real-time Bluetooth positioning and AI-powered directions.',
                      style: AppTextStyles.bodyRegular(13),
                    ),
                    const SizedBox(height: 20),

                    ...details.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.label,
                              style: AppTextStyles.bodyRegular(11,
                                  color: AppColors.mutedForeground)),
                          Text(d.value, style: AppTextStyles.bodyMedium(13)),
                        ],
                      ),
                    )),

                    const SizedBox(height: 8),
                    Text('Beacons (6 total)',
                        style: AppTextStyles.bodyRegular(11, color: AppColors.mutedForeground)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: beacons.map((b) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(b,
                            style: AppTextStyles.mono(10, color: AppColors.primary)),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text('Privacy Policy',
                              style: AppTextStyles.bodySemiBold(13, color: AppColors.primary)),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('Terms of Use',
                              style: AppTextStyles.bodySemiBold(13, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Text('© 2024 Campus Navigator · LAU Beirut Campus',
                style: AppTextStyles.bodyRegular(10,
                    color: AppColors.mutedForeground.withOpacity(0.6))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Detail {
  final String label;
  final String value;
  const _Detail(this.label, this.value);
}
