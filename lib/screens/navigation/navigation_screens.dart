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

  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.42, 0.32),
    'E5:65:DD:D0:91:EC': Offset(0.60, 0.68),
    'C8:93:08:09:B2:CA': Offset(0.12, 0.42),
    'F4:7B:74:76:D5:8A': Offset(0.42, 0.32),
    'C7:A4:5A:D0:74:D8': Offset(0.58, 0.68),
    'F3:55:BD:A3:65:2E': Offset(0.12, 0.37),
  };

  static const Map<String, Offset> _f4Rooms = {
    '424': Offset(0.12, 0.32), '425': Offset(0.12, 0.37), '426': Offset(0.12, 0.42),
    '427': Offset(0.12, 0.47), '428': Offset(0.12, 0.52), '429': Offset(0.12, 0.57),
    '430': Offset(0.12, 0.62),
    '423': Offset(0.22, 0.32), '422': Offset(0.32, 0.32), '421': Offset(0.42, 0.32),
    '420': Offset(0.52, 0.32),
    '401': Offset(0.62, 0.32), '402': Offset(0.62, 0.40), '403': Offset(0.62, 0.48),
    '404': Offset(0.62, 0.55),
    '419': Offset(0.72, 0.32), '418': Offset(0.72, 0.40), '417': Offset(0.72, 0.48),
    '416': Offset(0.72, 0.55),
    '408': Offset(0.60, 0.68),
    '409': Offset(0.48, 0.68), '415': Offset(0.38, 0.68), '414': Offset(0.28, 0.68),
    '413': Offset(0.18, 0.68),
    '410': Offset(0.48, 0.75), '411': Offset(0.38, 0.75), '412': Offset(0.28, 0.75),
    '406': Offset(0.72, 0.68), '407': Offset(0.82, 0.68),
  };

  static const Map<String, Offset> _f5Rooms = {
    '526': Offset(0.12, 0.32), '527': Offset(0.12, 0.37), '528': Offset(0.12, 0.42),
    '529': Offset(0.12, 0.47),
    '525': Offset(0.22, 0.32), '524': Offset(0.32, 0.32), '523': Offset(0.42, 0.32),
    '522': Offset(0.52, 0.32),
    '501': Offset(0.62, 0.32), '502': Offset(0.62, 0.42), '503': Offset(0.62, 0.52),
    '521': Offset(0.72, 0.32), '520': Offset(0.72, 0.42),
    '511': Offset(0.58, 0.68),
    '504': Offset(0.46, 0.68), '510': Offset(0.36, 0.68), '509': Offset(0.26, 0.68),
    '505': Offset(0.46, 0.72), '506': Offset(0.36, 0.72), '508': Offset(0.26, 0.72),
    '507': Offset(0.16, 0.72),
    '512': Offset(0.70, 0.68), '519': Offset(0.80, 0.68), '513': Offset(0.90, 0.68),
    '514': Offset(0.70, 0.72), '518': Offset(0.80, 0.72), '517': Offset(0.90, 0.72),
    '515': Offset(0.80, 0.72), '516': Offset(0.88, 0.72),
  };

  static const List<List<Offset>> _corridors4 = [
    [Offset(0.42, 0.22), Offset(0.22, 0.22)], [Offset(0.22, 0.22), Offset(0.22, 0.64)],
    [Offset(0.42, 0.22), Offset(0.42, 0.30)], [Offset(0.32, 0.30), Offset(0.52, 0.30)],
    [Offset(0.36, 0.30), Offset(0.36, 0.55)], [Offset(0.52, 0.30), Offset(0.52, 0.55)],
    [Offset(0.36, 0.55), Offset(0.44, 0.60)], [Offset(0.52, 0.55), Offset(0.44, 0.60)],
    [Offset(0.44, 0.60), Offset(0.36, 0.68)], [Offset(0.12, 0.68), Offset(0.36, 0.68)],
    [Offset(0.20, 0.68), Offset(0.20, 0.75)], [Offset(0.28, 0.68), Offset(0.28, 0.75)],
    [Offset(0.36, 0.68), Offset(0.36, 0.75)], [Offset(0.44, 0.60), Offset(0.56, 0.68)],
    [Offset(0.56, 0.68), Offset(0.82, 0.68)],
  ];

  static const List<List<Offset>> _corridors5 = [
    [Offset(0.42, 0.22), Offset(0.22, 0.22)], [Offset(0.22, 0.22), Offset(0.22, 0.46)],
    [Offset(0.42, 0.22), Offset(0.42, 0.30)], [Offset(0.32, 0.30), Offset(0.52, 0.30)],
    [Offset(0.36, 0.30), Offset(0.36, 0.50)], [Offset(0.52, 0.30), Offset(0.52, 0.45)],
    [Offset(0.36, 0.50), Offset(0.44, 0.60)], [Offset(0.52, 0.45), Offset(0.44, 0.60)],
    [Offset(0.44, 0.60), Offset(0.36, 0.68)], [Offset(0.12, 0.75), Offset(0.36, 0.68)],
    [Offset(0.20, 0.68), Offset(0.20, 0.75)], [Offset(0.28, 0.68), Offset(0.28, 0.75)],
    [Offset(0.36, 0.68), Offset(0.36, 0.75)], [Offset(0.44, 0.60), Offset(0.56, 0.68)],
    [Offset(0.56, 0.68), Offset(0.90, 0.68)], [Offset(0.56, 0.68), Offset(0.56, 0.75)],
    [Offset(0.64, 0.68), Offset(0.64, 0.75)], [Offset(0.72, 0.68), Offset(0.72, 0.75)],
    [Offset(0.80, 0.75), Offset(0.88, 0.75)],
  ];

  // Corridor-following paths between beacons
  static const Map<String, List<Offset>> _corridorPaths = {
    'C6:2A:90:A1:99:CB→E5:65:DD:D0:91:EC': [
      Offset(0.42, 0.32), Offset(0.42, 0.30), Offset(0.44, 0.30),
      Offset(0.44, 0.55), Offset(0.44, 0.60), Offset(0.60, 0.68),
    ],
    'E5:65:DD:D0:91:EC→C6:2A:90:A1:99:CB': [
      Offset(0.60, 0.68), Offset(0.44, 0.60), Offset(0.44, 0.30),
      Offset(0.42, 0.30), Offset(0.42, 0.32),
    ],
    'C6:2A:90:A1:99:CB→C8:93:08:09:B2:CA': [
      Offset(0.42, 0.32), Offset(0.22, 0.32), Offset(0.22, 0.42), Offset(0.12, 0.42),
    ],
    'C8:93:08:09:B2:CA→C6:2A:90:A1:99:CB': [
      Offset(0.12, 0.42), Offset(0.22, 0.42), Offset(0.22, 0.32), Offset(0.42, 0.32),
    ],
    'F4:7B:74:76:D5:8A→C7:A4:5A:D0:74:D8': [
      Offset(0.42, 0.32), Offset(0.52, 0.32), Offset(0.52, 0.30),
      Offset(0.62, 0.30), Offset(0.62, 0.52), Offset(0.44, 0.60), Offset(0.58, 0.68),
    ],
    'C7:A4:5A:D0:74:D8→F4:7B:74:76:D5:8A': [
      Offset(0.58, 0.68), Offset(0.44, 0.60), Offset(0.62, 0.52),
      Offset(0.62, 0.30), Offset(0.52, 0.30), Offset(0.52, 0.32), Offset(0.42, 0.32),
    ],
    'F4:7B:74:76:D5:8A→F3:55:BD:A3:65:2E': [
      Offset(0.42, 0.32), Offset(0.22, 0.32), Offset(0.22, 0.37), Offset(0.12, 0.37),
    ],
    'F3:55:BD:A3:65:2E→F4:7B:74:76:D5:8A': [
      Offset(0.12, 0.37), Offset(0.22, 0.37), Offset(0.22, 0.32), Offset(0.42, 0.32),
    ],
  };

  int get _destFloor => widget.roomNumber.startsWith('5') ? 5 : 4;
  Offset get _destPos => (_destFloor == 4 ? _f4Rooms : _f5Rooms)[widget.roomNumber] ?? const Offset(0.44, 0.60);
  Offset _beaconScreenPos(String mac) => _beaconPos[mac] ?? const Offset(0.42, 0.32);

  // Build corridor-accurate route waypoints
  void _buildRouteWaypoints() {
    _routeWaypoints = [];
    final dest = widget.roomNumber;
    final destPos = _destPos;

    if (_result == null || !_result!.success || _result!.path.isEmpty) {
      final b = BeaconService().currentBeacon;
      _routeWaypoints = [b != null ? _beaconScreenPos(b.mac) : const Offset(0.42, 0.32), destPos];
      return;
    }

    final steps = _result!.path.where((s) => s.beaconMac != 'STAIRS').toList();
    if (steps.isEmpty) { _routeWaypoints = [const Offset(0.42, 0.32), destPos]; return; }

    // Add first beacon
    _routeWaypoints.add(_beaconScreenPos(steps[0].beaconMac));

    for (int i = 0; i < steps.length; i++) {
      if (i < steps.length - 1) {
        // Corridor path to next beacon
        final key = '${steps[i].beaconMac}→${steps[i+1].beaconMac}';
        final pts = _corridorPaths[key];
        if (pts != null) {
          for (int j = 1; j < pts.length; j++) _routeWaypoints.add(pts[j]);
        } else {
          _routeWaypoints.add(_beaconScreenPos(steps[i+1].beaconMac));
        }
      } else {
        // Last beacon to destination — follow corridor
        final lastMac = steps[i].beaconMac;
        _addDestinationPath(lastMac, dest, destPos);
      }
    }

    if (_routeWaypoints.isEmpty || _routeWaypoints.last != destPos) _routeWaypoints.add(destPos);
  }

  void _addDestinationPath(String fromMac, String dest, Offset destPos) {
    // F4 destinations
    if (_destFloor == 4) {
      if (['406','407'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.60,0.68), Offset(0.56,0.68), destPos]);
      } else if (['409','410','411','412','413','414','415'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.60,0.68), Offset(0.44,0.60), Offset(0.44,0.68), destPos]);
      } else if (['401','402','403','404','416','417','418','419'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.60,0.68), Offset(0.44,0.60), Offset(0.44,0.32), destPos]);
      } else if (['420','421','422','423'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.42,0.32), destPos]);
      } else if (['424','425','426','427','428','429','430'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.12,0.42), destPos]);
      } else {
        _routeWaypoints.add(destPos);
      }
    }
    // F5 destinations
    else {
      if (['504','505','506','507','508','509','510'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.58,0.68), Offset(0.44,0.60), Offset(0.36,0.68), destPos]);
      } else if (['512','513','514','515','516','517','518','519'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.58,0.68), Offset(0.56,0.68), destPos]);
      } else if (['501','502','503','520','521'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.58,0.68), Offset(0.44,0.60), Offset(0.62,0.42), destPos]);
      } else if (['522','523','524','525'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.42,0.32), destPos]);
      } else if (['526','527','528','529'].contains(dest)) {
        _routeWaypoints.addAll([Offset(0.12,0.37), destPos]);
      } else if (dest == '511') {
        _routeWaypoints.addAll([Offset(0.58,0.68)]);
      } else {
        _routeWaypoints.add(destPos);
      }
    }
  }

  Offset _calcPinPos(BeaconService svc) {
    final b = svc.currentBeacon;
    if (b == null || _routeWaypoints.isEmpty) return _routeWaypoints.isNotEmpty ? _routeWaypoints.first : const Offset(0.42, 0.32);

    final currentPos = _beaconScreenPos(b.mac);
    final rssi = svc.currentRssi ?? -70;

    // Only update if RSSI changed >3 dBm
    if (_prevRssi == null || ((_prevRssi! - rssi).abs() > 3)) _prevRssi = rssi;
    final proximity = ((_prevRssi! + 90) / 60.0).clamp(0.0, 1.0);

    int idx = -1;
    for (int i = 0; i < _routeWaypoints.length; i++) {
      if (_routeWaypoints[i] == currentPos) { idx = i; break; }
    }
    if (idx < 0) return currentPos;
    if (idx >= _routeWaypoints.length - 1) { _routeProgress = 1.0; return currentPos; }

    final t = 1.0 - proximity;
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
    BeaconModel? b = svc.currentBeacon ?? await svc.detectCurrentLocation(durationSeconds: 5);
    const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      setState(() { _state = _NavState.preview; _error = 'Demo mode'; _currentFloor = b?.floor ?? _destFloor; });
      _buildRouteWaypoints();
      _routeCtrl.forward();
      return;
    }
    final result = await NavigationService().navigate(currentBeaconMac: b?.mac ?? 'C6:2A:90:A1:99:CB', currentFloor: b?.floor ?? _destFloor, destinationNumber: widget.roomNumber, apiKey: apiKey);
    if (!mounted) return;
    setState(() { _result = result; _state = _NavState.preview; _currentFloor = b?.floor ?? _destFloor; });
    _buildRouteWaypoints();
    _routeCtrl.forward();
  }

  void _start() {
    setState(() => _state = _NavState.active);
    _prevRssi = null;
    _offRouteCount = 0;
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
    final corridors = _currentFloor == 4 ? _corridors4 : _corridors5;

    Offset pinPos = _state == _NavState.active && _routeWaypoints.length >= 2
        ? _calcPinPos(beaconSvc)
        : (beacon != null ? _beaconScreenPos(beacon.mac) : const Offset(0.42, 0.32));

    // Live step tracking
    if (_state == _NavState.active && beacon != null && _result != null && _result!.success) {
      bool found = false;
      for (int i = 0; i < _result!.path.length; i++) {
        if (_result!.path[i].beaconMac == beacon.mac) {
          found = true;
          if (i != _step) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _offRouteCount = 0;
              final fl = _result!.path[i].floor;
              setState(() { _step = i; _currentFloor = fl is int ? fl : _currentFloor; });
              if (_lastSpokenMac != beacon.mac) {
                _lastSpokenMac = beacon.mac;
                _speak(_result!.path[i].instruction);
              }
              if (i >= _result!.path.length - 1 && (beaconSvc.currentRssi ?? -80) > -55) {
                _speak('You have arrived at Room ${widget.roomNumber}!');
                setState(() => _state = _NavState.arrived);
                BeaconService().stopContinuousScanning();
              }
            });
          }
          break;
        }
      }
      if (!found && beacon.mac != (_lastSpokenMac ?? '')) {
        _offRouteCount++;
        if (_offRouteCount >= 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _state != _NavState.active) return;
            _speak('You appear to be off route. Recalculating.');
            setState(() => _state = _NavState.offRoute);
            BeaconService().stopContinuousScanning();
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/campus_map.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _bg))),
        Positioned.fill(child: CustomPaint(painter: _CorridorPainter(corridors: corridors))),

        if (_state != _NavState.loading && _routeWaypoints.length >= 2)
          Positioned.fill(child: AnimatedBuilder(animation: _routeAnim,
              builder: (_, __) => CustomPaint(painter: _WaypointRoutePainter(
                  waypoints: _routeWaypoints, progress: _routeAnim.value,
                  liveProgress: _state == _NavState.active ? _routeProgress : 0,
                  isActive: _state == _NavState.active)))),

        ...floorRooms.map((r) {
          final pos = roomPosMap[r.number];
          if (pos == null) return const SizedBox.shrink();
          final isDest = r.number == widget.roomNumber;
          return Positioned(left: size.width * pos.dx - 18, top: size.height * pos.dy - 9,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: isDest ? _primary : Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDest ? 0.18 : 0.08), blurRadius: isDest ? 6 : 3, offset: const Offset(0, 1))]),
                  child: Text(r.number, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: isDest ? Colors.white : _text))));
        }),

        if (beacon != null)
          Positioned(left: size.width * pinPos.dx - 16, top: size.height * pinPos.dy - 16,
              child: AnimatedBuilder(animation: _pulseAnim,
                  builder: (_, __) => Stack(alignment: Alignment.center, children: [
                    Transform.scale(scale: _pulseAnim.value,
                        child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.15)))),
                    Image.asset('assets/images/pin1.png', width: 32, height: 32, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(width: 16, height: 16,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _primary, border: Border.all(color: Colors.white, width: 2)))),
                  ]))),

        if ((_state == _NavState.preview || _state == _NavState.active) && _routeWaypoints.length >= 2)
          Positioned(
              left: size.width * _routeWaypoints[_routeWaypoints.length ~/ 2].dx - 20,
              top: size.height * _routeWaypoints[_routeWaypoints.length ~/ 2].dy - 24,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(9999)),
                  child: Text('$time min', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),

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
                                const Icon(Icons.location_on_rounded, size: 14, color: _red), const SizedBox(width: 8),
                                Expanded(child: Text(room?.name ?? 'Room ${widget.roomNumber}',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _text), overflow: TextOverflow.ellipsis)),
                                Text('F$_destFloor', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _muted)),
                              ])),
                        ])),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.swap_vert_rounded, color: _muted, size: 22), padding: const EdgeInsets.only(top: 20)),
                      ])),
                  const SizedBox(height: 8), Container(height: 1, color: _border),
                ]))),

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

  Widget _buildActiveSheet(RoomModel? room, BeaconService svc) {
    final has = _result != null && _result!.success && _result!.path.isNotEmpty;
    final total = has ? _result!.path.length : 1;
    NavigationStep? step;
    if (has && _step < _result!.path.length) step = _result!.path[_step];
    final instr = step?.instruction ?? 'Navigate to Room ${widget.roomNumber}';
    final dir = step?.direction ?? 'forward';
    final beacon = svc.currentBeacon;

    return Positioned(bottom: 0, left: 0, right: 0,
        child: DraggableScrollableSheet(
          controller: _sheetCtrl,
          initialChildSize: 0.28,
          minChildSize: 0.10,
          maxChildSize: 0.60,
          snap: true,
          snapSizes: const [0.10, 0.28, 0.60],
          builder: (context, scrollCtrl) => Container(
            decoration: _cardDeco(),
            child: ListView(controller: scrollCtrl, padding: EdgeInsets.zero, children: [
              Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Progress
                Container(height: 4, margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(value: _routeProgress, backgroundColor: _border, valueColor: const AlwaysStoppedAnimation(_primary)))),
                // Status
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
                      color: beacon != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                  const SizedBox(width: 8),
                  Text(beacon != null ? 'Live · Floor ${beacon.floor}' : 'Scanning...',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500,
                          color: beacon != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                  const Spacer(),
                  Text('Step ${_step + 1} of $total', style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                ]),
                const SizedBox(height: 12),
                // Current direction
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14)),
                      child: Icon(_dirIcon(dir), color: Colors.white, size: 26)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_dirLabel(dir), style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: _text)),
                    const SizedBox(height: 4),
                    Text(instr, style: GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.45)),
                  ])),
                ]),
                const SizedBox(height: 16),
                // All steps
                if (has && total > 1) ...[
                  Text('ALL STEPS', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  ...List.generate(_result!.path.length, (i) {
                    final s = _result!.path[i];
                    final isCurrent = i == _step;
                    final isDone = i < _step;
                    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: isCurrent ? _primary.withValues(alpha: 0.06) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isCurrent ? _primary.withValues(alpha: 0.25) : _border.withValues(alpha: 0.5))),
                        child: Row(children: [
                          Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle,
                              color: isDone ? _primary : isCurrent ? _primary : const Color(0xFFE5EBEB)),
                              child: Center(child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                  : Text('${i+1}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: isCurrent ? Colors.white : _muted)))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.instruction,
                              style: GoogleFonts.poppins(fontSize: 12, color: isCurrent ? _text : _muted,
                                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400), maxLines: 3, overflow: TextOverflow.ellipsis)),
                        ]));
                  }),
                  const SizedBox(height: 8),
                ],
                GestureDetector(onTap: () { _tts.stop(); widget.onClose(); },
                    child: Container(width: double.infinity, height: 44,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _border, width: 1.5)),
                        child: Center(child: Text('Cancel Navigation', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _muted))))),
                const SizedBox(height: 16),
              ])),
            ]),
          ),
        ));
  }

  Widget _buildArrivedOverlay(RoomModel? room) => Positioned.fill(
      child: Container(color: Colors.black.withValues(alpha: 0.55),
          child: Center(child: Container(margin: const EdgeInsets.symmetric(horizontal: 32), padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 72, height: 72, decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)),
                const SizedBox(height: 16),
                Text("You've arrived!", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
                const SizedBox(height: 6),
                Text(room?.name ?? 'Room ${widget.roomNumber}',
                    style: GoogleFonts.poppins(fontSize: 14, color: _muted), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                GestureDetector(onTap: widget.onClose,
                    child: Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Text('Done', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))))),
                const SizedBox(height: 10),
                GestureDetector(onTap: widget.onNewDestination,
                    child: Container(width: double.infinity, height: 50,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: _border, width: 1.5)),
                        child: Center(child: Text('New destination', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _muted))))),
              ])))));

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

class _CorridorPainter extends CustomPainter {
  final List<List<Offset>> corridors;
  const _CorridorPainter({required this.corridors});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF007A6E).withValues(alpha: 0.10)..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (final s in corridors) canvas.drawLine(Offset(size.width * s[0].dx, size.height * s[0].dy), Offset(size.width * s[1].dx, size.height * s[1].dy), p);
  }
  @override
  bool shouldRepaint(_CorridorPainter old) => false;
}

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
      final completedLen = totalLen * liveProgress;
      double drawn = 0;
      for (final m in metrics) {
        final done = (completedLen - drawn).clamp(0.0, m.length);
        if (done > 0) canvas.drawPath(m.extractPath(0, done),
            Paint()..color = _primary..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
        if (done < m.length) { double d = done; while (d < m.length) { canvas.drawPath(m.extractPath(d, (d+8).clamp(0,m.length)),
            Paint()..color = _primary.withValues(alpha: 0.3)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke); d += 16; } }
        drawn += m.length;
      }
    } else {
      final animLen = totalLen * progress;
      double drawn = 0;
      for (final m in metrics) {
        final segLen = (animLen - drawn).clamp(0.0, m.length);
        if (segLen <= 0) break;
        double d = 0;
        while (d < segLen) { canvas.drawPath(m.extractPath(d, (d+8).clamp(0,segLen)),
            Paint()..color = _primary.withValues(alpha: 0.5)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke); d += 16; }
        drawn += m.length;
      }
    }
  }

  @override
  bool shouldRepaint(_WaypointRoutePainter old) =>
      old.progress != progress || old.liveProgress != liveProgress || old.waypoints.length != waypoints.length;
}