import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/rooms_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common/widgets.dart';
import '/services/beacon_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onSettings;
  final VoidCallback onSavedRooms;
  final VoidCallback onAbout;
  final VoidCallback onHelp;
  final VoidCallback onFeedback;
  final VoidCallback onSignOut;
  final ValueChanged<String> onNavigateToRoom;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);

  const ProfileScreen({
    super.key,
    required this.onTabChange,
    required this.onSettings,
    required this.onSavedRooms,
    required this.onAbout,
    required this.onHelp,
    required this.onFeedback,
    required this.onSignOut,
    required this.onNavigateToRoom,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final beacon = context.watch<BeaconService>().currentBeacon;
    final initials = state.userName.isNotEmpty
        ? state.userName.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';
    final isProf = state.userEmail.endsWith('@lau.edu.lb');
    final isStudent = state.userEmail.endsWith('@lau.edu');
    final badgeLabel = isProf ? 'LAU Professor' : isStudent ? 'LAU Student' : 'LAU Member';
    final badgeColor = isProf ? const Color(0xFF1A56A0) : _primary;

    final menuItems = [
      _MenuItem(icon: Icons.accessibility_new_outlined, label: 'Accessibility', onTap: onSettings),
      _MenuItem(icon: Icons.bluetooth_outlined, label: 'Bluetooth & Beacons', onTap: onSettings),
      _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: onSettings),
      _MenuItem(icon: Icons.info_outline, label: 'About', onTap: onAbout),
      _MenuItem(icon: Icons.help_outline, label: 'Help & FAQ', onTap: onHelp),
      _MenuItem(icon: Icons.chat_bubble_outline, label: 'Feedback', onTap: onFeedback),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [

          // ── HEADER BANNER ─────────────────────────────
          Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient2),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20, right: 20,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Image.asset('assets/images/pin1.png', width: 28, height: 28,
                    errorBuilder: (_, __, ___) => const Icon(Icons.explore, color: Colors.white, size: 28)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(state.userName,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(state.userEmail,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                ]),

                const Spacer(),

                // Live floor badge
                if (beacon != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF6EE7B7), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Floor ${beacon.floor}',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                  ),
              ]),
            ),

            // Avatar
            Positioned(bottom: -36, child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12)],
              ),
              child: Center(child: Text(initials,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: _primary))),
            )),
          ]),

          const SizedBox(height: 50),

          // LAU badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(9999)),
          child: Text(badgeLabel,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
          const SizedBox(height: 20),

          // ── STATS ROW ──────────────────────────────────
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _StatTile(value: '${state.navigationCount}', label: 'Navigations'),
              const SizedBox(width: 10),
              _StatTile(value: '${state.savedRooms.length}', label: 'Saved'),
              const SizedBox(width: 10),
              _StatTile(
                value: beacon != null ? 'F${beacon.floor}' : '--',
                label: 'You are here',
                isLive: beacon != null,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── SAVED ROOMS PREVIEW ────────────────────────
          if (state.savedRooms.isNotEmpty) ...[
            _SectionHeader(title: 'Saved Rooms', actionLabel: 'See all', onAction: onSavedRooms),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.savedRooms.take(5).length,
                itemBuilder: (context, i) {
                  final room = state.savedRooms[i];
                  return GestureDetector(
                    onTap: () => onNavigateToRoom(room.number),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.meeting_room_outlined, color: _primary, size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(room.number,
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _text)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── RECENT NAVIGATIONS ─────────────────────────
          if (state.navigationHistory.isNotEmpty) ...[
            _SectionHeader(title: 'Recent', actionLabel: '', onAction: () {}),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: state.navigationHistory.take(3).map((roomNum) {
                  final room = RoomsService().getRoomByNumber(roomNum);
                  return GestureDetector(
                    onTap: () => onNavigateToRoom(roomNum),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.history_rounded, color: _primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(room?.name ?? 'Room $roomNum',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
                          Text('Room $roomNum · Floor ${room?.floor ?? (roomNum.startsWith("5") ? 5 : 4)}',
                              style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                        ])),
                        const Icon(Icons.navigation_rounded, color: _primary, size: 16),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── MENU ──────────────────────────────────────
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: menuItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Column(children: [
                      GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(children: [
                            Icon(item.icon, size: 18, color: _primary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.label,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _text))),
                            const Icon(Icons.chevron_right, size: 16, color: _muted),
                          ]),
                        ),
                      ),
                      if (i < menuItems.length - 1)
                        Divider(height: 1, color: _border, indent: 46),
                    ]);
                  }).toList(),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Sign out
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
            label: Text('Sign Out',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
          ),
          const SizedBox(height: 6),
          Text('v1.0.0 · LAU Beirut Campus',
              style: GoogleFonts.poppins(fontSize: 10, color: _muted.withOpacity(0.6))),
          const SizedBox(height: 80),
        ]))),
      ]),

      bottomNavigationBar: AppBottomTabBar(currentIndex: 3, onTap: (i) {
        if (i == 0) onTabChange(0);
        if (i == 1) onTabChange(1);
        if (i == 2) onTabChange(2);
      })
    );
  }
}

// ── SECTION HEADER ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback onAction;
  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Row(children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1C2B2A))),
      const Spacer(),
      if (actionLabel.isNotEmpty)
        GestureDetector(onTap: onAction,
            child: Text(actionLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF007A6E)))),
    ]),
  );
}

// ── STAT TILE ─────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String value, label;
  final bool isLive;
  const _StatTile({required this.value, required this.label, this.isLive = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBEB)),
      ),
      child: Column(children: [
        if (isLive)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF007A6E))),
          ])
        else
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1C2B2A))),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF6B7B7A)), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});
}