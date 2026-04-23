import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '/services/beacon_service.dart';
import '/services/navigation_service.dart';
import '/data/rooms.dart';
import '/services/rooms_service.dart';

class NavigationScreen extends StatefulWidget {
  final String roomNumber;
  final VoidCallback onClose;
  final VoidCallback onNewDestination;
  const NavigationScreen({super.key, required this.roomNumber, required this.onClose, required this.onNewDestination});
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

enum _NavState { loading, preview, active, arrived, offRoute }

class _NavigationScreenState extends State<NavigationScreen> with TickerProviderStateMixin {
  _NavState _state = _NavState.loading;
  NavigationResult? _result;
  int _step = 0;
  String? _error;
  late int _currentFloor;
  String? _lastSpokenMac;
  int _offRouteCount = 0;
  int _gracePeriodSteps = 0;
  DateTime? _lastBeaconMatchTime;

  late AnimationController _pulseCtrl, _routeCtrl;
  late Animation<double> _pulseAnim, _routeAnim;

  List<Offset> _routeWaypoints = [];
  double _routeProgress = 0.0;
  int? _prevRssi;

  final FlutterTts _tts = FlutterTts();
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);
  static const _red = Color(0xFFEF4444);

  // Beacon positions matched to new map.png
  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.41, 0.28),
    'E5:65:DD:D0:91:EC': Offset(0.57, 0.55),
    'C8:93:08:09:B2:CA': Offset(0.25, 0.41),
    'F4:7B:74:76:D5:8A': Offset(0.41, 0.28),
    'C7:A4:5A:D0:74:D8': Offset(0.57, 0.55),
    'F3:55:BD:A3:65:2E': Offset(0.25, 0.38),
  };

  // Room positions matched to new map.png
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

  // ── CORRIDOR PATHS BETWEEN BEACONS (following the actual map corridors) ──
  // These trace the actual walking path through the corridors in the new map
  static const Map<String, List<Offset>> _corridorPaths = {
    // F4: Elevator → 408
    'C6:2A:90:A1:99:CB→E5:65:DD:D0:91:EC': [
      Offset(0.41, 0.28),
      Offset(0.65, 0.28),
      Offset(0.65, 0.55),
      Offset(0.57, 0.55),
    ],
    // F4: 408 → Elevator
    'E5:65:DD:D0:91:EC→C6:2A:90:A1:99:CB': [
      Offset(0.57, 0.55),
      Offset(0.65, 0.55),
      Offset(0.65, 0.28),
      Offset(0.41, 0.28),
    ],
    // F4: Elevator → Left Offices
    'C6:2A:90:A1:99:CB→C8:93:08:09:B2:CA': [
      Offset(0.41, 0.28),
      Offset(0.25, 0.28), // top-left corner — horizontal first
      Offset(0.25, 0.41), // then straight down to beacon
    ],
    // F4: Left Offices → Elevator
    'C8:93:08:09:B2:CA→C6:2A:90:A1:99:CB': [
      Offset(0.25, 0.41),
      Offset(0.25, 0.28),
      Offset(0.41, 0.28),
    ],
    // F5: Elevator → 511
    'F4:7B:74:76:D5:8A→C7:A4:5A:D0:74:D8': [
      Offset(0.41, 0.28),
      Offset(0.65, 0.28),
      Offset(0.65, 0.55),
      Offset(0.57, 0.55),
    ],
    // F5: 511 → Elevator
    'C7:A4:5A:D0:74:D8→F4:7B:74:76:D5:8A': [
      Offset(0.57, 0.55),
      Offset(0.65, 0.55),
      Offset(0.65, 0.28),
      Offset(0.41, 0.28),
    ],
    // F5: Elevator → Left Offices
    'F4:7B:74:76:D5:8A→F3:55:BD:A3:65:2E': [
      Offset(0.41, 0.28),
      Offset(0.25, 0.28), // horizontal first
      Offset(0.25, 0.38), // then down to beacon
    ],
    // F5: Left Offices → Elevator
    'F3:55:BD:A3:65:2E→F4:7B:74:76:D5:8A': [
      Offset(0.25, 0.38),
      Offset(0.25, 0.28),
      Offset(0.41, 0.28),
    ],
  };

  String _resolveDestinationName() {
    final room = RoomsService().getRoomByNumber(widget.roomNumber);
    if (room != null) return room.name;
    return 'Room ${widget.roomNumber}';
  }

  int get _destFloor => widget.roomNumber.startsWith('5') ? 5 : 4;
  Offset get _destPos => (_destFloor == 4 ? _f4Rooms : _f5Rooms)[widget.roomNumber] ?? const Offset(0.57, 0.55);
  Offset _beaconScreenPos(String mac) => _beaconPos[mac] ?? const Offset(0.41, 0.28);

  // Build corridor-accurate route waypoints from OpenAI steps
  void _buildRouteWaypoints() {
    _routeWaypoints = [];
    final destPos = _destPos;

    if (_result == null || !_result!.success || _result!.path.isEmpty) {
      final b = BeaconService().currentBeacon;
      _routeWaypoints = [b != null ? _beaconScreenPos(b.mac) : const Offset(0.41, 0.28), destPos];
      return;
    }

    final allSteps = _result!.path;
    final stairsIdx = allSteps.indexWhere((s) => s.beaconMac == 'STAIRS');

    List<NavigationStep> stepsToRender;
    if (stairsIdx < 0) {
      stepsToRender = allSteps;
    } else if (_currentFloor != _destFloor) {
      // On starting floor: draw from current beacon TO the stairs beacon
      stepsToRender = allSteps.sublist(0, stairsIdx);

      // If stepsToRender is empty (already at stairs beacon),
      // still draw a line from current position to stairs icon
      // REPLACE the starting-floor empty steps fallback:
      if (stepsToRender.isEmpty) {
        final b = BeaconService().currentBeacon;
        final startPos = b != null ? _beaconScreenPos(b.mac) : const Offset(0.41, 0.28);
        // Draw line from current position to stairs on THIS floor
        final stairsStep = allSteps[stairsIdx];
        final isMainStairs = stairsStep.location.toLowerCase().contains('main') ||
            stairsStep.location.toLowerCase().contains('elevator');
        final stairsPos = isMainStairs
            ? const Offset(0.41, 0.28)   // elevator/main stairs position
            : const Offset(0.57, 0.55);  // back stairs = 408/511 area
        _routeWaypoints = [startPos, stairsPos];
        return;
      }
    } else {
      stepsToRender = allSteps.sublist(stairsIdx + 1);
    }

    final steps = stepsToRender.where((s) => s.beaconMac != 'STAIRS').toList();
    if (steps.isEmpty) {
      final b = BeaconService().currentBeacon;
      _routeWaypoints = [b != null ? _beaconScreenPos(b.mac) : const Offset(0.41, 0.28), destPos];
      return;
    }

    _routeWaypoints.add(_beaconScreenPos(steps[0].beaconMac));

    for (int i = 0; i < steps.length; i++) {
      if (i < steps.length - 1) {
        final key = '${steps[i].beaconMac}→${steps[i+1].beaconMac}';
        final pts = _corridorPaths[key];
        if (pts != null) {
          for (int j = 1; j < pts.length; j++) _routeWaypoints.add(pts[j]);
        } else {
          _routeWaypoints.add(_beaconScreenPos(steps[i+1].beaconMac));
        }
      } else {
        _addDestinationPath(steps[i].beaconMac, widget.roomNumber, destPos);
      }
    }

    if (_routeWaypoints.isEmpty || _routeWaypoints.last != destPos) {
      _routeWaypoints.add(destPos);
    }
  }

// Returns where to draw the stairs icon on current floor map
  Offset _stairsIconPos(NavigationStep stairsStep) {
    // Primary stairs = elevator area, Secondary = 408/511 area
    if (stairsStep.location.toLowerCase().contains('main') ||
        stairsStep.location.toLowerCase().contains('elevator')) {
      return _currentFloor == 5
          ? const Offset(0.41, 0.28)  // F5 elevator
          : const Offset(0.41, 0.28); // F4 elevator
    }
    return _currentFloor == 5
        ? const Offset(0.57, 0.55)  // F5 back stairs = 511 area
        : const Offset(0.57, 0.55); // F4 back stairs = 408 area
  }

  // Add corridor waypoints from last beacon to destination room
  void _addDestinationPath(String fromMac, String dest, Offset destPos) {
    if (_destFloor == 4) {

      // ── TOP ROW: near elevator ──
      if (['420','421','422','423'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.41, 0.28),
          destPos,
        ]);

        // ── LEFT CORRIDOR: 424-430 ──
        // In the F4 section, REPLACE the 424-430 case:
      } else if (['424','425','426','427','428','429','430'].contains(dest)) {
        // LEFT OFFICES — must go back to elevator first, then left
        _routeWaypoints.addAll([
          const Offset(0.57, 0.55), // 408 junction
          const Offset(0.65, 0.55), // back up main corridor
          const Offset(0.65, 0.28), // top-right corner
          const Offset(0.41, 0.28), // elevator
          const Offset(0.25, 0.28), // top-left corner
          destPos,
        ]);

        // ── MAIN CORRIDOR RIGHT SIDE: 401-404 ──
      } else if (['401','402','403','404'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28), // top-right corner
          Offset(0.65, destPos.dy), // go down to room's row
          destPos,                  // enter room
        ]);

        // ── MAIN CORRIDOR LEFT SIDE: 419-416 ──
      } else if (['419','418','417','416'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          Offset(0.65, destPos.dy),
          destPos,
        ]);

        // ── TOILETS F4 (on main corridor) ──
      } else if (['4WC','4WC2'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          Offset(0.65, destPos.dy),
          destPos,
        ]);

        // ── 408 JUNCTION itself ──
      } else if (dest == '408') {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          const Offset(0.65, 0.55),
          destPos,
        ]);

        // ── LEFT of 408 junction: 406, 407 ──
      } else if (['406','407'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.57, 0.55), // 408 junction
          const Offset(0.44, 0.55), // go left along bottom corridor
          const Offset(0.44, 0.61), // turn down
          destPos,
        ]);

        // ── RIGHT of 408 junction: 409-415 ──
      } else if (['409','410','411','412','413','414','415'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.57, 0.55), // 408 junction
          const Offset(0.75, 0.55), // go right along bottom corridor
          Offset(0.75, destPos.dy), // go down to room's row
          destPos,
        ]);

      } else {
        _routeWaypoints.add(destPos);
      }

    } else {
      // ── FLOOR 5 ──────────────────────────────────────────────────

      // ── TOP ROW: near elevator ──
      if (['522','523','524','525'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.41, 0.28),
          destPos,
        ]);

        // ── LEFT CORRIDOR: 526-529 ──
        // In the F5 section, REPLACE the 526-529 case:
      } else if (['526','527','528','529'].contains(dest)) {
        // These are in LEFT OFFICES — must go back to elevator first, then left
        _routeWaypoints.addAll([
          const Offset(0.57, 0.55), // 511 junction
          const Offset(0.65, 0.55), // back up main corridor
          const Offset(0.65, 0.28), // top-right corner
          const Offset(0.41, 0.28), // elevator
          const Offset(0.25, 0.28), // top-left corner
          destPos,                  // down left offices corridor
        ]);

        // ── MAIN CORRIDOR RIGHT SIDE: 501-503 ──
      } else if (['501','502','503'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          Offset(0.65, destPos.dy),
          destPos,
        ]);

        // ── MAIN CORRIDOR LEFT SIDE: 521-520 ──
      } else if (['521','520'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          Offset(0.65, destPos.dy),
          destPos,
        ]);

        // ── TOILET 5WC (on main corridor right side) ──
      } else if (dest == '5WC') {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          Offset(0.65, destPos.dy),
          destPos,
        ]);

        // ── 511 JUNCTION itself ──
      } else if (dest == '511') {
        _routeWaypoints.addAll([
          const Offset(0.65, 0.28),
          const Offset(0.65, 0.55),
          destPos,
        ]);

        // ── LEFT of 511 junction: 504-510, 5WC2 ──
      } else if (['5WC2','504','505','506','507','508','509','510'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.57, 0.55), // 511 junction
          const Offset(0.44, 0.55), // go left along bottom corridor
          Offset(0.44, destPos.dy), // go down to room's row
          destPos,
        ]);

        // ── RIGHT of 511 junction: 512-519 ──
      } else if (['512','513','514','515','516','517','518','519'].contains(dest)) {
        _routeWaypoints.addAll([
          const Offset(0.57, 0.55), // 511 junction
          const Offset(0.75, 0.55), // go right along bottom corridor
          Offset(0.75, destPos.dy), // go down to room's row
          destPos,
        ]);

      } else {
        _routeWaypoints.add(destPos);
      }
    }
  }

  Offset _calcPinPos(BeaconService svc) {
    final b = svc.currentBeacon;
    if (b == null || _routeWaypoints.isEmpty) return _routeWaypoints.isNotEmpty ? _routeWaypoints.first : const Offset(0.41, 0.28);

    final currentPos = _beaconScreenPos(b.mac);
    final rssi = svc.currentRssi ?? -70;

    // Only update if RSSI changed meaningfully (>3 dBm threshold prevents jitter)
    if (_prevRssi == null || ((_prevRssi! - rssi).abs() > 3)) _prevRssi = rssi;
    final proximity = ((_prevRssi! + 90) / 60.0).clamp(0.0, 1.0);

    int idx = -1;
    for (int i = 0; i < _routeWaypoints.length; i++) {
      if (_routeWaypoints[i] == currentPos) { idx = i; break; }
    }
    if (idx < 0) return currentPos;
    if (idx >= _routeWaypoints.length - 1) { _routeProgress = 1.0; return currentPos; }

    final t = 1.0 - proximity; // 0 = at beacon, 1 = at next waypoint
    final next = _routeWaypoints[idx + 1];
    _routeProgress = ((idx + t) / (_routeWaypoints.length - 1)).clamp(0.0, 1.0);
    return Offset(currentPos.dx + (next.dx - currentPos.dx) * t, currentPos.dy + (next.dy - currentPos.dy) * t);
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    _currentFloor = _destFloor;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.4).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _routeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _routeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _routeCtrl, curve: Curves.easeInOut));
    _tts.setVolume(1.0);
    _loadRoute();
  }

  @override
  void dispose() { _tts.stop(); _pulseCtrl.dispose(); _routeCtrl.dispose(); _sheetCtrl.dispose(); BeaconService().stopContinuousScanning(); super.dispose(); }

  Future<void> _loadRoute() async {
    final svc = BeaconService();
    // Detect where the user is standing right now
    BeaconModel? b = svc.currentBeacon ?? await svc.detectCurrentLocation(durationSeconds: 5);

    const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      setState(() {
        _state = _NavState.preview;
        _error = 'Demo mode';
        _currentFloor = b?.floor ?? 4; // Show starting floor
      });
      _buildRouteWaypoints();
      _routeCtrl.forward();
      return;
    }

    final result = await NavigationService().navigate(
        currentBeaconMac: b?.mac ?? 'C6:2A:90:A1:99:CB',
        currentFloor: b?.floor ?? 4,
        destinationNumber: widget.roomNumber,
        apiKey: apiKey
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _state = _NavState.preview;
      // CRITICAL: Initialize the map to the user's STARTING floor
      _currentFloor = b?.floor ?? 4;
    });
    _buildRouteWaypoints();
    _routeCtrl.forward();
  }

  void _start() {
    setState(() => _state = _NavState.active);
    _prevRssi = null;
    _offRouteCount = 0;
    _lastBeaconMatchTime = null;
    BeaconService().startContinuousScanning();
    if (_result != null && _result!.path.isNotEmpty) {
      _speak(_result!.path[0].instruction);
      _lastSpokenMac = _result!.path[0].beaconMac;
    }
  }

  void _recalcRoute() {
    setState(() { _state = _NavState.loading; _step = 0; _offRouteCount = 0; });
    _speak('Recalculating route.');
    _loadRoute().then((_) { if (mounted && _state == _NavState.preview) _start(); });
  }

  IconData _dirIcon(String d) { switch (d.toLowerCase()) { case 'left': return Icons.turn_left_rounded; case 'right': return Icons.turn_right_rounded; case 'up': return Icons.north_rounded; case 'down': return Icons.south_rounded; default: return Icons.straight_rounded; } }
  String _dirLabel(String d) { switch (d.toLowerCase()) { case 'left': return 'Turn left'; case 'right': return 'Turn right'; case 'up': return 'Go upstairs'; case 'down': return 'Go downstairs'; default: return 'Go straight'; } }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final room = RoomsService().getRoomByNumber(widget.roomNumber);
    final beaconSvc = context.watch<BeaconService>();
    final beacon = beaconSvc.currentBeacon;
    final dist = _result?.totalDistanceMeters ?? 30;
    final time = _result?.estimatedTimeMinutes ?? 2;
    final roomPosMap = _currentFloor == 4 ? _f4Rooms : _f5Rooms;
    final floorRooms = RoomsService().allRooms.where((r) => r.floor == _currentFloor && r.active).toList();

    Offset pinPos = _state == _NavState.active && _routeWaypoints.length >= 2
        ? _calcPinPos(beaconSvc)
        : (beacon != null ? _beaconScreenPos(beacon.mac) : const Offset(0.41, 0.28));

    // Live step tracking
    if (_state == _NavState.active && beacon != null && _result != null && _result!.success) {
      bool found = false;
      for (int i = 0; i < _result!.path.length; i++) {
        final stepData = _result!.path[i];

        if (stepData.beaconMac == beacon.mac) {
          found = true; // ← move found=true here, inside the match

          final bool isLastStep = i == _result!.path.length - 1;

          // ── ALWAYS check arrival when on last beacon ──
          if (isLastStep && _state == _NavState.active && _lastBeaconMatchTime != null) {
            final sinceMatch = DateTime.now().difference(_lastBeaconMatchTime!);
            // Only trigger once — if we haven't arrived yet and been here >2s
            if (sinceMatch.inSeconds >= 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _state != _NavState.active) return;
                _speak("${stepData.instruction}. You have arrived.");
                setState(() => _state = _NavState.arrived);
                BeaconService().stopContinuousScanning();
              });
            }
          }

          if (i != _step || _lastSpokenMac != beacon.mac) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _offRouteCount = 0;
              _lastBeaconMatchTime = DateTime.now();

              if (_lastSpokenMac != beacon.mac) {
                _lastSpokenMac = beacon.mac;
                _speak(stepData.instruction);
              }

              // Floor switching — only from explicit floor field, not STAIRS
              int beaconFloor = _currentFloor;
              if (stepData.beaconMac != 'STAIRS' && stepData.floor != null) {
                beaconFloor = stepData.floor is int
                    ? stepData.floor as int
                    : (stepData.floor is String && stepData.floor.toString().contains('→')
                    ? int.parse(stepData.floor.toString().split('→').last)
                    : _currentFloor);
              }

              setState(() { _step = i; });

              // ── AUTO-ADVANCE THROUGH STAIRS STEP ──
              final nextIdx = i + 1;
              final hasStairsNext = nextIdx < _result!.path.length &&
                  _result!.path[nextIdx].beaconMac == 'STAIRS';

              if (hasStairsNext) {
                Future.delayed(const Duration(seconds: 4), () {
                  if (!mounted || _state != _NavState.active) return;
                  // Show and speak stairs instruction
                  final stairsStep = _result!.path[nextIdx];
                  _speak(stairsStep.instruction);
                  setState(() { _step = nextIdx; });

                  // Switch floor after user has time to take stairs
                  Future.delayed(const Duration(seconds: 5), () {
                    if (!mounted || _state != _NavState.active) return;
                    final afterStairsIdx = nextIdx + 1;
                    setState(() {
                      _currentFloor = _destFloor;
                      _step = afterStairsIdx < _result!.path.length
                          ? afterStairsIdx
                          : nextIdx;
                      _buildRouteWaypoints();
                      _routeCtrl.forward(from: 0);
                    });
                    // Speak first instruction on new floor
                    if (afterStairsIdx < _result!.path.length) {
                      _speak(_result!.path[afterStairsIdx].instruction);
                      _lastSpokenMac = _result!.path[afterStairsIdx].beaconMac;
                    }
                  });
                });
              }

              // ── ARRIVED CHECK ──
              final bool isLastStep = i == _result!.path.length - 1;
              if (isLastStep) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted && _state == _NavState.active) {
                    _speak("${stepData.instruction}. You have arrived.");
                    setState(() => _state = _NavState.arrived);
                    BeaconService().stopContinuousScanning();
                  }
                });
              }
            });
          } else if (isLastStep && _state == _NavState.active) {
            // Already on this step but arrived panel never showed — force it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _state != _NavState.active) return;
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && _state == _NavState.active) {
                  _speak("${stepData.instruction}. You have arrived.");
                  setState(() => _state = _NavState.arrived);
                  BeaconService().stopContinuousScanning();
                }
              });
            });
          }
          break;
        }
      }

      if (!found && beacon.mac != (_lastSpokenMac ?? '')) {
        final now = DateTime.now();
        final sinceLastMatch = _lastBeaconMatchTime == null
            ? Duration.zero
            : now.difference(_lastBeaconMatchTime!);
        if (_lastBeaconMatchTime != null && sinceLastMatch.inSeconds > 30) {
          _offRouteCount++;
          if (_offRouteCount >= 4) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _state != _NavState.active) return;
              _speak('You appear to be off route. Recalculating.');
              setState(() => _state = _NavState.offRoute);
              BeaconService().stopContinuousScanning();
            });
          }
        }
      } else if (found) {
        _offRouteCount = 0;
        _lastBeaconMatchTime = DateTime.now();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // Map — using new map.png
        Positioned.fill(child: Image.asset('assets/images/map.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _bg))),

        // Route line — follows actual corridor paths
        if (_state != _NavState.loading && _routeWaypoints.length >= 2)
          Positioned.fill(child: AnimatedBuilder(animation: _routeAnim,
              builder: (_, __) => CustomPaint(painter: _WaypointRoutePainter(
                  waypoints: _routeWaypoints, progress: _routeAnim.value,
                  liveProgress: _state == _NavState.active ? _routeProgress : 0,
                  isActive: _state == _NavState.active)))),

        // Room labels
        ...floorRooms.map((r) {
          final pos = roomPosMap[r.number];
          if (pos == null) return const SizedBox.shrink();
          final isDest = r.number == widget.roomNumber;
          return Positioned(left: size.width * pos.dx - 18, top: size.height * pos.dy - 9,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: isDest ? _primary : Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDest ? 0.18 : 0.08), blurRadius: isDest ? 6 : 3, offset: const Offset(0, 1))]),
                  child: Text( r.number.contains('WC') ? 'WC' : r.number, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: isDest ? Colors.white : _text))));
        }),

        // Pin — centered exactly on position
        if (beacon != null)
          Positioned(
            left: size.width * pinPos.dx - 16,
            top: size.height * pinPos.dy - 16,
            child: AnimatedBuilder(animation: _pulseAnim,
                builder: (_, __) => Stack(alignment: Alignment.center, children: [
                  Transform.scale(scale: _pulseAnim.value,
                      child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.15)))),
                  Image.asset('assets/images/pin1.png', width: 32, height: 32, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(width: 16, height: 16,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _primary, border: Border.all(color: Colors.white, width: 2)))),
                ])),
          ),

        // Time badge
        if ((_state == _NavState.preview || _state == _NavState.active) && _routeWaypoints.length >= 2)
          Positioned(
              left: size.width * _routeWaypoints[_routeWaypoints.length ~/ 2].dx - 20,
              top: size.height * _routeWaypoints[_routeWaypoints.length ~/ 2].dy - 24,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(9999)),
                  child: Text('$time min', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),

        // Header
        Positioned(top: 0, left: 0, right: 0,
            child: Container(
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))]),
                padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + 8, 0, 0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        IconButton(onPressed: widget.onClose, icon: const Icon(Icons.arrow_back_rounded, color: _text, size: 22), padding: const EdgeInsets.only(top: 10)),
                        Expanded(child: Column(children: [
                          Container(height: 42, margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                              child: Row(children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _primary)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(beacon != null ? beacon.location.replaceAll('Floor ${beacon.floor} - ', '') : 'Your location',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: beacon != null ? _primary : _muted), overflow: TextOverflow.ellipsis)),
                              ])),
                          Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _primary)),
                              child: Row(children: [
                                Image.asset('assets/images/pin1.png', width: 18, height: 18, fit: BoxFit.contain),  const SizedBox(width: 8),
                                Expanded(child: Text(_resolveDestinationName(),
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _text), overflow: TextOverflow.ellipsis)),
                                Text('F$_destFloor', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _muted)),
                              ])),
                        ])),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.swap_vert_rounded, color: _muted, size: 22), padding: const EdgeInsets.only(top: 20)),
                      ])),
                  const SizedBox(height: 8), Container(height: 1, color: _border),
                ]))),

        // Bottom cards
        if (_state == _NavState.loading) _buildLoading(),
        if (_state == _NavState.preview) _buildPreview(room, dist, time),
        if (_state == _NavState.active) _buildActiveSheet(room, beaconSvc),
        if (_state == _NavState.arrived) _buildArrivedOverlay(room),
        if (_state == _NavState.offRoute) _buildOffRouteOverlay(),
      ]),
    );
  }

  Widget _buildLoading() => Positioned(bottom: 0, left: 0, right: 0, height: 180,
      child: Container(decoration: _cardDeco(), child: const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5))));

  Widget _buildPreview(RoomModel? room, int dist, int time) => Positioned(bottom: 0, left: 0, right: 0,
      child: Container(decoration: _cardDeco(), padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
            RichText(text: TextSpan(children: [
              TextSpan(text: '$time min ', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _primary)),
              TextSpan(text: '(${dist}m)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w400, color: _text)),
            ])),
            const SizedBox(height: 2),
            Text('Indoor navigation via BLE beacons', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFF59E0B)))),
            const SizedBox(height: 16),
            GestureDetector(onTap: _start, child: Container(width: double.infinity, height: 50,
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.navigation_rounded, color: Colors.white, size: 20), const SizedBox(width: 8),
                  Text('Start Navigation', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))]))),
            const SizedBox(height: 16),
          ]))));

  // ── SCROLLABLE ACTIVE SHEET ─────────────────────────────────────────────
  Widget _buildActiveSheet(RoomModel? room, BeaconService svc) {final has = _result != null && _result!.success && _result!.path.isNotEmpty;
  final total = has ? _result!.path.length : 1;

  NavigationStep? step;
  if (has && _step < _result!.path.length) {
    step = _result!.path[_step];
  }

  final instr = step?.instruction ?? 'Walking toward ${widget.roomNumber}...';
  final dir = step?.direction ?? 'forward';
  final beacon = svc.currentBeacon;

  return Positioned.fill(
    child: DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.2, // How much of the screen it takes initially
      minChildSize: 0.12,     // How small it can get (shows just the handle)
      maxChildSize: 0.50,     // How high it can be pulled
      snap: true,
      snapSizes: const [0.12, 0.30, 0.50],
      builder: (context, scrollCtrl) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: _cardDeco(),
          child: ListView.builder(
            controller: scrollCtrl, // Connects the drag handle to the sheet
            padding: EdgeInsets.zero,
            addSemanticIndexes: false, // Prevents the parentDataDirty crash
            itemCount: 2, // 1 for the Handle, 1 for the Main Content
            itemBuilder: (context, index) {
              // ITEM 0: THE DRAG HANDLE (This makes the top area draggable)
              if (index == 0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.transparent, // Ensures the whole top is a hit target
                  child: Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }

              // ITEM 1: THE MAIN NAVIGATION CONTENT
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    Container(
                      height: 4, margin: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: ((_step + 1) / total),
                          backgroundColor: _border,
                          valueColor: AlwaysStoppedAnimation(_primary),
                        ),
                      ),
                    ),

                    // Live status & Step count
                    Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: beacon != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        beacon != null ? 'Live · Floor ${beacon.floor}' : 'Scanning...',
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: beacon != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                      const Spacer(),
                      Text('Step ${_step + 1} of $total', style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                    ]),
                    const SizedBox(height: 16),

                    // CURRENT DIRECTION
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(16)),
                          child: Icon(_dirIcon(dir), color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_dirLabel(dir), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
                              const SizedBox(height: 4),
                              Text(instr, style: GoogleFonts.poppins(fontSize: 14, color: _muted, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Cancel button
                    GestureDetector(
                      onTap: () { _tts.stop(); widget.onClose(); },
                      child: Container(
                        width: double.infinity, height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border, width: 1.5),
                        ),
                        child: Center(
                          child: Text('Cancel Navigation', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _muted)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  }

  // ── ARRIVAL OVERLAY ───────────────────────────────────────────────────────
  // REPLACE _buildArrivedOverlay with:
  Widget _buildArrivedOverlay(RoomModel? room) {
    // Only show final direction if the last beacon is NOT the destination
    // i.e. the user still had to walk from the last beacon to reach the room
    final lastStep = (_result != null && _result!.path.isNotEmpty)
        ? _result!.path.last
        : null;

    // These rooms sit exactly ON a beacon — no extra walking needed after the beacon
    const roomsOnBeacon = {
      '408', '511',                          // junction beacons themselves
    };

    final destIsOnBeacon = roomsOnBeacon.contains(widget.roomNumber);
    final showFinalDirection = lastStep != null && !destIsOnBeacon;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ── FINAL DIRECTION (only when destination needs walking past last beacon) ──
              if (showFinalDirection) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_dirIcon(lastStep.direction), color: _primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lastStep.instruction,
                        style: GoogleFonts.poppins(fontSize: 13, color: _text, height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _border),
                const SizedBox(height: 16),
              ],

              // ── ARRIVED ──────────────────────────────────────
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text("You've arrived!",
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
              const SizedBox(height: 6),
              Text(_resolveDestinationName(),
                  style: GoogleFonts.poppins(fontSize: 14, color: _muted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('Done',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.onNewDestination,
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.5)),
                  child: Center(child: Text('New destination',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _muted))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
  // ── OFF ROUTE OVERLAY ─────────────────────────────────────────────────────
  Widget _buildOffRouteOverlay() => Positioned.fill(
      child: Container(color: Colors.black.withValues(alpha: 0.55),
          child: Center(child: Container(margin: const EdgeInsets.symmetric(horizontal: 32), padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 40)),
                const SizedBox(height: 16),
                Text('Off Route', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
                const SizedBox(height: 6),
                Text('You seem to have taken a wrong turn.\nWould you like to recalculate your route?',
                    style: GoogleFonts.poppins(fontSize: 13, color: _muted), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                GestureDetector(onTap: _recalcRoute,
                    child: Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.refresh_rounded, color: Colors.white, size: 20), const SizedBox(width: 8),
                          Text('Recalculate Route', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))]))),
                const SizedBox(height: 10),
                GestureDetector(onTap: widget.onClose,
                    child: Container(width: double.infinity, height: 50,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: _border, width: 1.5)),
                        child: Center(child: Text('Cancel Navigation', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _muted))))),
              ])))));

  BoxDecoration _cardDeco() => BoxDecoration(color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -6))]);
}

// ── ROUTE PAINTER — draws actual corridor path ─────────────────────────────
class _WaypointRoutePainter extends CustomPainter {
  final List<Offset> waypoints;
  final double progress, liveProgress;
  final bool isActive;
  static const _primary = Color(0xFF007A6E);

  const _WaypointRoutePainter({required this.waypoints, required this.progress, this.liveProgress = 0, this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.length < 2) return;
    final path = Path();
    path.moveTo(size.width * waypoints[0].dx, size.height * waypoints[0].dy);
    for (int i = 1; i < waypoints.length; i++) path.lineTo(size.width * waypoints[i].dx, size.height * waypoints[i].dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    double totalLen = 0;
    for (final m in metrics) totalLen += m.length;

    if (isActive && liveProgress > 0) {
      // Solid = completed portion, dotted = remaining
      final completedLen = totalLen * liveProgress;
      double drawn = 0;
      for (final m in metrics) {
        final done = (completedLen - drawn).clamp(0.0, m.length);
        if (done > 0) canvas.drawPath(m.extractPath(0, done),
            Paint()..color = _primary..strokeWidth = 6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
        if (done < m.length) {
          double d = done;
          while (d < m.length) {
            canvas.drawPath(m.extractPath(d, (d + 8).clamp(0, m.length)),
                Paint()..color = _primary.withValues(alpha: 0.3)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
            d += 16;
          }
        }
        drawn += m.length;
      }
    } else {
      // Preview: all dotted
      final animLen = totalLen * progress;
      double drawn = 0;
      for (final m in metrics) {
        final segLen = (animLen - drawn).clamp(0.0, m.length);
        if (segLen <= 0) break;
        double d = 0;
        while (d < segLen) {
          canvas.drawPath(m.extractPath(d, (d + 8).clamp(0, segLen)),
              Paint()..color = _primary.withValues(alpha: 0.6)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
          d += 16;
        }
        drawn += m.length;
      }
    }
  }

  @override
  bool shouldRepaint(_WaypointRoutePainter old) =>
      old.progress != progress || old.liveProgress != liveProgress || old.waypoints.length != waypoints.length;
}