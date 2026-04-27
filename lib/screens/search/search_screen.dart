import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  RoomModel? _selectedRoom; // for detail sheet

  static const _primary = Color(0xFF007A6E);
  static const _text    = Color(0xFF1C2B2A);
  static const _muted   = Color(0xFF6B7B7A);
  static const _border  = Color(0xFFE5EBEB);
  static const _bg      = Color(0xFFF7FAFA);

  List<RoomModel> get _filtered => RoomsService().search(_query);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _openDetail(RoomModel room) => setState(() => _selectedRoom = room);
  void _closeDetail() => setState(() => _selectedRoom = null);

  @override
  Widget build(BuildContext context) {
    final results       = _filtered;
    final showRecent    = _query.isEmpty;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [

        Column(children: [
          // ── SEARCH BAR ──────────────────────────────
          SafeArea(bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(left: 4, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: _selectedRoom != null ? _closeDetail : widget.onBack,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                          _selectedRoom != null ? Icons.arrow_back_rounded : Icons.arrow_back_rounded,
                          color: _text, size: 22),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (v) { setState(() { _query = v; _selectedRoom = null; }); },
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text),
                      decoration: InputDecoration(
                        hintText: 'Room, professor, email…',
                        hintStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () { _ctrl.clear(); setState(() { _query = ''; _selectedRoom = null; }); },
                      child: const Icon(Icons.close_rounded, color: _muted, size: 20),
                    ),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: keyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 80),
              child: _selectedRoom != null
                  ? _buildRoomDetail(_selectedRoom!)
                  : showRecent
                  ? _buildRecent()
                  : results.isEmpty
                  ? _buildEmpty()
                  : _buildResults(results),
            ),
          ),
        ]),

        // ── BOTTOM TAB BAR ──────────────────────────
        if (!keyboardVisible)
          Positioned(bottom: 0, left: 0, right: 0,
            child: AppBottomTabBar(currentIndex: 1, onTap: (i) {
              if (i == 0) widget.onBack();
              if (i == 2) widget.onSavedTap();
              if (i == 3) widget.onProfileTap();
            }),
          ),
      ]),
    );
  }

  // ── ROOM DETAIL VIEW ──────────────────────────────────────────────────
  Widget _buildRoomDetail(RoomModel room) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Room header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: Text(room.number,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _primary))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
              Text('${room.category} · Floor ${room.floor} · ${room.building}',
                  style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
            ])),
          ]),
        ),

        const SizedBox(height: 16),

        // Navigate button
        GestureDetector(
          onTap: () => widget.onRoomSelected(room.number),
          child: Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Navigate to ${room.number}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),

        // ── PROFESSOR INFO ─────────────────────────
        if (room.hasProfessorInfo) ...[
          const SizedBox(height: 24),
          Text('Office Info',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(children: [

              if (room.professorsName != null)
                _infoRow(Icons.person_outline_rounded, 'Professor', room.professorsName!, isFirst: true),

              if (room.professorTitle != null)
                _infoRow(Icons.school_outlined, 'Title', room.professorTitle!,
                    isFirst: room.professorsName == null),

              if (room.professorEmail != null)
                _infoRow(Icons.mail_outline_rounded, 'Email', room.professorEmail!,
                    isFirst: room.professorsName == null && room.professorTitle == null,
                    onTap: () => _launchEmail(room.professorEmail!)),

              if (room.officeHours != null)
                _infoRow(Icons.schedule_outlined, 'Office Hours', room.officeHours!,
                    isFirst: !room.hasProfessorInfo,
                    isLast: true),

            ]),
          ),
        ],

        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(children: [
      if (!isFirst)
        Divider(height: 1, color: _border, indent: 56),
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                      color: _muted, letterSpacing: 0.3)),
              const SizedBox(height: 1),
              Text(value,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                      color: onTap != null ? _primary : _text,
                      decoration: onTap != null ? TextDecoration.underline : null)),
            ])),
            if (onTap != null)
              Icon(Icons.open_in_new_rounded, size: 14, color: _muted),
          ]),
        ),
      ),
    ]);
  }

  // ── RECENT ────────────────────────────────────────────────────────────
  Widget _buildRecent() {
    final recent = context.watch<AppState>().navigationHistory;
    return ListView(padding: EdgeInsets.zero, children: [
      if (recent.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Recent',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
        ),
        ...recent.take(5).map((num) {
          final room = RoomsService().getRoomByNumber(num);
          return _buildRoomTile(room, num);
        }),
      ] else
        Center(child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text('No recents', style: GoogleFonts.poppins(fontSize: 14, color: _muted)),
        )),
    ]);
  }

  // ── RESULTS ───────────────────────────────────────────────────────────
  Widget _buildResults(List<RoomModel> rooms) {
    // Pin professor-match results to top
    final q = _query.toLowerCase();
    final profMatches = rooms.where((r) =>
    r.professorsName?.toLowerCase().contains(q) == true ||
        r.professorEmail?.toLowerCase().contains(q) == true ||
        r.professorTitle?.toLowerCase().contains(q) == true).toList();
    final others = rooms.where((r) => !profMatches.contains(r)).toList();
    final sorted = [...profMatches, ...others];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sorted.length,
      itemBuilder: (_, i) => _buildRoomTile(sorted[i], sorted[i].number),
    );
  }

  Widget _buildRoomTile(RoomModel? room, String number) {
    final hasProfInfo = room?.hasProfessorInfo == true;
    return Column(children: [
      GestureDetector(
        onTap: () {
          if (room != null && room.hasProfessorInfo) {
            _openDetail(room);
          } else {
            widget.onRoomSelected(number);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0F4F3)),
              child: Icon(
                  hasProfInfo ? Icons.person_outline_rounded : Icons.location_on_outlined,
                  size: 18, color: _muted),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(room?.name ?? 'Room $number',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text))),
                if (hasProfInfo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9999)),
                    child: Text('Office',
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _primary)),
                  ),
              ]),
              if (hasProfInfo && room!.professorsName != null)
                Text(room.professorsName!,
                    style: GoogleFonts.poppins(fontSize: 12, color: _primary, fontWeight: FontWeight.w500))
              else
                Text('Room $number · Floor ${room?.floor ?? (number.startsWith('5') ? 5 : 4)} · ${room?.building ?? 'Nicol Hall'}',
                    style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
            ])),
            Icon(hasProfInfo ? Icons.info_outline_rounded : Icons.chevron_right_rounded,
                size: 18, color: _muted),
          ]),
        ),
      ),
      Padding(padding: const EdgeInsets.only(left: 74),
          child: Container(height: 0.5, color: _border)),
    ]);
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded, size: 48, color: _border),
    const SizedBox(height: 8),
    Text('No rooms found', style: GoogleFonts.poppins(fontSize: 14, color: _muted)),
    const SizedBox(height: 4),
    Text('Try a room number, professor name, or email',
        style: GoogleFonts.poppins(fontSize: 12, color: _border)),
  ]));

  static Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}