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
  bool _showAllRecent = false;
  RoomModel? _selectedRoom;

  static const _primary = Color(0xFF007A6E);
  static const _text    = Color(0xFF1C2B2A);
  static const _muted   = Color(0xFF6B7B7A);
  static const _border  = Color(0xFFE5EBEB);
  static const _bg      = Color(0xFFF7FAFA);

  List<RoomModel> get _filtered => RoomsService().search(_query);

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

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
          // SEARCH BAR
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
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.arrow_back_rounded, color: _text, size: 22),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (v) { setState(() { _query = v; _selectedRoom = null; }); },
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

        // BOTTOM TAB BAR
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

  Widget _buildRoomDetail(RoomModel room) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)),
              child: Center(child: Text(room.number, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _primary))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
              Text('${room.category} · Floor ${room.floor} · ${room.building}', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            context.read<AppState>().addToNavigationHistory(room.number);
            widget.onRoomSelected(room.number);
          },
          child: Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Navigate to ${room.number}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
        if (room.hasProfessorInfo) ...[
          const SizedBox(height: 24),
          Text('Office Info', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
            child: Column(children: [
              if (room.professorsName != null) _infoRow(Icons.person_outline_rounded, 'Professor', room.professorsName!, isFirst: true),
              if (room.professorTitle != null) _infoRow(Icons.school_outlined, 'Title', room.professorTitle!, isFirst: room.professorsName == null),
              if (room.professorEmail != null)
                GestureDetector(
                  onTap: () => _launchEmail(room.professorEmail!),
                  child: _infoRow(
                    Icons.mail_outline_rounded,
                    'Email',
                    room.professorEmail!,
                    isFirst: room.professorsName == null && room.professorTitle == null,
                    isLink: true, // Pass a flag for visual feedback
                  ),
                ),              if (room.officeHours != null) _infoRow(Icons.schedule_outlined, 'Office Hours', room.officeHours!, isLast: true),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isFirst = false, bool isLast = false, bool isLink = false}) {
    return Column(children: [
      if (!isFirst) Divider(height: 1, color: _border, indent: 56),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.3)),
            Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isLink ? _primary : _text,
                  decoration: isLink ? TextDecoration.underline : null,
                )
            ),
          ])),
        ]),
      ),
    ]);
  }

  Widget _buildRecent() {
    final recent = context.watch<AppState>().navigationHistory;
    if (recent.isEmpty) return _buildEmpty();

    final displayList = _showAllRecent ? recent : recent.take(5).toList();

    return ListView(padding: EdgeInsets.zero, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Text('Recent', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
          const Spacer(),
          if (recent.length > 5)
            GestureDetector(
              onTap: () => setState(() => _showAllRecent = !_showAllRecent),
              child: Text(_showAllRecent ? 'Show less' : 'See all',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
            ),
        ]),
      ),
      ...displayList.map((num) {
        final room = RoomsService().getRoomByNumber(num);
        return _buildRoomTile(room, num);
      }),
    ]);
  }

  Widget _buildResults(List<RoomModel> rooms) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: rooms.length,
      itemBuilder: (_, i) => _buildRoomTile(rooms[i], rooms[i].number),
    );
  }

  Widget _buildRoomTile(RoomModel? room, String number) {
    final appState = context.watch<AppState>();
    final isSaved = appState.isRoomSaved(number);
    final hasProfInfo = room?.hasProfessorInfo == true;
    return Column(children: [
      GestureDetector(
        onTap: () {
          appState.addToNavigationHistory(number);
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
              child: Icon(hasProfInfo ? Icons.person_outline_rounded : Icons.location_on_outlined, size: 18, color: _muted),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(room?.name ?? 'Room $number', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _text))),
                if (hasProfInfo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9999)),
                    child: Text('Office', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _primary)),
                  ),
              ]),
              Text('Room $number · Floor ${room?.floor ?? (number.startsWith('5') ? 5 : 4)} · ${room?.building ?? 'Nicol Hall'}', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
            ])),
            // ── QUICK SAVE ICON ──
            GestureDetector(
              onTap: () => appState.toggleSavedRoom(number),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 22,
                  color: isSaved ? _primary : _muted,
                ),
              ),
            ),
            Icon(hasProfInfo ? Icons.info_outline_rounded : Icons.chevron_right_rounded, size: 18, color: _muted),
          ]),
        ),
      ),
      Padding(padding: const EdgeInsets.only(left: 74), child: Container(height: 0.5, color: _border)),
    ]);
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded, size: 48, color: _border),
    const SizedBox(height: 8),
    Text('No rooms found', style: GoogleFonts.poppins(fontSize: 14, color: _muted)),
    const SizedBox(height: 4),
    Text('Try searching for a room number or professor', style: GoogleFonts.poppins(fontSize: 12, color: _border)),
  ]));
}
