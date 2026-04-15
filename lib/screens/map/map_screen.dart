import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../data/rooms.dart';
import '../../services/beacon_service.dart';

const _teal = Color(0xFF1ABC9C);
const _tealDk = Color(0xFF16A085);
const _darkCard = Color(0xFF1C2B2A);
const _textDk = Color(0xFF2C3E50);
const _textGy = Color(0xFFBDC3C7);

class MapScreen extends StatefulWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onSearchTap;
  // Add callback so tapping "Get Directions" navigates to room detail
  final ValueChanged<String>? onRoomSelected;

  const MapScreen({
    super.key,
    required this.onTabChange,
    required this.onSearchTap,
    this.onRoomSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  int _selectedFloor = 4;
  _MapRoom? _selectedRoom;

  late AnimationController _sheetCtrl;
  late Animation<double> _sheetAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Room pins positioned on the map — normalized 0..1 coords
  // These approximate positions on the campus_map.png for visual placement
  static final List<_MapRoom> _floor4Rooms = [
    // Elevator area
    _MapRoom('420', 'Office', 0.28, 0.32, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('421', 'Office', 0.22, 0.28, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('422', 'Office', 0.18, 0.24, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('423', 'Office', 0.14, 0.20, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    // Main corridor right
    _MapRoom('401', 'Office', 0.38, 0.28, const Color(0xFF8B5CF6), Icons.business_outlined),
    _MapRoom('402', 'Office', 0.46, 0.28, const Color(0xFF8B5CF6), Icons.business_outlined),
    _MapRoom('403', 'Office', 0.52, 0.28, const Color(0xFF8B5CF6), Icons.business_outlined),
    _MapRoom('404', 'Office', 0.58, 0.28, const Color(0xFF8B5CF6), Icons.business_outlined),
    _MapRoom('408', 'CS Lab', 0.72, 0.34, const Color(0xFFE74C3C), Icons.computer_outlined),
    _MapRoom('406', 'Conference', 0.78, 0.44, const Color(0xFFF59E0B), Icons.groups_outlined),
    _MapRoom('407', 'Classroom', 0.82, 0.50, const Color(0xFFF59E0B), Icons.class_outlined),
    // Corridor bottom
    _MapRoom('416', 'Office', 0.58, 0.42, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('417', 'Office', 0.52, 0.42, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('418', 'Office', 0.46, 0.42, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('419', 'Office', 0.38, 0.42, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    // 409-415 split
    _MapRoom('409', 'Office', 0.66, 0.50, const Color(0xFF007A6E), Icons.meeting_room_outlined),
    _MapRoom('410', 'Office', 0.62, 0.58, const Color(0xFF007A6E), Icons.meeting_room_outlined),
    _MapRoom('411', 'Office', 0.68, 0.58, const Color(0xFF007A6E), Icons.meeting_room_outlined),
    _MapRoom('412', 'Office', 0.74, 0.58, const Color(0xFF007A6E), Icons.meeting_room_outlined),
    // Left offices
    _MapRoom('424', 'Office', 0.14, 0.40, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('425', 'Office', 0.14, 0.48, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('426', 'Office', 0.14, 0.54, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('427', 'Office', 0.14, 0.60, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('428', 'Office', 0.14, 0.66, const Color(0xFFEC4899), Icons.business_outlined),
  ];

  static final List<_MapRoom> _floor5Rooms = [
    _MapRoom('522', "Dean's Office", 0.32, 0.30, const Color(0xFF185FA5), Icons.business_outlined),
    _MapRoom('501', 'Computer Lab', 0.42, 0.28, const Color(0xFF8B5CF6), Icons.desktop_windows_outlined),
    _MapRoom('502', 'Classroom', 0.50, 0.28, const Color(0xFFF59E0B), Icons.class_outlined),
    _MapRoom('503', 'Classroom', 0.58, 0.28, const Color(0xFFF59E0B), Icons.class_outlined),
    _MapRoom('511', 'Lab', 0.72, 0.34, const Color(0xFFE74C3C), Icons.science_outlined),
    _MapRoom('516', 'Journalism Lab', 0.82, 0.56, const Color(0xFFEC4899), Icons.mic_outlined),
    _MapRoom('520', 'Computer Lab', 0.50, 0.42, const Color(0xFF8B5CF6), Icons.desktop_windows_outlined),
    _MapRoom('512', 'Office', 0.76, 0.46, const Color(0xFF007A6E), Icons.meeting_room_outlined),
    _MapRoom('513', 'Office', 0.80, 0.50, const Color(0xFF007A6E), Icons.meeting_room_outlined),
    _MapRoom('504', 'Office', 0.66, 0.50, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    _MapRoom('507', 'Office', 0.74, 0.62, const Color(0xFF5B8DB8), Icons.meeting_room_outlined),
    // Left offices
    _MapRoom('525', 'Office', 0.24, 0.28, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('524', 'Office', 0.20, 0.24, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('523', 'Office', 0.16, 0.20, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('526', 'Office', 0.14, 0.40, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('527', 'Office', 0.14, 0.48, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('528', 'Office', 0.14, 0.54, const Color(0xFFEC4899), Icons.business_outlined),
    _MapRoom('529', 'Office', 0.14, 0.60, const Color(0xFFEC4899), Icons.business_outlined),
  ];

  List<_MapRoom> get _currentRooms =>
      _selectedFloor == 4 ? _floor4Rooms : _floor5Rooms;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _sheetAnim = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.2).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onPinTap(_MapRoom room) {
    setState(() => _selectedRoom = room);
    _sheetCtrl.forward(from: 0);
  }

  void _closeSheet() {
    _sheetCtrl.reverse().then((_) {
      if (mounted) setState(() => _selectedRoom = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final beaconSvc = context.watch<BeaconService>();
    final mapHeight = size.height - 64; // minus bottom tab bar

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── MAP BACKGROUND ────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 64,
            child: Image.asset(
              'assets/images/campus_map.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFEEF2F3)),
            ),
          ),

          // Light wash
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 64,
            child: Container(color: Colors.white.withValues(alpha: 0.08)),
          ),

          // ── ROOM PINS ─────────────────────────────────────
          ...(_currentRooms.map((room) {
            final isSelected = _selectedRoom?.number == room.number;
            final pinLeft = size.width * room.x - 18;
            final pinTop = mapHeight * room.y - 18;

            return Positioned(
              left: pinLeft,
              top: pinTop,
              child: GestureDetector(
                onTap: () => _onPinTap(room),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring when selected
                        if (isSelected)
                          Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: room.color.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                        // Pin circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 40 : 36,
                          height: isSelected ? 40 : 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? room.color
                                : room.color.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: room.color.withValues(alpha: 0.35),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            room.icon,
                            color: Colors.white,
                            size: isSelected ? 18 : 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          })),

          // ── CURRENT LOCATION DOT ──────────────────────────
          if (beaconSvc.currentBeacon != null &&
              beaconSvc.currentFloor == _selectedFloor)
            Positioned(
              left: size.width * 0.30 - 10,
              top: mapHeight * 0.35 - 10,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _teal.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: _teal, width: 2.5),
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _teal),
                    ),
                  ],
                ),
              ),
            ),

          // ── TOP BAR (search + logo + floor toggle) ────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.scaleDown,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.navigation_rounded,
                              color: _teal,
                              size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Search bar
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onSearchTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withValues(alpha: 0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: _textGy, size: 18),
                              const SizedBox(width: 8),
                              Text('Search rooms...',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _textGy)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FLOOR TOGGLE (bottom-left, above tab bar) ─────
          Positioned(
            bottom: 80,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [4, 5].map((f) {
                  final active = f == _selectedFloor;
                  return GestureDetector(
                    onTap: () {
                      _closeSheet();
                      setState(() => _selectedFloor = f);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      margin: EdgeInsets.only(
                          bottom: f == 4 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: active ? _teal : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'F$f',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : const Color(0xFF6B7B7A),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── MY LOCATION BUTTON (bottom-right) ─────────────
          Positioned(
            bottom: 80,
            right: 16,
            child: GestureDetector(
              onTap: () => beaconSvc.detectCurrentLocation(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location,
                    color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── ROOM DETAIL BOTTOM SHEET ──────────────────────
          if (_selectedRoom != null)
            Positioned(
              bottom: 64,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _sheetAnim,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(0, 300 * (1 - _sheetAnim.value)),
                    child: Opacity(
                      opacity: _sheetAnim.value.clamp(0.0, 1.0),
                      child: _RoomDetailSheet(
                        room: _selectedRoom!,
                        floor: _selectedFloor,
                        onClose: _closeSheet,
                        onGetDirections: () {
                          if (widget.onRoomSelected != null) {
                            widget.onRoomSelected!(_selectedRoom!.number);
                          } else {
                            widget.onSearchTap();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── MINI LABEL when no room selected ──────────────
          if (_selectedRoom == null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    'Nicol Hall · Floor $_selectedFloor · ${_currentRooms.length} rooms',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textDk),
                  ),
                ),
              ),
            ),

          // ── BOTTOM TAB BAR ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomTabBar(
                currentIndex: 2, onTap: widget.onTabChange),
          ),
        ],
      ),
    );
  }
}

// ── Room detail bottom sheet (dark card like the design) ─
class _RoomDetailSheet extends StatelessWidget {
  final _MapRoom room;
  final int floor;
  final VoidCallback onClose;
  final VoidCallback onGetDirections;

  const _RoomDetailSheet({
    required this.room,
    required this.floor,
    required this.onClose,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    final fullRoom = getRoomByNumber(room.number);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pin icon overlapping top
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: room.color,
                shape: BoxShape.circle,
                border: Border.all(color: _darkCard, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: room.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(room.icon, color: Colors.white, size: 24),
            ),
          ),

          // Close button (top-right)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 0),
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white54, size: 16),
                ),
              ),
            ),
          ),

          // Room name
          Transform.translate(
            offset: const Offset(0, -16),
            child: Column(
              children: [
                Text(
                  fullRoom?.name ?? 'Room ${room.number}',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Room ${room.number} · Nicol Hall',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),

          // Info rows
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              children: [
                Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Floor',
                  value: 'Floor $floor',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Category',
                  value: fullRoom?.category ?? room.category,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Distance',
                  value: '~30m from you',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Get Directions button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GestureDetector(
              onTap: onGetDirections,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Get Directions',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row inside the dark card ────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.white54)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }
}

// ── Map room data model ─────────────────────────────────
class _MapRoom {
  final String number;
  final String category;
  final double x; // normalized 0..1
  final double y; // normalized 0..1
  final Color color;
  final IconData icon;

  const _MapRoom(
      this.number, this.category, this.x, this.y, this.color, this.icon);
}