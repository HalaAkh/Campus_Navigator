import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_state.dart';
import '/services/beacon_service.dart';
import '/data/rooms.dart';
import '/services/rooms_service.dart';


class NavigateSearchScreen extends StatefulWidget {
  final String? prefilledRoom;
  final ValueChanged<String> onStartNavigation;
  final VoidCallback onBack;
  const NavigateSearchScreen({super.key, this.prefilledRoom, required this.onStartNavigation, required this.onBack});
  @override
  State<NavigateSearchScreen> createState() => _NavigateSearchScreenState();
}

class _NavigateSearchScreenState extends State<NavigateSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _red = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    if (widget.prefilledRoom != null) {
      final room = RoomsService().getRoomByNumber(widget.prefilledRoom!);
      _ctrl.text = room?.name ?? 'Room ${widget.prefilledRoom}';
      _query = _ctrl.text;
    }
  }

  List<RoomModel> get _filtered {
    final rooms = RoomsService().allRooms;
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return rooms.where((r) =>
    r.number.contains(q) ||
        r.name.toLowerCase().contains(q) ||
        r.category.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final beaconSvc = context.watch<BeaconService>();
    final beacon = beaconSvc.currentBeacon;
    final rooms = _filtered;
    final f4 = rooms.where((r) => r.floor == 4).toList();
    final f5 = rooms.where((r) => r.floor == 5).toList();

    // If prefilled, show the "Start" button
    final prefilledRoom = widget.prefilledRoom != null ? RoomsService().getRoomByNumber(widget.prefilledRoom!) : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // ── HEADER ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + 8, 0, 0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: _text, size: 22),
                    padding: const EdgeInsets.only(top: 10),
                  ),
                  Expanded(
                    child: Column(children: [
                      // Your location
                      Container(
                        height: 42,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFFF7FAFA), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                        child: Row(children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _primary)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              beacon != null ? beacon.location.replaceAll('Floor ${beacon.floor} - ', '') : 'Your location',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: beacon != null ? _primary : _muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),
                      // Destination field
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFA), borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _query.isNotEmpty ? _primary : _border)),
                        child: Row(children: [
                          Icon(Icons.location_on_rounded, size: 14, color: _query.isNotEmpty ? _red : _muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: widget.prefilledRoom == null,
                              onChanged: (v) => setState(() => _query = v),
                              style: GoogleFonts.poppins(fontSize: 13, color: _text),
                              decoration: InputDecoration(
                                hintText: 'Choose destination',
                                hintStyle: GoogleFonts.poppins(fontSize: 13, color: _muted),
                                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.swap_vert_rounded, color: _muted, size: 22), padding: const EdgeInsets.only(top: 20)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: _border),
          ]),
        ),

        // ── "Start Navigation" button if prefilled ──────
        if (widget.prefilledRoom != null && prefilledRoom != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GestureDetector(
              onTap: () => widget.onStartNavigation(widget.prefilledRoom!),
              child: Container(
                width: double.infinity, height: 48,
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Start Navigation to ${prefilledRoom.name}',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ),

        // ── ROOM LIST ───────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Recent
              if (_query.isEmpty) ...[
                Builder(builder: (context) {
                  final recent = context.watch<AppState>().navigationHistory;
                  if (recent.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(child: Text('No recents',
                          style: GoogleFonts.poppins(fontSize: 14, color: _muted))),
                    );
                  }
                  return Column(children: [
                    Padding(padding: const EdgeInsets.only(top: 4, bottom: 10),
                        child: Text('Recent', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                    ...recent.take(5).map((num) {
                      final room = RoomsService().getRoomByNumber(num);
                      return _RecentRow(
                        name: room?.name ?? 'Room $num',
                        sub: 'Room $num · Floor ${room?.floor ?? (num.startsWith('5') ? 5 : 4)}',
                        onTap: () => widget.onStartNavigation(num),
                      );
                    }),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: _border),
                    const SizedBox(height: 8),
                  ]);
                }),
              ],

              if (f4.isNotEmpty) ...[
                _floorHeader('FLOOR 4'),
                ...f4.map((r) => _RoomRow(room: r, onTap: () => widget.onStartNavigation(r.number))),
                const SizedBox(height: 10),
              ],
              if (f5.isNotEmpty) ...[
                _floorHeader('FLOOR 5'),
                ...f5.map((r) => _RoomRow(room: r, onTap: () => widget.onStartNavigation(r.number))),
              ],

              if (rooms.isEmpty && _query.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 60),
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off_rounded, size: 48, color: _border),
                      const SizedBox(height: 8),
                      Text('No rooms found', style: GoogleFonts.poppins(fontSize: 14, color: _muted)),
                    ]))),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _floorHeader(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 1.2)),
  );
}

class _ModeChip extends StatelessWidget {
  final IconData icon; final String label; final bool active;
  const _ModeChip(this.icon, this.label, this.active);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: active ? const Color(0xFF007A6E) : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: active ? null : Border.all(color: const Color(0xFFE5EBEB))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF6B7B7A)), const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: active ? Colors.white : const Color(0xFF6B7B7A))),
      ]));
}

class _RecentRow extends StatelessWidget {
  final String name, sub; final VoidCallback onTap;
  const _RecentRow({required this.name, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF0F4F3)),
                child: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6B7B7A))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1C2B2A))),
              Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7B7A))),
            ])),
          ])));
}

class _RoomRow extends StatelessWidget {
  final RoomModel room; final VoidCallback onTap;
  const _RoomRow({required this.room, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF0F4F3))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF7FAFA), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(room.number, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF007A6E))))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1C2B2A))),
              Text(room.category, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7B7A))),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFE5EBEB)),
          ])));
}