import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/widgets.dart';
import '/data/rooms.dart';
import '/services/rooms_service.dart';
import '/utils/app_state.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<String> onRoomSelected;
  final VoidCallback onBack;
  final VoidCallback onSavedTap;
  final VoidCallback onProfileTap;

  const SearchScreen({
    super.key,
    required this.onRoomSelected,
    required this.onBack,
    required this.onSavedTap,
    required this.onProfileTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);

  List<RoomModel> get _filtered {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return RoomsService().allRooms.where((r) =>
    r.number.contains(q) ||
        r.name.toLowerCase().contains(q) ||
        r.category.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final showRecent = _query.isEmpty;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing up the bottom bar
      body: Stack(children: [
        Column(children: [
          // ── SEARCH BAR ──────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(left: 4, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.arrow_back_rounded, color: _text, size: 22),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text),
                      decoration: InputDecoration(
                        hintText: 'Search here',
                        hintStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                      child: const Icon(Icons.close_rounded, color: _muted, size: 20),
                    )
                ]),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── CONTENT ─────────────────────────────────────
          Expanded(
            child: Padding(
              // Add padding at the bottom so results aren't hidden behind keyboard/tabbar
              padding: EdgeInsets.only(bottom: keyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 80),
              child: showRecent ? _buildRecent() : results.isEmpty ? _buildEmpty() : _buildResults(results),
            ),
          ),
        ]),

        // ── BOTTOM TAB BAR (Only show if keyboard is NOT visible) ────────
        if (!keyboardVisible)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AppBottomTabBar(
              currentIndex: 1,
              onTap: (i) {
                if (i == 0) widget.onBack();
                if (i == 2) widget.onSavedTap();
                if (i == 3) widget.onProfileTap();
              },
            ),
          ),
      ]),
    );
  }

  Widget _buildRecent() {
    final recent = context.watch<AppState>().navigationHistory;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Text('Recent', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
              const Spacer(),
              Icon(Icons.info_outline_rounded, size: 18, color: _border),
            ]),
          ),
          ...recent.take(5).map((num) {
            final room = RoomsService().getRoomByNumber(num);
            return _buildRoomTile(room, num);
          }),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('No recents', style: GoogleFonts.poppins(fontSize: 14, color: _muted)),
            ),
          ),
      ],
    );
  }

  Widget _buildResults(List<RoomModel> rooms) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final r = rooms[index];
        return _buildRoomTile(r, r.number);
      },
    );
  }

  Widget _buildRoomTile(RoomModel? room, String number) {
    return Column(children: [
      GestureDetector(
        onTap: () => widget.onRoomSelected(number),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0F4F3)),
              child: Icon(room == null ? Icons.access_time_rounded : Icons.location_on_outlined, size: 18, color: _muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room?.name ?? 'Room $number', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text)),
                  Text(
                    'Room $number · Floor ${room?.floor ?? (number.startsWith('5') ? 5 : 4)} · ${room?.building ?? 'Nicol Hall'}',
                    style: GoogleFonts.poppins(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
      Padding(padding: const EdgeInsets.only(left: 74), child: Container(height: 0.5, color: _border)),
    ]);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: _border),
          const SizedBox(height: 8),
          Text('No rooms found', style: GoogleFonts.poppins(fontSize: 14, color: _muted)),
          const SizedBox(height: 4),
          Text('Try a different search', style: GoogleFonts.poppins(fontSize: 12, color: _border)),
        ],
      ),
    );
  }
}
