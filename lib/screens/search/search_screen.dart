import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/data/rooms.dart';

/// SEARCH — Opens when tapping "Search here" on home.
/// Search bar matches home's pill bar (same position, same style).
/// Below: recent searches, then filtered room list.
class SearchScreen extends StatefulWidget {
  final ValueChanged<String> onRoomSelected;
  final VoidCallback onBack;
  const SearchScreen({super.key, required this.onRoomSelected, required this.onBack});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _primary = Color(0xFF007A6E);

  static const _recent = ['408', '516', '522', '501', '406'];

  List<RoomModel> get _filtered {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return allRooms.where((r) =>
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // ── SEARCH BAR (same position as HomeScreen) ────
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
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(children: [
                // Back arrow (replaces logo)
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.arrow_back_rounded, color: _text, size: 22),
                  ),
                ),
                // Text field
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
                // Clear / mic
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                    child: const Icon(Icons.close_rounded, color: _muted, size: 20),
                  )
                else
                  const Icon(Icons.mic_none_rounded, color: _muted, size: 22),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── CONTENT ─────────────────────────────────────
        Expanded(
          child: showRecent ? _buildRecent() : results.isEmpty ? _buildEmpty() : _buildResults(results),
        ),
      ]),
    );
  }

  // ── RECENT ────────────────────────────────────────────
  Widget _buildRecent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Recent header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(children: [
            Text('Recent', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
            const Spacer(),
            Icon(Icons.info_outline_rounded, size: 18, color: _border),
          ]),
        ),

        // Recent items with dividers
        ..._recent.map((num) {
          final room = getRoomByNumber(num);
          return Column(children: [
            GestureDetector(
              onTap: () => widget.onRoomSelected(num),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  // Clock icon
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0F4F3),
                    ),
                    child: const Icon(Icons.access_time_rounded, size: 18, color: _muted),
                  ),
                  const SizedBox(width: 14),
                  // Room info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room?.name ?? 'Room $num',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text),
                        ),
                        if (room != null)
                          Text(
                            'Room $num · Floor ${room.floor} · Nicol Hall',
                            style: GoogleFonts.poppins(fontSize: 12, color: _muted),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            // Divider
            Padding(
              padding: const EdgeInsets.only(left: 74),
              child: Container(height: 0.5, color: _border),
            ),
          ]);
        }),

        // More from recent history
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'More from recent history',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _primary),
            ),
          ),
        ),
      ],
    );
  }

  // ── SEARCH RESULTS ────────────────────────────────────
  Widget _buildResults(List<RoomModel> rooms) {
    return ListView(
      padding: EdgeInsets.zero,
      children: rooms.map((r) {
        return Column(children: [
          GestureDetector(
            onTap: () => widget.onRoomSelected(r.number),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(children: [
                // Location icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF0F4F3),
                  ),
                  child: const Icon(Icons.location_on_outlined, size: 18, color: _muted),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text)),
                      Text(
                        'Room ${r.number} · Floor ${r.floor} · ${r.category}',
                        style: GoogleFonts.poppins(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 74),
            child: Container(height: 0.5, color: _border),
          ),
        ]);
      }).toList(),
    );
  }

  // ── EMPTY ─────────────────────────────────────────────
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