import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/common/widgets.dart';
import '/utils/app_state.dart';
import '/data/rooms.dart';

class SavedRoomsNavScreen extends StatelessWidget {
  final ValueChanged<int> onTabChange;
  final ValueChanged<String> onNavigateToRoom;

  const SavedRoomsNavScreen({
    super.key,
    required this.onTabChange,
    required this.onNavigateToRoom,
  });

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final saved = appState.savedRooms;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // ── HEADER ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
          child: Row(children: [
            Image.asset('assets/images/pin1.png', width: 28, height: 28, fit: BoxFit.scaleDown, filterQuality: FilterQuality.high),
            const SizedBox(width: 10),
            Text('Saved Rooms', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _text)),
          ]),
        ),
        Container(height: 0.5, color: _border),

        // ── CONTENT ─────────────────────────────────────
        Expanded(
          child: saved.isEmpty
              ? _buildEmpty()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: saved.length,
            itemBuilder: (_, i) => _SavedRoomCard(
              room: saved[i],
              onDirections: () => onNavigateToRoom(saved[i].number),
              onRemove: () => appState.toggleSavedRoom(saved[i].number),
              onShare: () => Share.share(
                  'Check out ${saved[i].name} (Room ${saved[i].number}) on Floor ${saved[i].floor} at ${saved[i].building}'),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: AppBottomTabBar(currentIndex: 1, onTap: onTabChange),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bookmark_outline_rounded, size: 36, color: _primary),
        ),
        const SizedBox(height: 16),
        Text('No saved rooms', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
        const SizedBox(height: 6),
        Text('Tap the save button on any room\nto add it here.',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _SavedRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onDirections;
  final VoidCallback onRemove;
  final VoidCallback onShare;

  const _SavedRoomCard({
    required this.room,
    required this.onDirections,
    required this.onRemove,
    required this.onShare,
  });

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Room info row
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(room.number, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _primary))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
            Text('${room.category} · Floor ${room.floor} · ${room.building}',
                style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
          ])),
        ]),
        const SizedBox(height: 12),

        // Action buttons
        Row(children: [
          _ActionBtn(
            icon: Icons.directions_rounded,
            label: 'Directions',
            color: _primary,
            onTap: onDirections,
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.share_outlined,
            label: 'Share',
            color: _primary,
            onTap: onShare,
          ),
          const Spacer(),
          _ActionBtn(
            icon: Icons.bookmark_remove_outlined,
            label: 'Remove',
            color: const Color(0xFFEF4444),
            onTap: onRemove,
          ),
        ]),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
