import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_state.dart';
import '../../widgets/common/widgets.dart';
import '/services/beacon_service.dart';
import '/data/rooms.dart';
import '/services/rooms_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNavigateTap;
  final VoidCallback onProfileTap;
  final ValueChanged<String> onNavigateToRoom;
  final VoidCallback onSavedTap;

  const HomeScreen({
    super.key,
    required this.onSearchTap,
    required this.onNavigateTap,
    required this.onSavedTap,
    required this.onProfileTap,
    required this.onNavigateToRoom,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedFloor = 4;
  RoomModel? _tappedRoom;
  String? _activeCategory;
  int? _categoryFloorFilter;

  final GlobalKey _sheetKey = GlobalKey();

  late AnimationController _pulseCtrl, _sheetCtrl;
  late Animation<double> _pulseAnim, _sheetAnim;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);

  // ── FLOOR 4 ROOM POSITIONS (matched to new map.png) ──────────────
  static const Map<String, Offset> _f4Rooms = {
    '424': Offset(0.25, 0.33), '425': Offset(0.25, 0.37),
    '426': Offset(0.25, 0.41), '427': Offset(0.25, 0.45),
    '428': Offset(0.25, 0.49), '429': Offset(0.25, 0.53),
    '430': Offset(0.25, 0.57),
    '423': Offset(0.31, 0.28), '422': Offset(0.41, 0.28),
    '421': Offset(0.51, 0.28), '420': Offset(0.61, 0.28),
    '401': Offset(0.60, 0.33), '402': Offset(0.60, 0.38),
    '403': Offset(0.60, 0.43), '404': Offset(0.60, 0.48),
    '4WC2': Offset(0.70, 0.33),
    '419': Offset(0.70, 0.37), '418': Offset(0.70, 0.41),
    '417': Offset(0.70, 0.45), '416': Offset(0.70, 0.49),
    '4WC':  Offset(0.70, 0.53),
    '408': Offset(0.57, 0.55),
    '409': Offset(0.70, 0.61), '410': Offset(0.70, 0.66),
    '411': Offset(0.70, 0.71), '415': Offset(0.80, 0.61),
    '414': Offset(0.80, 0.66), '413': Offset(0.80, 0.71),
    '412': Offset(0.80, 0.76),
    '407': Offset(0.47, 0.61), '406': Offset(0.42, 0.66),
  };

  // ── FLOOR 5 ROOM POSITIONS (matched to new map.png) ──────────────
  static const Map<String, Offset> _f5Rooms = {
    '526': Offset(0.25, 0.33), '527': Offset(0.25, 0.38),
    '528': Offset(0.25, 0.43), '529': Offset(0.25, 0.48),
    '525': Offset(0.31, 0.28), '524': Offset(0.41, 0.28),
    '523': Offset(0.51, 0.28), '522': Offset(0.61, 0.28),
    '501': Offset(0.60, 0.33), '502': Offset(0.60, 0.38),
    '503': Offset(0.60, 0.43),
    '521': Offset(0.70, 0.33), '520': Offset(0.70, 0.38),
    '5WC':  Offset(0.70, 0.43),
    '511': Offset(0.57, 0.55),
    '5WC2': Offset(0.37, 0.61),
    '504': Offset(0.37, 0.66), '505': Offset(0.37, 0.71),
    '506': Offset(0.37, 0.76), '510': Offset(0.47, 0.61),
    '509': Offset(0.47, 0.66), '508': Offset(0.47, 0.71),
    '507': Offset(0.42, 0.81),
    '512': Offset(0.70, 0.61), '513': Offset(0.70, 0.66),
    '514': Offset(0.70, 0.71), '515': Offset(0.70, 0.76),
    '519': Offset(0.80, 0.61), '518': Offset(0.80, 0.66),
    '517': Offset(0.80, 0.71), '516': Offset(0.75, 0.81),
  };

  // Beacon screen positions — matched to new room positions
  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.41, 0.28),  // F4 Elevator — near 422
    'E5:65:DD:D0:91:EC': Offset(0.57, 0.55),  // F4 Room 408
    'C8:93:08:09:B2:CA': Offset(0.25, 0.41),  // F4 Left Offices — near 426
    'F4:7B:74:76:D5:8A': Offset(0.41, 0.28),  // F5 Elevator — near 524
    'C7:A4:5A:D0:74:D8': Offset(0.57, 0.55),  // F5 Room 511
    'F3:55:BD:A3:65:2E': Offset(0.25, 0.38),  // F5 Left Offices — near 527
  };

  Offset get _userPos {
    final b = context.read<BeaconService>().currentBeacon;
    if (b == null) return const Offset(0.41, 0.28);
    return _beaconPos[b.mac] ?? const Offset(0.41, 0.28);
  }

  List<RoomModel> get _floorRooms =>
      RoomsService().allRooms.where((r) => r.floor == _selectedFloor && r.active).toList();

  List<RoomModel> get _categoryRooms {
    if (_activeCategory == null) return [];
    return RoomsService().allRooms.where((r) {
      bool matchCat = false;
      switch (_activeCategory) {
        case 'Labs':       matchCat = r.category == 'Lab'; break;
        case 'Offices':    matchCat = r.category == 'Office'; break;
        case 'Classrooms': matchCat = r.category == 'Classroom' || r.category == 'Conference'; break;
        case 'Toilets':    matchCat = r.category == 'Toilet' || r.category == 'Restroom'; break;
        case 'All':        matchCat = true; break;
        default:           matchCat = r.category == _activeCategory; break;
      }
      bool matchFloor = _categoryFloorFilter == null || r.floor == _categoryFloorFilter;
      return matchCat && matchFloor && r.active;
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

  void _onRoomTap(RoomModel room) { if (_activeCategory != null) return; setState(() => _tappedRoom = room); _sheetCtrl.forward(from: 0); }
  void _closeSheet() { _sheetCtrl.reverse().then((_) { if (mounted) setState(() => _tappedRoom = null); }); }
  void _openCategory(String cat) { _closeSheet(); setState(() => _activeCategory = cat); }
  void _closeCategory() {
    setState(() {
      _activeCategory = null;
      _categoryFloorFilter = null;
    });
  }
  Offset _getRoomPos(String number) {
    final map = _selectedFloor == 4 ? _f4Rooms : _f5Rooms;
    return map[number] ?? const Offset(0.44, 0.40);
  }

  @override
  Widget build(BuildContext context) {
    final beaconSvc = context.watch<BeaconService>();
    final beacon = beaconSvc.currentBeacon;
    final size = MediaQuery.of(context).size;
    final pos = _userPos;
    final rooms = _floorRooms;

    if (beacon != null && beacon.floor != _selectedFloor && _activeCategory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _selectedFloor = beacon.floor); });
    }

    return Scaffold(
      body: Stack(children: [
        // ── MAP ─────────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: () { if (_tappedRoom != null) _closeSheet(); },
            child: Image.asset('assets/images/map.png', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _bg)),
          ),
        ),

        // ── ROOM LABELS ─────────────────────────────────
        ...rooms.map((room) {
          final p = _getRoomPos(room.number);
          final selected = _tappedRoom?.number == room.number;
          final highlighted = _activeCategory != null && _isCategoryMatch(room);
          final dimmed = _activeCategory != null && !highlighted;

          return Positioned(
            left: size.width * p.dx - 18,
            top: size.height * p.dy - 9,
            child: GestureDetector(
              onTap: () => _onRoomTap(room),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: dimmed ? 0.25 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected ? _primary : highlighted ? _primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: selected ? 0.18 : 0.08), blurRadius: selected ? 6 : 3, offset: const Offset(0, 1))],
                  ),
                  child: Text(
                      room.number.contains('WC') ? 'WC' : room.number,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? Colors.white : _text)),
                ),
              ),
            ),
          );
        }),

        // ── LOCATION PIN — centered on beacon position ────
        if (beacon != null)
          Positioned(
            left: size.width * pos.dx - 20,
            top: size.height * pos.dy - 38,
            child: AnimatedBuilder(animation: _pulseAnim,
                builder: (_, __) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                  Transform.scale(scale: _pulseAnim.value,
                      child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.10)))),
                  Image.asset('assets/images/pin1.png', width: 35, height: 35, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(width: 16, height: 16,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _primary, width: 3)))),
                ])),
          ),

        // ── SEARCH BAR ──────────────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(bottom: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: _activeCategory != null ? () {} : widget.onSearchTap,
                child: Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9999),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 4))]),
                    child: Row(children: [
                      if (_activeCategory != null)
                        GestureDetector(onTap: _closeCategory,
                            child: const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.arrow_back_rounded, color: _text, size: 22)))
                      else
                        Image.asset('assets/images/pin1.png', width: 24, height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.explore_rounded, color: _primary, size: 20)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_activeCategory ?? 'Search here',
                          style: GoogleFonts.poppins(fontSize: 15,
                              fontWeight: _activeCategory != null ? FontWeight.w600 : FontWeight.w500,
                              color: _activeCategory != null ? _text : _muted))),
                      if (_activeCategory != null)
                        GestureDetector(onTap: _closeCategory, child: const Icon(Icons.close_rounded, color: _muted, size: 22))
                      else
                        GestureDetector(onTap: widget.onProfileTap,
                            child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                                child: Center(child: Text(
                                    context.watch<AppState>().userName.isNotEmpty
                                        ? context.watch<AppState>().userName[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))))),
                    ])),
              ),
            ),
          ),
        ),

        // ── CATEGORY CHIPS ──────────────────────────────
        if (_activeCategory == null)
          Positioned(top: 10, left: 0, right: 0,
              child: SafeArea(bottom: false,
                  child: Padding(padding: const EdgeInsets.only(top: 60),
                      child: SizedBox(height: 36,
                          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                _chipBtn('Labs', Icons.science_outlined),
                                _chipBtn('Offices', Icons.business_outlined),
                                _chipBtn('Classrooms', Icons.class_outlined),
                                _chipBtn('Toilets',    Icons.wc_outlined),
                              ]))))),

        // ── FLOOR TOGGLE ────────────────────────────────
        if (_activeCategory == null)
          Positioned(bottom: 75, left: 16,
              child: Container(padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))]),
                  child: Column(mainAxisSize: MainAxisSize.min,
                      children: [4, 5].map((f) {
                        final active = f == _selectedFloor;
                        return GestureDetector(
                            onTap: () { _closeSheet(); setState(() { _selectedFloor = f; if (_tappedRoom?.floor != f) _tappedRoom = null; }); },
                            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 40, height: 40,
                                margin: EdgeInsets.only(bottom: f == 4 ? 2 : 0),
                                decoration: BoxDecoration(color: active ? _primary : Colors.transparent, borderRadius: BorderRadius.circular(9)),
                                child: Center(child: Text('F$f', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : _muted)))));
                      }).toList()))),

        // ── FABs ────────────────────────────────────────
        if (_activeCategory == null)
          Positioned(bottom: 75, right: 16,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: () => beaconSvc.detectCurrentLocation(),
                    child: Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))]),
                        child: Icon(beaconSvc.isScanning ? Icons.bluetooth_searching_rounded : Icons.my_location_rounded, color: _primary, size: 20))),
                const SizedBox(height: 6),
                GestureDetector(onTap: widget.onNavigateTap,
                    child: Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
                        child: const Icon(Icons.directions_rounded, color: Colors.white, size: 24))),
              ])),

        // ── ROOM DETAIL CARD ────────────────────────────
        if (_tappedRoom != null && _activeCategory == null)
          Positioned(bottom: 80, left: 16, right: 16,
              child: AnimatedBuilder(animation: _sheetAnim,
                  builder: (_, __) => Transform.translate(offset: Offset(0, 100 * (1 - _sheetAnim.value)),
                      child: Opacity(opacity: _sheetAnim.value.clamp(0.0, 1.0), child: _buildPinCard())))),

        // ── BOTTOM NAV ──────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0,
            child: AppBottomTabBar(currentIndex: 0, onTap: (i) {
              if (i == 1) widget.onSearchTap();   // ← Search tab
              if (i == 2) widget.onSavedTap();    // ← Saved tab
              if (i == 3) widget.onProfileTap();  // ← Profile tab
            })),

        // ── CATEGORY SHEET ──────────────────────────────
        if (_activeCategory != null) _buildCategorySheet(size),

      ]),
    );
  }

  Widget _buildPinCard() {
    final room = _tappedRoom!;
    final roomPos = _getRoomPos(room.number);
    final userPos = _userPos;
    final dx = roomPos.dx - userPos.dx;
    final dy = roomPos.dy - userPos.dy;
    final distanceInMeters = (math.sqrt(dx * dx + dy * dy) * 100).toStringAsFixed(0);
    final hasProfInfo = room.hasProfessorInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // ── TOP ROW ─────────────────────────────────────────────────────
        Row(children: [
          Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(
                  room.number,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _primary)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(room.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                Text(
                  hasProfInfo && room.professorsName != null
                      ? '${room.professorsName} · Floor ${room.floor}'
                      : '${room.category} · Floor ${room.floor} · ${distanceInMeters}m',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: hasProfInfo && room.professorsName != null
                          ? _primary
                          : _muted),
                ),
              ])),
          GestureDetector(
              onTap: () { _closeSheet(); widget.onNavigateToRoom(room.number); },
              child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.directions_rounded,
                      color: Colors.white, size: 20))),
        ]),

        // ── PROFESSOR DETAILS ────────────────────────────────────────────
        if (hasProfInfo) ...[
          const SizedBox(height: 12),
          Container(height: 0.5, color: _border),
          const SizedBox(height: 10),

          if (room.professorsName != null)
            _pinInfoRow(Icons.person_outline_rounded, room.professorsName!),

          if (room.professorTitle != null)
            _pinInfoRow(Icons.school_outlined, room.professorTitle!),

          if (room.officeHours != null)
            _pinInfoRow(Icons.schedule_outlined, 'Office hours: ${room.officeHours!}'),

          if (room.professorEmail != null)
            _pinInfoRow(Icons.mail_outline_rounded, room.professorEmail!,
                isEmail: true),
        ],
      ]),
    );
  }

  Widget _pinInfoRow(IconData icon, String value, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, size: 14, color: _muted),
        const SizedBox(width: 8),
        Expanded(child: Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: isEmail ? _primary : _muted,
                decoration: isEmail ? TextDecoration.underline : null),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }


  // 1. Add this key to your _HomeScreenState variables at the top  final GlobalKey _sheetKey = GlobalKey();

  Widget _buildCategorySheet(Size size) {
    final rooms = _categoryRooms;
    final userPos = _userPos;

    return Positioned.fill(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) => true,
        child: DraggableScrollableSheet(
          key: _sheetKey,
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.95,
          snap: true,
          builder: (context, scrollCtrl) {
            return Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 65), // Above bottom nav
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
                  ],
                ),
                child: ListView.builder(
                  // Attaching the controller here makes everything inside draggable
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  // Disable semantic indexing to prevent the 'parentDataDirty' crash
                  addSemanticIndexes: false,
                  // +2 because we are adding the Handle and the Header as items
                  itemCount: rooms.length + 2,
                  itemBuilder: (context, index) {
                    // ITEM 0: THE DRAG HANDLE (Now functional!)
                    if (index == 0) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        // Transparent background so the whole top area is a drag target
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 40, height: 5,
                            decoration: BoxDecoration(
                              color: _border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    }

                    // ITEM 1: THE HEADER (Title, Close Button, Chips)
                    if (index == 1) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(_activeCategory!,
                                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              IconButton(onPressed: _closeCategory, icon: const Icon(Icons.close)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                GestureDetector(
                                    onTap: () => setState(() => _categoryFloorFilter = 4),
                                    child: _filterChip(null, 'Floor 4', _categoryFloorFilter == 4)),
                                GestureDetector(
                                    onTap: () => setState(() => _categoryFloorFilter = 5),
                                    child: _filterChip(null, 'Floor 5', _categoryFloorFilter == 5)),
                                GestureDetector(
                                    onTap: () => setState(() => _categoryFloorFilter = null),
                                    child: _filterChip(null, 'All floors', _categoryFloorFilter == null)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    // REMAINING ITEMS: THE ROOM CARDS
                    final room = rooms[index - 2]; // Adjust index
                    final roomPos = _getRoomPos(room.number);
                    final dx = roomPos.dx - userPos.dx;
                    final dy = roomPos.dy - userPos.dy;
                    final distance = (math.sqrt(dx * dx + dy * dy) * 100).toStringAsFixed(0);

                    // Use watch to react to "Saved" state changes
                    final appState = context.watch<AppState>();

                    return _CategoryRoomCard(
                      key: ValueKey('cat_${room.number}'),
                      room: room,
                      distance: distance,
                      isSaved: appState.isRoomSaved(room.number),
                      onDirections: () {
                        _closeCategory();
                        widget.onNavigateToRoom(room.number);
                      },
                      onSave: () {
                        appState.toggleSavedRoom(room.number);
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isCategoryMatch(RoomModel room) {
    switch (_activeCategory) {
      case 'Labs':       return room.category == 'Lab';
      case 'Offices':    return room.category == 'Office';
      case 'Classrooms': return room.category == 'Classroom' || room.category == 'Conference';
      case 'Toilets':    return room.category == 'Toilet' || room.category == 'Restroom';
      case 'All':        return true;
      default:           return room.category == _activeCategory;
    }
  }

  Widget _chipBtn(String label, IconData icon) {
    final active = _activeCategory == label;
    return GestureDetector(onTap: () => _openCategory(label),
        child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: active ? _primary : Colors.white, borderRadius: BorderRadius.circular(9999),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: active ? Colors.white : _text), const SizedBox(width: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : _text))])));
  }

  Widget _filterChip(IconData? icon, String? label, bool active) => Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: icon != null && label == null ? 10 : 14, vertical: 6),
      decoration: BoxDecoration(color: active ? const Color(0xFFE0F2F0) : Colors.white, borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: active ? _primary.withValues(alpha: 0.3) : _border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 16, color: _muted),
        if (icon != null && label != null) const SizedBox(width: 4),
        if (label != null) Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: active ? _primary : _muted))]));
}

// ─── CATEGORY CARD ───────────────────────────────────────────────────────────
class _CategoryRoomCard extends StatefulWidget {
  final RoomModel room;
  final String distance;
  final bool isSaved;
  final VoidCallback onDirections;
  final VoidCallback onSave;
  const _CategoryRoomCard({super.key, required this.room, required this.distance, required this.isSaved, required this.onDirections, required this.onSave});
  @override
  State<_CategoryRoomCard> createState() => _CategoryRoomCardState();
}

class _CategoryRoomCardState extends State<_CategoryRoomCard> {
  bool _isShareActive = false;

  static const _primary = Color(0xFF007A6E);
  static const _text    = Color(0xFF1C2B2A);
  static const _muted   = Color(0xFF6B7B7A);
  static const _border  = Color(0xFFE5EBEB);

  @override
  Widget build(BuildContext context) {
    final room        = widget.room;
    final hasProfInfo = room.hasProfessorInfo;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text(room.name,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
        const SizedBox(height: 2),
        Text('${room.category} · Room ${room.number} · Floor ${room.floor}',
            style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
        const SizedBox(height: 3),
        Text('${widget.distance} m · ${room.building}',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w500, color: _primary)),

        // ── PROFESSOR INFO BOX ───────────────────────────────────────────
        if (hasProfInfo) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (room.professorsName != null)
                    _profRow(
                      Icons.person_outline_rounded,
                      room.professorsName!,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _text),
                    ),

                  if (room.professorTitle != null)
                    _profRow(Icons.school_outlined, room.professorTitle!),

                  if (room.officeHours != null)
                    _profRow(Icons.schedule_outlined,
                        'Office hours: ${room.officeHours!}'),

                  if (room.professorEmail != null)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri(
                            scheme: 'mailto', path: room.professorEmail);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      child: _profRow(
                        Icons.mail_outline_rounded,
                        room.professorEmail!,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _primary,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                ]),
          ),
        ],

        // ── ACTION BUTTONS ───────────────────────────────────────────────
        const SizedBox(height: 10),
        Row(children: [
          _Btn(
              i: Icons.directions_rounded,
              l: 'Directions',
              isActive: false,
              onTap: widget.onDirections),
          const SizedBox(width: 8),
          _Btn(
              i: Icons.share_outlined,
              l: 'Share',
              isActive: _isShareActive,
              onTap: () async {
                setState(() => _isShareActive = true);
                await Share.share(
                    'Check out ${room.name} (Room ${room.number}) '
                        'at ${room.building}');
                if (mounted) setState(() => _isShareActive = false);
              }),
          const SizedBox(width: 8),
          _Btn(
              i: widget.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              l: widget.isSaved ? 'Saved' : 'Save',
              isActive: widget.isSaved,
              onTap: widget.onSave),
        ]),

        const SizedBox(height: 14),
        Container(height: 0.5, color: _border),
      ]),
    );
  }

  Widget _profRow(IconData icon, String value, {TextStyle? style}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 13, color: _muted),
          const SizedBox(width: 6),
          Expanded(child: Text(
              value,
              style: style ??
                  GoogleFonts.poppins(fontSize: 11, color: _muted),
              overflow: TextOverflow.ellipsis)),
        ]),
      );
}


class _Btn extends StatelessWidget {
  final IconData i; final String l; final bool isActive; final VoidCallback onTap;
  const _Btn({required this.i, required this.l, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: isActive ? const Color(0xFF007A6E) : Colors.white, borderRadius: BorderRadius.circular(9999),
              border: isActive ? null : Border.all(color: const Color(0xFFE5EBEB))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 16, color: isActive ? Colors.white : const Color(0xFF6B7B7A)), const SizedBox(width: 4),
            Text(l, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF6B7B7A)))])));
}