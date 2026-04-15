import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/beacon_service.dart';
import '/services/navigation_service.dart';
import '/data/rooms.dart';

class NavigationScreen extends StatefulWidget {
  final String roomNumber;
  final VoidCallback onClose;
  final VoidCallback onNewDestination;
  const NavigationScreen({super.key, required this.roomNumber, required this.onClose, required this.onNewDestination});
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

enum _NavState { loading, preview, active, arrived }

class _NavigationScreenState extends State<NavigationScreen> with TickerProviderStateMixin {
  _NavState _state = _NavState.loading;
  NavigationResult? _result;
  int _step = 0;
  String? _error;

  late AnimationController _pulseCtrl, _routeCtrl;
  late Animation<double> _pulseAnim, _routeAnim;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);
  static const _red = Color(0xFFEF4444);
  static const _routeBlue = Color(0xFF3B78C6);

  // Beacon positions on map (same as HomeScreen)
  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.28, 0.32),
    'E5:65:DD:D0:91:EC': Offset(0.68, 0.36),
    'C8:93:08:09:B2:CA': Offset(0.14, 0.48),
    'FC:17:8A:61:EC:6D': Offset(0.28, 0.32),
    'F3:55:BD:A3:65:2E': Offset(0.14, 0.48),
    'C7:A4:5A:D0:74:D8': Offset(0.68, 0.36),
  };

  // Room pins (same as HomeScreen)
  static const Map<String, Offset> _roomPositions = {
    // Floor 4
    '408': Offset(0.68, 0.36), '406': Offset(0.78, 0.44),
    '401': Offset(0.40, 0.30), '420': Offset(0.32, 0.26),
    '416': Offset(0.56, 0.44), '424': Offset(0.14, 0.42),
    '427': Offset(0.14, 0.56), '409': Offset(0.62, 0.52),
    '412': Offset(0.72, 0.56), '402': Offset(0.48, 0.30),
    '403': Offset(0.54, 0.30), '404': Offset(0.60, 0.30),
    '407': Offset(0.82, 0.50), '410': Offset(0.66, 0.58),
    '411': Offset(0.70, 0.58), '413': Offset(0.58, 0.52),
    '414': Offset(0.54, 0.52), '415': Offset(0.58, 0.48),
    '417': Offset(0.52, 0.44), '418': Offset(0.46, 0.44),
    '419': Offset(0.40, 0.44), '421': Offset(0.28, 0.26),
    '422': Offset(0.24, 0.26), '423': Offset(0.20, 0.26),
    '425': Offset(0.14, 0.48), '426': Offset(0.14, 0.52),
    '428': Offset(0.14, 0.60), '429': Offset(0.18, 0.64),
    '430': Offset(0.18, 0.68),
    // Floor 5
    '511': Offset(0.68, 0.36), '516': Offset(0.80, 0.54),
    '522': Offset(0.36, 0.30), '501': Offset(0.44, 0.30),
    '503': Offset(0.56, 0.30), '520': Offset(0.50, 0.44),
    '526': Offset(0.14, 0.42), '512': Offset(0.74, 0.46),
    '507': Offset(0.72, 0.60), '502': Offset(0.50, 0.30),
    '504': Offset(0.64, 0.52), '505': Offset(0.68, 0.56),
    '506': Offset(0.72, 0.56), '508': Offset(0.68, 0.62),
    '509': Offset(0.62, 0.56), '510': Offset(0.60, 0.52),
    '513': Offset(0.78, 0.50), '514': Offset(0.80, 0.54),
    '515': Offset(0.82, 0.58), '517': Offset(0.76, 0.58),
    '518': Offset(0.76, 0.54), '519': Offset(0.72, 0.50),
    '523': Offset(0.32, 0.26), '524': Offset(0.28, 0.26),
    '525': Offset(0.24, 0.26), '527': Offset(0.14, 0.48),
    '528': Offset(0.14, 0.52), '529': Offset(0.14, 0.56),
  };

  // Key rooms to show labels for (avoid clutter)
  static const _keyRooms = {
    '401','408','406','420','424','416','409','427',
    '501','511','516','522','520','526','503','507','512',
  };

  Offset get _originPos {
    final b = BeaconService().currentBeacon;
    if (b == null) return const Offset(0.28, 0.32);
    return _beaconPos[b.mac] ?? const Offset(0.28, 0.32);
  }

  Offset get _destPos => _roomPositions[widget.roomNumber] ?? const Offset(0.68, 0.36);
  int get _destFloor => widget.roomNumber.startsWith('5') ? 5 : 4;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.4).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _routeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _routeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _routeCtrl, curve: Curves.easeInOut));
    _loadRoute();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _routeCtrl.dispose(); BeaconService().stopContinuousScanning(); super.dispose(); }

  Future<void> _loadRoute() async {
    final svc = BeaconService();
    BeaconModel? b = svc.currentBeacon ?? await svc.detectCurrentLocation(durationSeconds: 5);
    const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) { setState(() { _state = _NavState.preview; _error = 'Demo mode'; }); _routeCtrl.forward(); return; }
    final result = await NavigationService().navigate(currentBeaconMac: b?.mac ?? 'C6:2A:90:A1:99:CB', currentFloor: b?.floor ?? 4, destinationNumber: widget.roomNumber, apiKey: apiKey);
    if (mounted) { setState(() { _result = result; _state = _NavState.preview; }); _routeCtrl.forward(); }
  }

  void _start() { setState(() => _state = _NavState.active); BeaconService().startContinuousScanning(); }
  void _next() { final t = _result?.path.length ?? 3; if (_step >= t - 1) { setState(() => _state = _NavState.arrived); BeaconService().stopContinuousScanning(); return; } setState(() => _step++); }
  void _prev() { if (_step > 0) setState(() => _step--); }

  IconData _dirIcon(String d) { switch (d.toLowerCase()) { case 'left': return Icons.turn_left_rounded; case 'right': return Icons.turn_right_rounded; case 'up': return Icons.north_rounded; case 'down': return Icons.south_rounded; default: return Icons.straight_rounded; } }
  String _dirLabel(String d) { switch (d.toLowerCase()) { case 'left': return 'Turn left'; case 'right': return 'Turn right'; case 'up': return 'Go upstairs'; case 'down': return 'Go downstairs'; default: return 'Go straight'; } }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final room = getRoomByNumber(widget.roomNumber);
    final beaconSvc = context.watch<BeaconService>();
    final beacon = beaconSvc.currentBeacon;
    final dist = _result?.totalDistanceMeters ?? 30;
    final time = _result?.estimatedTimeMinutes ?? 2;

    // Collect room pins for current destination floor
    final visibleRooms = _roomPositions.entries
        .where((e) => _destFloor == 4 ? !e.key.startsWith('5') : e.key.startsWith('5'))
        .where((e) => _keyRooms.contains(e.key) || e.key == widget.roomNumber)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // ── TOP HEADER (matches SearchScreen) ───────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + 8, 0, 0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back_rounded, color: _text, size: 22),
                    padding: const EdgeInsets.only(top: 10),
                  ),
                  // Origin + destination fields
                  Expanded(
                    child: Column(children: [
                      // Your location
                      Container(
                        height: 42,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
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
                      // Destination (filled)
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _primary)),
                        child: Row(children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: _red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              room?.name ?? 'Room ${widget.roomNumber}',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _text),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('F$_destFloor', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _muted)),
                        ]),
                      ),
                    ]),
                  ),
                  // Swap
                  IconButton(onPressed: () {}, icon: const Icon(Icons.swap_vert_rounded, color: _muted, size: 22), padding: const EdgeInsets.only(top: 20)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Mode tabs
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _ModeChip(Icons.directions_walk_rounded, 'Walk', true),
                const SizedBox(width: 8),
                _ModeChip(Icons.stairs_rounded, 'Stairs', false),
                const SizedBox(width: 8),
                _ModeChip(Icons.accessible_rounded, 'Accessible', false),
              ]),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: _border),
          ]),
        ),

        // ── MAP + BOTTOM CARD ───────────────────────────
        Expanded(
          child: Stack(children: [
            // Map background
            Positioned.fill(
              child: Image.asset('assets/images/campus_map.png', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: _bg)),
            ),

            // Route line
            if (_state != _NavState.loading)
              Positioned.fill(
                child: AnimatedBuilder(animation: _routeAnim,
                    builder: (_, __) => CustomPaint(
                        painter: _RoutePainter(
                          progress: _routeAnim.value,
                          origin: _originPos, dest: _destPos,
                          stepFrac: _state == _NavState.active ? (_step + 1) / (_result?.path.length ?? 3).clamp(1, 99) : 0,
                          isActive: _state == _NavState.active,
                        ))),
              ),

            // Room labels on map
            ...visibleRooms.map((e) {
              final isDest = e.key == widget.roomNumber;
              return Positioned(
                left: size.width * e.value.dx - 30,
                top: (size.height * 0.55) * e.value.dy - 14, // map takes remaining space
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDest ? _red : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDest ? 0.15 : 0.08), blurRadius: isDest ? 10 : 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isDest ? Colors.white : _primary)),
                    const SizedBox(width: 4),
                    Text(e.key, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: isDest ? Colors.white : _text)),
                  ]),
                ),
              );
            }),

            // Current location — pin.png
            if (beacon != null)
              Positioned(
                left: size.width * _originPos.dx - 18,
                top: (size.height * 0.55) * _originPos.dy - 36,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    Transform.scale(scale: _pulseAnim.value,
                        child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.10)))),
                    Image.asset('assets/images/pin.png', width: 36, height: 36, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(width: 36, height: 36,
                            decoration: BoxDecoration(color: _primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8)]),
                            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18))),
                  ]),
                ),
              ),

            // Destination drop pin
            Positioned(
              left: size.width * _destPos.dx - 14,
              top: (size.height * 0.55) * _destPos.dy - 40,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: _red, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]),
                    child: Center(child: Text(widget.roomNumber, style: GoogleFonts.poppins(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white)))),
                Container(width: 2, height: 8, color: _red),
                Container(width: 6, height: 3, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9999))),
              ]),
            ),

            // Time badge mid-route
            if (_state == _NavState.preview || _state == _NavState.active)
              Positioned(
                left: size.width * ((_originPos.dx + _destPos.dx) / 2) - 20,
                top: (size.height * 0.55) * ((_originPos.dy + _destPos.dy) / 2) - 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(9999),
                      boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 6)]),
                  child: Text('$time min', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),

            // Progress bar (active)
            if (_state == _NavState.active)
              Positioned(bottom: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                      value: (_step + 1) / (_result?.path.length ?? 3).clamp(1, 99),
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(_primary),
                      minHeight: 3)),

            // ── Bottom cards ────────────────────────────
            if (_state == _NavState.loading) _buildLoading(),
            if (_state == _NavState.preview) _buildPreview(room, dist, time),
            if (_state == _NavState.active) _buildActiveStep(room, beaconSvc),
            if (_state == _NavState.arrived) _buildArrived(room),
          ]),
        ),
      ]),
    );
  }

  // ── LOADING ───────────────────────────────────────────
  Widget _buildLoading() => Positioned(bottom: 0, left: 0, right: 0, height: 200,
      child: Container(decoration: _cardDeco(), child: const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5))));

  // ── ROUTE PREVIEW ─────────────────────────────────────
  Widget _buildPreview(RoomModel? room, int dist, int time) {
    return Positioned(bottom: 0, left: 0, right: 0,
        child: Container(decoration: _cardDeco(), padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),

              // Time + distance
              RichText(text: TextSpan(children: [
                TextSpan(text: '$time min ', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _primary)),
                TextSpan(text: '(${dist}m)', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w400, color: _text)),
              ])),
              const SizedBox(height: 2),
              Text('Indoor navigation via BLE beacons', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),

              if (_error != null) Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(_error!, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFF59E0B)))),

              const SizedBox(height: 16),

              // Start + Overview
              Row(children: [
                GestureDetector(onTap: _start,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(9999),
                            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.navigation_rounded, color: Colors.white, size: 18), const SizedBox(width: 6),
                          Text('Start', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]))),
                const SizedBox(width: 10),
                GestureDetector(onTap: () {},
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9999), border: Border.all(color: _border)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.map_outlined, size: 16, color: _muted), const SizedBox(width: 4),
                          Text('Overview', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
                        ]))),
              ]),
              const SizedBox(height: 16),
            ]))));
  }

  // ── ACTIVE STEP ───────────────────────────────────────
  Widget _buildActiveStep(RoomModel? room, BeaconService svc) {
    final has = _result != null && _result!.success && _result!.path.isNotEmpty;
    final total = has ? _result!.path.length : 3;
    final isLast = _step >= total - 1;
    NavigationStep? step;
    if (has && _step < _result!.path.length) step = _result!.path[_step];
    final instr = step?.instruction ?? ['Turn RIGHT from elevator', 'Walk straight', 'You have arrived!'][_step.clamp(0, 2)];
    final dir = step?.direction ?? 'forward';

    return Positioned(bottom: 0, left: 0, right: 0,
        child: Container(decoration: _cardDeco(), padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Progress dots
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) => Container(
                      width: i == _step ? 22 : 8, height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: i <= _step ? _primary : _border, borderRadius: BorderRadius.circular(9999))))),
              const SizedBox(height: 14),

              // Direction
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: isLast ? _primary : const Color(0xFFF0F7F6), borderRadius: BorderRadius.circular(12)),
                    child: Icon(isLast ? Icons.check_rounded : _dirIcon(dir), color: isLast ? Colors.white : _primary, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isLast ? "You're here!" : _dirLabel(dir),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isLast ? _primary : _text)),
                  const SizedBox(height: 2),
                  Text(instr, style: GoogleFonts.poppins(fontSize: 12, color: _muted, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                ])),
              ]),
              const SizedBox(height: 14),

              // Prev + Next
              Row(children: [
                if (_step > 0) GestureDetector(onTap: _prev,
                    child: Container(width: 48, height: 48,
                        decoration: BoxDecoration(border: Border.all(color: _border, width: 1.5), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _muted))),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(child: GestureDetector(onTap: _next,
                    child: Container(height: 48,
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                        child: Center(child: Text(isLast ? 'Done' : 'Next', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)))))),
              ]),
              const SizedBox(height: 14),
            ]))));
  }

  // ── ARRIVED ───────────────────────────────────────────
  Widget _buildArrived(RoomModel? room) => Center(
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40), padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 10))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 68, height: 68, decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 34)),
            const SizedBox(height: 16),
            Text("You've arrived!", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 4),
            Text(room?.name ?? 'Room ${widget.roomNumber}', style: GoogleFonts.poppins(fontSize: 13, color: _muted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(onTap: widget.onClose,
                child: Container(width: double.infinity, height: 46, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('Done', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))))),
            const SizedBox(height: 8),
            GestureDetector(onTap: widget.onNewDestination,
                child: Container(width: double.infinity, height: 46,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _border, width: 1.5)),
                    child: Center(child: Text('New destination', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _muted))))),
          ])));

  // ── Helpers ───────────────────────────────────────────
  BoxDecoration _cardDeco() => BoxDecoration(color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -6))]);
}

// ── Mode chip ───────────────────────────────────────────
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

// ── Route painter ───────────────────────────────────────
class _RoutePainter extends CustomPainter {
  final double progress; final Offset origin, dest; final double stepFrac; final bool isActive;
  const _RoutePainter({required this.progress, required this.origin, required this.dest, this.stepFrac = 0, this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width * origin.dx; final sy = size.height * origin.dy;
    final ex = size.width * dest.dx; final ey = size.height * dest.dy;
    final path = Path()..moveTo(sx, sy)..cubicTo(sx, sy + (ey - sy) * 0.5, ex - 20, ey, ex, ey);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.first.length;

    // Shadow
    canvas.drawPath(metrics.first.extractPath(0, total * progress),
        Paint()..color = const Color(0xFF3B78C6).withValues(alpha: 0.08)..strokeWidth = 10..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);

    if (isActive && stepFrac > 0) {
      final done = total * stepFrac * progress;
      canvas.drawPath(metrics.first.extractPath(0, done),
          Paint()..color = const Color(0xFF3B78C6)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
      final rem = metrics.first.extractPath(done, total);
      for (final m in rem.computeMetrics()) { double d = 0; while (d < m.length) { canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)),
          Paint()..color = const Color(0xFF3B78C6).withValues(alpha: 0.3)..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke); d += 12; } }
    } else {
      canvas.drawPath(metrics.first.extractPath(0, total * progress),
          Paint()..color = const Color(0xFF3B78C6).withValues(alpha: 0.8)..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.progress != progress || old.stepFrac != stepFrac;
}