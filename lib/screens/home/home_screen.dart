import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/beacon_service.dart';
import '/data/rooms.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNavigateTap;
  final VoidCallback onProfileTap;
  final ValueChanged<String> onNavigateToRoom;

  const HomeScreen({
    super.key,
    required this.onSearchTap,
    required this.onNavigateTap,
    required this.onProfileTap,
    required this.onNavigateToRoom,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedFloor = 4;
  _RoomPin? _tappedRoom;
  String? _activeCategory; // null = no category sheet open

  late AnimationController _pulseCtrl, _sheetCtrl;
  late Animation<double> _pulseAnim, _sheetAnim;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);

  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.28, 0.32), 'E5:65:DD:D0:91:EC': Offset(0.68, 0.36),
    'C8:93:08:09:B2:CA': Offset(0.14, 0.48), 'FC:17:8A:61:EC:6D': Offset(0.28, 0.32),
    'F3:55:BD:A3:65:2E': Offset(0.14, 0.48), 'C7:A4:5A:D0:74:D8': Offset(0.68, 0.36),
  };

  static final List<_RoomPin> _floor4Pins = [
    _RoomPin('408', 'CS Lab', 0.68, 0.36), _RoomPin('406', 'Conference', 0.78, 0.44),
    _RoomPin('401', 'Office', 0.40, 0.30), _RoomPin('420', 'Office', 0.32, 0.26),
    _RoomPin('416', 'Office', 0.56, 0.44), _RoomPin('424', 'Office', 0.14, 0.42),
    _RoomPin('427', 'Office', 0.14, 0.56), _RoomPin('409', 'Office', 0.62, 0.52),
    _RoomPin('412', 'Office', 0.72, 0.56),
  ];

  static final List<_RoomPin> _floor5Pins = [
    _RoomPin('511', 'Lab', 0.68, 0.36), _RoomPin('516', 'Journalism Lab', 0.80, 0.54),
    _RoomPin('522', "Dean's Office", 0.36, 0.30), _RoomPin('501', 'Computer Lab', 0.44, 0.30),
    _RoomPin('503', 'Classroom', 0.56, 0.30), _RoomPin('520', 'Computer Lab', 0.50, 0.44),
    _RoomPin('526', 'Office', 0.14, 0.42), _RoomPin('512', 'Office', 0.74, 0.46),
    _RoomPin('507', 'Office', 0.72, 0.60),
  ];

  List<_RoomPin> get _pins => _selectedFloor == 4 ? _floor4Pins : _floor5Pins;

  Offset get _userPos {
    final b = context.read<BeaconService>().currentBeacon;
    if (b == null) return const Offset(0.28, 0.32);
    return _beaconPos[b.mac] ?? const Offset(0.28, 0.32);
  }

  // Get rooms for active category across both floors
  List<RoomModel> get _categoryRooms {
    if (_activeCategory == null) return [];
    return allRooms.where((r) {
      switch (_activeCategory) {
        case 'Labs': return r.category == 'Lab' || r.category == 'Classroom';
        case 'Offices': return r.category == 'Office';
        case 'Classrooms': return r.category == 'Classroom' || r.category == 'Conference';
        default: return false;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.4).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _sheetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _sheetAnim = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => BeaconService().detectCurrentLocation());
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _sheetCtrl.dispose(); super.dispose(); }

  void _onPinTap(_RoomPin pin) {
    if (_activeCategory != null) return; // don't show pin card when category sheet is open
    setState(() => _tappedRoom = pin);
    _sheetCtrl.forward(from: 0);
  }

  void _closeSheet() {
    _sheetCtrl.reverse().then((_) { if (mounted) setState(() => _tappedRoom = null); });
  }

  void _openCategory(String cat) {
    _closeSheet();
    setState(() => _activeCategory = cat);
  }

  void _closeCategory() {
    setState(() => _activeCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    final beaconSvc = context.watch<BeaconService>();
    final beacon = beaconSvc.currentBeacon;
    final size = MediaQuery.of(context).size;
    final pos = _userPos;

    if (beacon != null && beacon.floor != _selectedFloor && _activeCategory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _selectedFloor = beacon.floor); });
    }

    return Scaffold(
      body: Stack(children: [
        // ── MAP ─────────────────────────────────────────
        Positioned.fill(child: Image.asset('assets/images/campus_map.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _bg))),

        // ── ROOM LABELS ─────────────────────────────────
        ..._pins.map((pin) {
          final selected = _tappedRoom?.number == pin.number;
          // If category is active, highlight matching rooms
          final highlighted = _activeCategory != null && _isCategoryMatch(pin.number, _activeCategory!);
          final dimmed = _activeCategory != null && !highlighted;

          return Positioned(left: size.width * pin.x - 30, top: size.height * pin.y - 14,
              child: GestureDetector(onTap: () => _onPinTap(pin),
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: dimmed ? 0.3 : 1.0,
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: selected ? _primary : highlighted ? _primary.withValues(alpha: 0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: selected ? 0.15 : 0.08), blurRadius: selected ? 10 : 6, offset: const Offset(0, 2))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? Colors.white : _primary)),
                            const SizedBox(width: 4),
                            Text(pin.label.length > 10 ? pin.number : pin.label,
                                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: selected ? Colors.white : _text)),
                          ])))));
        }),

        // ── LOCATION DOT ────────────────────────────────
        if (beacon != null)
          Positioned(left: size.width * pos.dx - 18, top: size.height * pos.dy - 36,
              child: AnimatedBuilder(animation: _pulseAnim,
                  builder: (_, __) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    Transform.scale(scale: _pulseAnim.value,
                        child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.10)))),
                    Image.asset('assets/images/pin.png', width: 36, height: 36, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(width: 18, height: 18,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _primary, width: 3)),
                            child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _primary))))),
                  ]))),

        // ── SEARCH BAR ──────────────────────────────────
        Positioned(top: 0, left: 0, right: 0,
            child: SafeArea(bottom: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: GestureDetector(
                        onTap: _activeCategory != null
                            ? () {} // Don't navigate when category is open — show category name in bar
                            : widget.onSearchTap,
                        child: Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9999),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 4))]),
                            child: Row(children: [
                              if (_activeCategory != null)
                                GestureDetector(
                                  onTap: _closeCategory,
                                  child: const Padding(padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.arrow_back_rounded, color: _text, size: 22)),
                                )
                              else
                                Padding(padding: const EdgeInsets.only(right: 12),
                                    child: Image.asset('assets/images/logo.png', width: 24, height: 24,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.explore_rounded, color: _primary, size: 22))),
                              Expanded(child: Text(
                                  _activeCategory ?? 'Search here',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: _activeCategory != null ? FontWeight.w600 : FontWeight.w500,
                                      color: _activeCategory != null ? _text : _muted))),
                              if (_activeCategory != null)
                                GestureDetector(onTap: _closeCategory,
                                    child: const Icon(Icons.close_rounded, color: _muted, size: 22))
                              else
                                GestureDetector(onTap: widget.onProfileTap,
                                    child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                                        child: Center(child: Text('U', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))))),
                            ])))))),

        // ── CATEGORY CHIPS ──────────────────────────────
        if (_activeCategory == null)
          Positioned(top: 0, left: 0, right: 0,
              child: SafeArea(bottom: false,
                  child: Padding(padding: const EdgeInsets.only(top: 60),
                      child: SizedBox(height: 36,
                          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                _chipBtn('Labs', Icons.science_outlined),
                                _chipBtn('Offices', Icons.business_outlined),
                                _chipBtn('Classrooms', Icons.class_outlined),
                              ]))))),

        // ── FLOOR TOGGLE ────────────────────────────────
        if (_activeCategory == null)
          Positioned(bottom: 90, left: 16,
              child: Container(padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))]),
                  child: Column(mainAxisSize: MainAxisSize.min,
                      children: [4, 5].map((f) {
                        final active = f == _selectedFloor;
                        return GestureDetector(onTap: () { _closeSheet(); setState(() => _selectedFloor = f); },
                            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 40, height: 40,
                                margin: EdgeInsets.only(bottom: f == 4 ? 2 : 0),
                                decoration: BoxDecoration(color: active ? _primary : Colors.transparent, borderRadius: BorderRadius.circular(9)),
                                child: Center(child: Text('F$f', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : _muted)))));
                      }).toList()))),

        // ── FABs ────────────────────────────────────────
        if (_activeCategory == null)
          Positioned(bottom: 90, right: 16,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: () => beaconSvc.detectCurrentLocation(),
                    child: Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))]),
                        child: Icon(beaconSvc.isScanning ? Icons.bluetooth_searching_rounded : Icons.my_location_rounded, color: _primary, size: 20))),
                const SizedBox(height: 10),
                GestureDetector(onTap: widget.onNavigateTap,
                    child: Container(width: 52, height: 52,
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
                        child: const Icon(Icons.directions_rounded, color: Colors.white, size: 24))),
              ])),

        // ── ROOM DETAIL CARD (single pin tap) ───────────
        if (_tappedRoom != null && _activeCategory == null)
          Positioned(bottom: 80, left: 16, right: 16,
              child: AnimatedBuilder(animation: _sheetAnim,
                  builder: (_, __) => Transform.translate(offset: Offset(0, 100 * (1 - _sheetAnim.value)),
                      child: Opacity(opacity: _sheetAnim.value.clamp(0.0, 1.0),
                          child: _buildPinCard())))),

        // ── CATEGORY BOTTOM SHEET ───────────────────────
        if (_activeCategory != null)
          _buildCategorySheet(size),

        // ── BOTTOM NAV ──────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0,
            child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _border, width: 0.5))),
                child: SafeArea(top: false,
                    child: SizedBox(height: 60,
                        child: Row(children: [
                          _tab(Icons.explore_rounded, 'Explore', true, () {}),
                          _tab(Icons.bookmark_outline_rounded, 'Saved', false, () {}),
                          _tab(Icons.person_outline_rounded, 'Profile', false, widget.onProfileTap),
                        ]))))),
      ]),
    );
  }

  // ── Pin detail card ───────────────────────────────────
  Widget _buildPinCard() {
    final room = getRoomByNumber(_tappedRoom!.number);
    return Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(_tappedRoom!.number, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(room?.name ?? _tappedRoom!.label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
            Text('Room ${_tappedRoom!.number} · Floor $_selectedFloor', style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
          ])),
          GestureDetector(onTap: () { _closeSheet(); widget.onNavigateToRoom(_tappedRoom!.number); },
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.directions_rounded, color: Colors.white, size: 20))),
        ]));
  }

  // ── Category bottom sheet (Google Maps style) ─────────
  Widget _buildCategorySheet(Size size) {
    final rooms = _categoryRooms;
    final icon = _activeCategory == 'Labs' ? Icons.science_outlined
        : _activeCategory == 'Offices' ? Icons.business_outlined
        : Icons.class_outlined;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.2, 0.45, 0.85],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, -6))],
          ),
          child: Column(children: [
            // Handle
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),

            // Header
            Padding(padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                child: Row(children: [
                  Text(_activeCategory!, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _text)),
                  const Spacer(),
                  GestureDetector(onTap: _closeCategory,
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF0F4F3)),
                          child: const Icon(Icons.close_rounded, size: 18, color: _muted))),
                ])),

            const SizedBox(height: 8),

            // Filter chips
            SizedBox(height: 36,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _filterChip(Icons.tune_rounded, null, false),
                      _filterChip(null, 'Floor 4', _selectedFloor == 4),
                      _filterChip(null, 'Floor 5', _selectedFloor == 5),
                      _filterChip(null, 'All floors', true),
                    ])),

            const SizedBox(height: 8),

            // Room list
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: rooms.length,
                itemBuilder: (_, i) => _CategoryRoomCard(
                  room: rooms[i],
                  onDirections: () { _closeCategory(); widget.onNavigateToRoom(rooms[i].number); },
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  bool _isCategoryMatch(String roomNumber, String category) {
    final room = getRoomByNumber(roomNumber);
    if (room == null) return false;
    switch (category) {
      case 'Labs': return room.category == 'Lab' || room.category == 'Classroom';
      case 'Offices': return room.category == 'Office';
      case 'Classrooms': return room.category == 'Classroom' || room.category == 'Conference';
      default: return false;
    }
  }

  Widget _chipBtn(String label, IconData icon) {
    final active = _activeCategory == label;
    return GestureDetector(
      onTap: () => _openCategory(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: active ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? Colors.white : _text),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : _text)),
        ]),
      ),
    );
  }

  Widget _filterChip(IconData? icon, String? label, bool active) => Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: icon != null && label == null ? 10 : 14, vertical: 6),
      decoration: BoxDecoration(
          color: active ? const Color(0xFFE0F2F0) : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: active ? _primary.withValues(alpha: 0.3) : _border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 16, color: _muted),
        if (icon != null && label != null) const SizedBox(width: 4),
        if (label != null) Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: active ? _primary : _muted)),
        if (label == 'Floor 4' || label == 'Floor 5') const SizedBox(width: 2),
      ]));

  Widget _tab(IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? _primary : _muted;
    return Expanded(child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: color), const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: color)),
        ])));
  }
}

// ── Category room card (Google Maps restaurant card style) ─
class _CategoryRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onDirections;
  const _CategoryRoomCard({required this.room, required this.onDirections});

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Room name + info
        Text(room.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
        const SizedBox(height: 2),
        Row(children: [
          Text(room.category, style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          Text(' · ', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          Text('Room ${room.number}', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          Text(' · ', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          Text('Floor ${room.floor}', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
        ]),
        const SizedBox(height: 3),
        Text('~30m · Nicol Hall', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _primary)),

        const SizedBox(height: 10),

        // Action buttons row (Directions, Share, Save)
        Row(children: [
          _ActionBtn(icon: Icons.directions_rounded, label: 'Directions', filled: true, onTap: onDirections),
          const SizedBox(width: 8),
          _ActionBtn(icon: Icons.share_outlined, label: 'Share', filled: false, onTap: () {}),
          const SizedBox(width: 8),
          _ActionBtn(icon: Icons.bookmark_outline_rounded, label: 'Save', filled: false, onTap: () {}),
        ]),

        const SizedBox(height: 14),
        Container(height: 0.5, color: _border),
      ]),
    );
  }
}

// ── Action button (Directions / Share / Save) ───────────
class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final bool filled; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: filled ? const Color(0xFFE0F7F4) : Colors.white,
                borderRadius: BorderRadius.circular(9999),
                border: filled ? null : Border.all(color: const Color(0xFFE5EBEB))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: filled ? const Color(0xFF007A6E) : const Color(0xFF6B7B7A)),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500,
                  color: filled ? const Color(0xFF007A6E) : const Color(0xFF6B7B7A))),
            ])));
  }
}

class _RoomPin {
  final String number, label; final double x, y;
  const _RoomPin(this.number, this.label, this.x, this.y);
}