import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

  late AnimationController _pulseCtrl, _sheetCtrl;
  late Animation<double> _pulseAnim, _sheetAnim;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);

  // Elevator position
  static const _elevator = Offset(0.42, 0.22);

  // ── FLOOR 4 ROOM POSITIONS ────────────────────────────
  static const Map<String, Offset> _f4Rooms = {
    // LEFT CORRIDOR — vertical track x≈0.22, spaced evenly downward
    '424': Offset(0.12, 0.32),
    '425': Offset(0.12, 0.37),
    '426': Offset(0.12, 0.42),
    '427': Offset(0.12, 0.47),
    '428': Offset(0.12, 0.52),
    '429': Offset(0.12, 0.57),
    '430': Offset(0.12, 0.62),

    // NEAR ELEVATOR — below elevator, along center line going down
    '423': Offset(0.22, 0.32),
    '422': Offset(0.32, 0.32),
    '421': Offset(0.42, 0.32),
    '420': Offset(0.52, 0.32),

    // MAIN CORRIDOR — RIGHT vertical track
    // LEFT side of corridor (rooms on left when walking from elevator)
    '401': Offset(0.62, 0.32),
    '402': Offset(0.62, 0.40),
    '403': Offset(0.62, 0.48),
    '404': Offset(0.62, 0.55),

    // RIGHT side of corridor
    '419': Offset(0.72, 0.32),
    '418': Offset(0.72, 0.40),
    '417': Offset(0.72, 0.48),
    '416': Offset(0.72, 0.55),

    // 408 JUNCTION — where lower arrows are
    '408': Offset(0.60, 0.68),

    // BOTTOM LEFT SPLIT — horizontal track, going left from junction
    '409': Offset(0.48, 0.68),
    '415': Offset(0.38, 0.68),
    '414': Offset(0.28, 0.68),
    '413': Offset(0.18, 0.68),
    '410': Offset(0.48, 0.75),
    '411': Offset(0.38, 0.75),
    '412': Offset(0.28, 0.75),

    // BOTTOM RIGHT SPLIT — horizontal track, going right from junction
    '406': Offset(0.72, 0.68),
    '407': Offset(0.82, 0.68),
  };

  // ── FLOOR 5 ROOM POSITIONS ────────────────────────────
  static const Map<String, Offset> _f5Rooms = {
    // LEFT CORRIDOR
    '526': Offset(0.12, 0.32),
    '527': Offset(0.12, 0.37),
    '528': Offset(0.12, 0.42),
    '529': Offset(0.12, 0.47),

    // NEAR ELEVATOR
    '525': Offset(0.22, 0.32),
    '524': Offset(0.32, 0.32),
    '523': Offset(0.42, 0.32),
    '522': Offset(0.52, 0.32),

    // MAIN CORRIDOR LEFT
    '501': Offset(0.62, 0.32),
    '502': Offset(0.62, 0.42),
    '503': Offset(0.62, 0.52),

    // MAIN CORRIDOR RIGHT
    '521': Offset(0.72, 0.32),
    '520': Offset(0.72, 0.42),

    // 511 JUNCTION
    '511': Offset(0.58, 0.68),

    // BOTTOM RIGHT SPLIT — offices 504-510
    '504': Offset(0.70, 0.68),
    '510': Offset(0.70, 0.75),
    '509': Offset(0.80, 0.75),
    '505': Offset(0.80, 0.68),
    '506': Offset(0.90, 0.68),
    '508': Offset(0.90, 0.75),
    '507': Offset(0.95, 0.72),

    // BOTTOM LEFT SPLIT — offices 512-516
    '512': Offset(0.46, 0.68),
    '519': Offset(0.46, 0.75),
    '513': Offset(0.36, 0.68),
    '514': Offset(0.26, 0.68),
    '518': Offset(0.36, 0.75),
    '517': Offset(0.26, 0.75),
    '515': Offset(0.16, 0.68),
    '516': Offset(0.10, 0.72),
  };

  // ── CORRIDOR PATHS (transparent lines) ────────────────
  static const List<List<Offset>> _corridors4 = [
    // Elevator to left corridor
    [Offset(0.42, 0.22), Offset(0.22, 0.22)],
    // Left corridor vertical
    [Offset(0.22, 0.22), Offset(0.22, 0.64)],
    // Elevator down to near-elevator rooms
    [Offset(0.42, 0.22), Offset(0.42, 0.30)],
    // Near-elevator horizontal
    [Offset(0.32, 0.30), Offset(0.52, 0.30)],
    // Main corridor LEFT vertical
    [Offset(0.36, 0.30), Offset(0.36, 0.55)],
    // Main corridor RIGHT vertical
    [Offset(0.52, 0.30), Offset(0.52, 0.55)],
    // Main corridor to 408 junction
    [Offset(0.36, 0.55), Offset(0.44, 0.60)],
    [Offset(0.52, 0.55), Offset(0.44, 0.60)],
    // 408 to LEFT split
    [Offset(0.44, 0.60), Offset(0.36, 0.68)],
    [Offset(0.12, 0.68), Offset(0.36, 0.68)],
    [Offset(0.20, 0.68), Offset(0.20, 0.75)],
    [Offset(0.28, 0.68), Offset(0.28, 0.75)],
    [Offset(0.36, 0.68), Offset(0.36, 0.75)],
    // 408 to RIGHT split
    [Offset(0.44, 0.60), Offset(0.56, 0.68)],
    [Offset(0.56, 0.68), Offset(0.64, 0.68)],
  ];

  static const List<List<Offset>> _corridors5 = [
    // Elevator to left corridor
    [Offset(0.42, 0.22), Offset(0.22, 0.22)],
    // Left corridor vertical
    [Offset(0.22, 0.22), Offset(0.22, 0.46)],
    // Elevator down
    [Offset(0.42, 0.22), Offset(0.42, 0.30)],
    // Near-elevator horizontal
    [Offset(0.32, 0.30), Offset(0.52, 0.30)],
    // Main corridor LEFT
    [Offset(0.36, 0.30), Offset(0.36, 0.50)],
    // Main corridor RIGHT
    [Offset(0.52, 0.30), Offset(0.52, 0.45)],
    // To 511 junction
    [Offset(0.36, 0.50), Offset(0.44, 0.60)],
    [Offset(0.52, 0.45), Offset(0.44, 0.60)],
    // 511 to LEFT split
    [Offset(0.44, 0.60), Offset(0.36, 0.68)],
    [Offset(0.12, 0.75), Offset(0.36, 0.68)],
    [Offset(0.20, 0.68), Offset(0.20, 0.75)],
    [Offset(0.28, 0.68), Offset(0.28, 0.75)],
    [Offset(0.36, 0.68), Offset(0.36, 0.75)],
    // 511 to RIGHT split
    [Offset(0.44, 0.60), Offset(0.56, 0.68)],
    [Offset(0.56, 0.68), Offset(0.88, 0.68)],
    [Offset(0.56, 0.68), Offset(0.56, 0.75)],
    [Offset(0.64, 0.68), Offset(0.64, 0.75)],
    [Offset(0.72, 0.68), Offset(0.72, 0.75)],
    [Offset(0.80, 0.75), Offset(0.88, 0.75)],
  ];

  // Beacon screen positions
  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.42, 0.32),  // F4 Elevator
    'E5:65:DD:D0:91:EC': Offset(0.60, 0.68),  // F4 Room 408
    'C8:93:08:09:B2:CA': Offset(0.12, 0.42),  // F4 Room 426 area
    'F4:7B:74:76:D5:8A': Offset(0.42, 0.32),  // F5 Elevator
    'C7:A4:5A:D0:74:D8': Offset(0.58, 0.68),  // F5 Room 511
    'F3:55:BD:A3:65:2E': Offset(0.12, 0.37),  // F5 Room 527 area
  };

  Offset get _userPos {
    final b = context.read<BeaconService>().currentBeacon;
    if (b == null) return _elevator;
    return _beaconPos[b.mac] ?? _elevator;
  }

  List<RoomModel> get _floorRooms =>
      RoomsService().allRooms.where((r) => r.floor == _selectedFloor && r.active).toList();

  List<RoomModel> get _categoryRooms {
    if (_activeCategory == null) return [];
    return RoomsService().allRooms.where((r) {
      // 1. Filter by Category
      bool matchCat = false;
      switch (_activeCategory) {
        case 'Labs': matchCat = r.category == 'Lab'; break;
        case 'Offices': matchCat = r.category == 'Office'; break;
        case 'Classrooms': matchCat = r.category == 'Classroom' || r.category == 'Conference'; break;
      }

      // 2. Filter by Floor (if selected)
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
  void _closeCategory() { setState(() => _activeCategory = null); }

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
    final corridors = _selectedFloor == 4 ? _corridors4 : _corridors5;

    if (beacon != null && beacon.floor != _selectedFloor && _activeCategory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _selectedFloor = beacon.floor); });
    }

    return Scaffold(
      body: Stack(children: [
        // ── MAP ─────────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_tappedRoom != null) _closeSheet();
            },
            child: Image.asset(
              'assets/images/campus_map.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _bg),
            ),
          ),
        ),

        // ── CORRIDOR PATHS ──────────────────────────────
        Positioned.fill(child: CustomPaint(painter: _CorridorPainter(corridors: corridors, highlighted: null))),

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
                  child: Text(room.number,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? Colors.white : _text)),
                ),
              ),
            ),
          );
        }),

        // ── LOCATION PIN ────────────────────────────────
        if (beacon != null)
          Positioned(left: size.width * pos.dx - 18, top: size.height * pos.dy - 40,
              child: AnimatedBuilder(animation: _pulseAnim,
                  builder: (_, __) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    Transform.scale(scale: _pulseAnim.value,
                        child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.10)))),
                    Image.asset('assets/images/pin1.png', width: 40, height: 40, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(width: 16, height: 16,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _primary, width: 3)))),
                  ]))),

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
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: _activeCategory != null ? FontWeight.w600 : FontWeight.w500,
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
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))))),                    ])),
              ),
            ),
          ),
        ),

        // ── CATEGORY CHIPS ──────────────────────────────
        if (_activeCategory == null)
          Positioned(top: 10, left: 0, right: 5,
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
        if (_activeCategory == null)Positioned(bottom: 75, left: 16,
            child: Container(padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))]),
                child: Column(mainAxisSize: MainAxisSize.min,
                    children: [4, 5].map((f) {
                      final active = f == _selectedFloor;
                      return GestureDetector(
                          onTap: () {
                            _closeSheet(); // Close any open room card
                            setState(() {
                              _selectedFloor = f;
                              // If a room was selected on the other floor, deselect it
                              if (_tappedRoom?.floor != f) _tappedRoom = null;
                            });
                          },
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

        // ── CATEGORY SHEET ──────────────────────────────
        if (_activeCategory != null) _buildCategorySheet(size),

        // ── BOTTOM NAV ──────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0,
            child: AppBottomTabBar(currentIndex: 0, onTap: (i) {
              if (i == 1) widget.onSavedTap();
              if (i == 2) widget.onProfileTap();
            })),
      ]),
    );
  }

  Widget _buildPinCard() {
    final room = _tappedRoom!;

    // 1. Get room position and current user position
    final roomPos = _getRoomPos(room.number);
    final userPos = _userPos; // Uses your existing _userPos logic

    // 2. Calculate Distance
    // Since coordinates are roughly 0.0 to 1.0, we scale by 100
    // to get a representative "meter" value.
    final dx = roomPos.dx - userPos.dx;
    final dy = roomPos.dy - userPos.dy;
    final distanceInUnits = math.sqrt(dx * dx + dy * dy);
    final distanceInMeters = (distanceInUnits * 100).toStringAsFixed(0);

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4)
              )
            ]
        ),
        child: Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: Center(
                  child: Text(room.number,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primary
                      )
                  )
              )
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(room.name,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _text
                        )
                    ),
                    // Added distance here
                    Text(
                        '${room.category} · Floor ${room.floor} · $distanceInMeters m',
                        style: GoogleFonts.poppins(fontSize: 11, color: _muted)
                    ),
                  ]
              )
          ),
          GestureDetector(
              onTap: () {
                _closeSheet();
                widget.onNavigateToRoom(room.number);
              },
              child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: const Icon(Icons.directions_rounded, color: Colors.white, size: 20)
              )
          ),
        ])
    );
  }

  // ── CATEGORY SHEET ──────────────────────────────
  Widget _buildCategorySheet(Size size) {
    final rooms = _categoryRooms;
    final userPos = _userPos;

    return Positioned(
      // We keep bottom at 0 because the DraggableScrollableSheet
      // already has internal padding/margin constraints
      top: 0, left: 0, right: 0, bottom: 65,
      child: DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25, // INCREASED this to prevent the overflow
        maxChildSize: 0.95,
        snap: true,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              children: [
                // 1. THE DRAG HANDLE (Wrapped to ensure it is always the drag target)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                // 2. HEADER & CHIPS (Wrapped in a non-scrollable column)
                // We use Column instead of ListView for the header to avoid nested scroll issues
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(_activeCategory!, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(onPressed: _closeCategory, icon: const Icon(Icons.close))
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
                              child: _filterChip(null, 'Floor 4', _categoryFloorFilter == 4),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _categoryFloorFilter = 5),
                              child: _filterChip(null, 'Floor 5', _categoryFloorFilter == 5),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _categoryFloorFilter = null),
                              child: _filterChip(null, 'All floors', _categoryFloorFilter == null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. ROOM LIST (Using the scrollCtrl provided by the sheet)
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final roomPos = _getRoomPos(room.number);

                      final dx = roomPos.dx - userPos.dx;
                      final dy = roomPos.dy - userPos.dy;
                      final distance = (math.sqrt(dx * dx + dy * dy) * 100).toStringAsFixed(0);

                      // Inside your ListView.builder in _buildCategorySheet
                      final appState = context.watch<AppState>();

                      return _CategoryRoomCard(
                        room: room,
                        distance: distance,
                        isSaved: appState.isRoomSaved(room.number),
                        onDirections: () {
                          widget.onNavigateToRoom(room.number);
                        },
                        onSave: () {
                          appState.toggleSavedRoom(room.number);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isCategoryMatch(RoomModel room) {
    switch (_activeCategory) {
      case 'Labs': return room.category == 'Lab';
      case 'Offices': return room.category == 'Office';
      case 'Classrooms': return room.category == 'Classroom' || room.category == 'Conference';
      default: return false;
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

// ═══════════════════════════════════════════════════════
// CORRIDOR PAINTER
// ═══════════════════════════════════════════════════════

class _CorridorPainter extends CustomPainter {
  final List<List<Offset>> corridors;
  final List<int>? highlighted;
  const _CorridorPainter({required this.corridors, this.highlighted});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF007A6E).withValues(alpha: 0.10)..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final hi = Paint()..color = const Color(0xFF007A6E).withValues(alpha: 0.6)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (int i = 0; i < corridors.length; i++) {
      final s = corridors[i];
      canvas.drawLine(Offset(size.width * s[0].dx, size.height * s[0].dy), Offset(size.width * s[1].dx, size.height * s[1].dy),
          highlighted != null && highlighted!.contains(i) ? hi : base);
    }
  }
  @override
  bool shouldRepaint(_CorridorPainter old) => old.corridors != corridors || old.highlighted != highlighted;
}

// ═══════════════════════════════════════════════════════
// CATEGORY CARD + ACTION BUTTON
// ═══════════════════════════════════════════════════════
class _CategoryRoomCard extends StatefulWidget {
  final RoomModel room;
  final String distance;
  final bool isSaved; // This comes from appState.isRoomSaved(room.number)
  final VoidCallback onDirections;
  final VoidCallback onSave;

  const _CategoryRoomCard({
    super.key,
    required this.room,
    required this.distance,
    required this.isSaved,
    required this.onDirections,
    required this.onSave,
  });

  @override
  State<_CategoryRoomCard> createState() => _CategoryRoomCardState();
}

class _CategoryRoomCardState extends State<_CategoryRoomCard> {
  bool _isDirectionsActive = false;
  bool _isShareActive = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.room.name,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1C2B2A))),
          const SizedBox(height: 2),
          Text('${widget.room.category} · Room ${widget.room.number} · Floor ${widget.room.floor}',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7B7A))),
          const SizedBox(height: 3),
          Text('${widget.distance} m · ${widget.room.building}',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF007A6E))),
          const SizedBox(height: 10),
          Row(children: [
            // DIRECTIONS: Stays green when active
            _Btn(
              i: Icons.directions_rounded,
              l: 'Directions',
              isActive: _isDirectionsActive,
              onTap: () {
                setState(() => _isDirectionsActive = true);
                widget.onDirections();
              },
            ),
            const SizedBox(width: 8),

            // SHARE: Green only while sharing, then returns to white
            _Btn(
              i: Icons.share_outlined,
              l: 'Share',
              isActive: _isShareActive,
              onTap: () async {
                setState(() => _isShareActive = true);
                // Wait for the system share sheet to close
                await Share.share(
                    'Check out ${widget.room.name} (Room ${widget.room.number}) at ${widget.room.building}');
                if (mounted) setState(() => _isShareActive = false);
              },
            ),
            const SizedBox(width: 8),

            // SAVE: Stay green if isSaved is true, white if false
            _Btn(
              i: widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              l: widget.isSaved ? 'Saved' : 'Save',
              isActive: widget.isSaved, // Uses the boolean from AppState
              onTap: widget.onSave, // Calls toggleSavedRoom in AppState
            ),
          ]),
          const SizedBox(height: 14),
          Container(height: 0.5, color: const Color(0xFFE5EBEB))
        ]));
  }
}

class _Btn extends StatelessWidget {
  final IconData i;
  final String l;
  final bool isActive;
  final VoidCallback onTap;

  const _Btn({required this.i, required this.l, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF007A6E) : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: isActive ? null : Border.all(color: const Color(0xFFE5EBEB)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 16, color: isActive ? Colors.white : const Color(0xFF6B7B7A)),
          const SizedBox(width: 4),
          Text(l,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF6B7B7A))),
        ]),
      ),
    );
  }
}