import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  DateTime? _lastBeaconMatchTime;
  // NEW: track whether we've already triggered the stairs transition
  bool _stairsTransitionFired = false;

  late AnimationController _pulseCtrl, _routeCtrl;
  late Animation<double> _pulseAnim, _routeAnim;

  List<Offset> _routeWaypoints = [];
  double _routeProgress = 0.0;
  int? _prevRssi;

  final FlutterTts _tts = FlutterTts();
  late DraggableScrollableController _sheetCtrl;

  static const _primary = Color(0xFF007A6E);
  static const _text = Color(0xFF1C2B2A);
  static const _muted = Color(0xFF6B7B7A);
  static const _border = Color(0xFFE5EBEB);
  static const _bg = Color(0xFFF7FAFA);

  static const Map<String, Offset> _beaconPos = {
    'C6:2A:90:A1:99:CB': Offset(0.41, 0.28),
    'E5:65:DD:D0:91:EC': Offset(0.57, 0.55),
    'C8:93:08:09:B2:CA': Offset(0.25, 0.41),
    'F4:7B:74:76:D5:8A': Offset(0.41, 0.28),
    'C7:A4:5A:D0:74:D8': Offset(0.57, 0.55),
    'F3:55:BD:A3:65:2E': Offset(0.25, 0.38),
  };

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
    '4WC': Offset(0.70, 0.53),
    '408': Offset(0.57, 0.55),
    '409': Offset(0.70, 0.61), '410': Offset(0.70, 0.66),
    '411': Offset(0.70, 0.71), '415': Offset(0.80, 0.61),
    '414': Offset(0.80, 0.66), '413': Offset(0.80, 0.71),
    '412': Offset(0.80, 0.76),
    '407': Offset(0.47, 0.61), '406': Offset(0.42, 0.66),
  };

  static const Map<String, Offset> _f5Rooms = {
    '526': Offset(0.25, 0.33), '527': Offset(0.25, 0.38),
    '528': Offset(0.25, 0.43), '529': Offset(0.25, 0.48),
    '525': Offset(0.31, 0.28), '524': Offset(0.41, 0.28),
    '523': Offset(0.51, 0.28), '522': Offset(0.61, 0.28),
    '501': Offset(0.60, 0.33), '502': Offset(0.60, 0.38),
    '503': Offset(0.60, 0.43),
    '521': Offset(0.70, 0.33), '520': Offset(0.70, 0.38),
    '5WC': Offset(0.70, 0.43),
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

  static const Map<String, List<Offset>> _corridorPaths = {
    'C6:2A:90:A1:99:CB→E5:65:DD:D0:91:EC': [
      Offset(0.41, 0.28), Offset(0.65, 0.28), Offset(0.65, 0.55), Offset(0.57, 0.55),
    ],
    'E5:65:DD:D0:91:EC→C6:2A:90:A1:99:CB': [
      Offset(0.57, 0.55), Offset(0.65, 0.55), Offset(0.65, 0.28), Offset(0.41, 0.28),
    ],
    'C6:2A:90:A1:99:CB→C8:93:08:09:B2:CA': [
      Offset(0.41, 0.28), Offset(0.25, 0.28), Offset(0.25, 0.41),
    ],
    'C8:93:08:09:B2:CA→C6:2A:90:A1:99:CB': [
      Offset(0.25, 0.41), Offset(0.25, 0.28), Offset(0.41, 0.28),
    ],
    'C8:93:08:09:B2:CA→C8:93:08:09:B2:CA': [
      Offset(0.25, 0.41),
    ],
    'C8:93:08:09:B2:CA→E5:65:DD:D0:91:EC': [
      Offset(0.25, 0.41), Offset(0.25, 0.28), Offset(0.65, 0.28), Offset(0.65, 0.55), Offset(0.57, 0.55),
    ],
    'F3:55:BD:A3:65:2E→C7:A4:5A:D0:74:D8': [
      Offset(0.25, 0.38), Offset(0.25, 0.28), Offset(0.65, 0.28), Offset(0.65, 0.55), Offset(0.57, 0.55),
    ],
    'F4:7B:74:76:D5:8A→C7:A4:5A:D0:74:D8': [
      Offset(0.41, 0.28), Offset(0.65, 0.28), Offset(0.65, 0.55), Offset(0.57, 0.55),
    ],
    'C7:A4:5A:D0:74:D8→F4:7B:74:76:D5:8A': [
      Offset(0.57, 0.55), Offset(0.65, 0.55), Offset(0.65, 0.28), Offset(0.41, 0.28),
    ],
    'F4:7B:74:76:D5:8A→F3:55:BD:A3:65:2E': [
      Offset(0.41, 0.28), Offset(0.25, 0.28), Offset(0.25, 0.38),
    ],
    'F3:55:BD:A3:65:2E→F4:7B:74:76:D5:8A': [
      Offset(0.25, 0.38), Offset(0.25, 0.28), Offset(0.41, 0.28),
    ],
  };

  Future<void> _logNavigation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final room = RoomsService().getRoomByNumber(widget.roomNumber);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('navigations')
          .add({
        'roomNumber': widget.roomNumber,
        'roomName': room?.name ?? 'Room ${widget.roomNumber}',
        'floor': room?.floor ?? (widget.roomNumber.startsWith('5') ? 5 : 4),
        'building': room?.building ?? 'Nicol Hall',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to log navigation: $e');
    }
  }

  String _resolveDestinationName() {
    final room = RoomsService().getRoomByNumber(widget.roomNumber);
    if (room != null) return room.name;
    return 'Room ${widget.roomNumber}';
  }

  int get _destFloor => widget.roomNumber.startsWith('5') ? 5 : 4;
  Offset get _destPos => (_destFloor == 4 ? _f4Rooms : _f5Rooms)[widget.roomNumber] ?? const Offset(0.57, 0.55);
  Offset _beaconScreenPos(String mac) => _beaconPos[mac] ?? const Offset(0.41, 0.28);

  // ── BEACON MACs ─────────────────────────────────────────────────────────
  static const _elevatorF4 = 'C6:2A:90:A1:99:CB';
  static const _elevatorF5 = 'F4:7B:74:76:D5:8A';
  static const _junctionF4 = 'E5:65:DD:D0:91:EC'; // 408 junction
  static const _junctionF5 = 'C7:A4:5A:D0:74:D8'; // 511 junction

  /// The beacon that triggers the map switch is the FIRST beacon of the
  /// destination floor in the route path (after the STAIRS marker).
  /// We read this directly from the path generated by NavigationService
  /// rather than guessing — so it works for all 3 cases:
  ///   Case A: elevator F5 (after main stairs going up)
  ///   Case B: junction F4 (after back stairs going down)
  ///   Case C: same as Case A
  String? get _destFloorArrivalBeacon {
    if (_result == null) return null;
    final stairsIdx = _result!.path.indexWhere((s) => s.beaconMac == 'STAIRS');
    if (stairsIdx < 0) return null;
    // First real step after STAIRS = the arrival beacon on dest floor
    for (int i = stairsIdx + 1; i < _result!.path.length; i++) {
      if (_result!.path[i].beaconMac != 'STAIRS') {
        return _result!.path[i].beaconMac.toUpperCase();
      }
    }
    return null;
  }

  /// Returns true ONLY when the user has physically arrived at the beacon
  /// on the DESTINATION floor — triggering the map switch.
  bool _isArrivalBeaconOnDestFloor(String mac) {
    if (_currentFloor == _destFloor) return false;
    final arrival = _destFloorArrivalBeacon;
    if (arrival == null) return false;
    return mac.toUpperCase() == arrival;
  }

  /// Instruction to show BEFORE the user takes the stairs
  /// (spoken when they are at the starting-floor stairs beacon).
  String _buildStairsInstruction(String mac) {
    final up = mac.toUpperCase();
    final isLeftOfficesF4 = up == 'C8:93:08:09:B2:CA';
    final isElevatorF5 = up == _elevatorF5.toUpperCase();
    final isJunction = up == _junctionF4.toUpperCase() ||
        up == _junctionF5.toUpperCase();
    final goingUp = _destFloor > _currentFloor;
    final ud = goingUp ? 'UP' : 'DOWN';

    if (isLeftOfficesF4) {
      return 'You are at the main stairs on Floor 4. '
          'Take the stairs $ud to Floor $_destFloor.';
    } else if (isElevatorF5) {
      return 'You are at the elevator on Floor 5. '
          'Take the elevator $ud to Floor $_destFloor.';
    } else if (isJunction) {
      return 'You are at the junction. '
          'Turn RIGHT toward the Back Stairs and go $ud to Floor $_destFloor.';
    } else {
      return 'Take the stairs $ud to Floor $_destFloor.';
    }
  }

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
      stepsToRender = allSteps.sublist(0, stairsIdx);
      if (stepsToRender.isEmpty) {
        final b = BeaconService().currentBeacon;
        final startPos = b != null ? _beaconScreenPos(b.mac) : const Offset(0.41, 0.28);
        // If user is at Left Offices F4 (stairs location), just show short upward arrow
        final isAtLeftOfficesF4 = b?.mac.toUpperCase() == 'C8:93:08:09:B2:CA';
        if (isAtLeftOfficesF4) {
          _routeWaypoints = [startPos, Offset(startPos.dx, startPos.dy - 0.06)];
          return;
        }
        final stairsStep = allSteps[stairsIdx];
        final isMainStairs = stairsStep.location.toLowerCase().contains('main') ||
            stairsStep.location.toLowerCase().contains('elevator');
        final stairsPos = isMainStairs ? const Offset(0.41, 0.28) : const Offset(0.57, 0.55);
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

    // Are we on the starting floor of a cross-floor route?
    // If yes, the line must end at the STAIRS position, not the destination room.
    final isStartingFloor = stairsIdx >= 0 && _currentFloor != _destFloor;

    // Stairs position on the current floor:
    // Main stairs = elevator beacon position (0.41, 0.28)
    // Back stairs = junction beacon position (0.57, 0.55)
    Offset _stairsEndPos() {
      if (stairsIdx <= 0) return const Offset(0.41, 0.28);
      final stairsEntry = allSteps[stairsIdx - 1];
      final mac = stairsEntry.beaconMac.toUpperCase();
      final isJunction = mac == 'E5:65:DD:D0:91:EC' || mac == 'C7:A4:5A:D0:74:D8';
      final isElevatorF5 = mac == 'F4:7B:74:76:D5:8A';
      final isLeftOfficesF4 = mac == 'C8:93:08:09:B2:CA';
      if (isJunction) return const Offset(0.44, 0.55);
      if (isElevatorF5) return const Offset(0.25, 0.28);
      if (isLeftOfficesF4) return const Offset(0.25, 0.35);

      return const Offset(0.41, 0.28);
    }

    for (int i = 0; i < steps.length; i++) {
      if (i < steps.length - 1) {
        final key = '${steps[i].beaconMac}→${steps[i + 1].beaconMac}';
        final pts = _corridorPaths[key];
        if (pts != null) {
          for (int j = 1; j < pts.length; j++) _routeWaypoints.add(pts[j]);
        } else {
          _routeWaypoints.add(_beaconScreenPos(steps[i + 1].beaconMac));
        }
      } else {
        // Last step — draw to stairs if starting floor, otherwise to destination
        if (isStartingFloor) {
          _routeWaypoints.add(_stairsEndPos());
        } else {
          _addDestinationPath(steps[i].beaconMac, widget.roomNumber, destPos);
        }
      }
    }

    if (!isStartingFloor) {
      if (_routeWaypoints.isEmpty || _routeWaypoints.last != destPos) {
        _routeWaypoints.add(destPos);
      }
    }

    final List<Offset> distinct = [];
    for (var p in _routeWaypoints) {
      if (distinct.isEmpty || (distinct.last.dx - p.dx).abs() > 0.001 || (distinct.last.dy - p.dy).abs() > 0.001) {
        distinct.add(p);
      }
    }
    // If after deduplication we only have 1 point (user is already at stairs),
    // add a small visual endpoint just above to show a short upward arrow
    if (distinct.length == 1) {
      distinct.add(Offset(distinct[0].dx, distinct[0].dy + 0.06));
    }
    _routeWaypoints = distinct;
  }

  void _addDestinationPath(String fromMac, String dest, Offset destPos) {
    const topLeftCorner = Offset(0.25, 0.28);
    const topRightCorner = Offset(0.65, 0.28);
    const bottomJunction = Offset(0.57, 0.55);
    const bottomLeftElbow = Offset(0.44, 0.55);
    const bottomRightElbow = Offset(0.75, 0.55);

    final isFromElevator = fromMac == 'C6:2A:90:A1:99:CB' || fromMac == 'F4:7B:74:76:D5:8A';
    final isFromJunction = fromMac == 'E5:65:DD:D0:91:EC' || fromMac == 'C7:A4:5A:D0:74:D8';
    final isFromLeftWing = fromMac == 'C8:93:08:09:B2:CA' || fromMac == 'F3:55:BD:A3:65:2E';

    bool isLeftWing(String d) => d.startsWith('42') || d.startsWith('43') ||
        (d.startsWith('52') && d.length == 3 && int.tryParse(d) != null && int.parse(d) >= 526);
    bool isMainCorridor(String d) => ['401','402','403','404','419','418','417','416',
      '501','502','503','521','520',
      '522','523','524','525',
      '420','421','422','423',
      '4WC','4WC2','5WC'].contains(d);
    bool isBottomRight(String d) => d.startsWith('409') || d.startsWith('41') || d.startsWith('512') ||
        d.startsWith('513') || d.startsWith('514') || d.startsWith('515') ||
        d.startsWith('516') || d.startsWith('517') || d.startsWith('518') || d.startsWith('519');
    bool isBottomLeft(String d) => ['406','407','504','505','506','507','508','509','510','5WC2'].contains(d);

    if (isLeftWing(dest)) {
      if (isFromJunction) {
        // Junction → left wing: go up-right to top-right, across to top-left, then down
        _routeWaypoints.add(Offset(topRightCorner.dx, 0.55));
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(topLeftCorner);
      } else if (!isFromLeftWing) {
        // Elevator → left wing: go left along top to top-left corner
        _routeWaypoints.add(topLeftCorner);
      }
      // Left wing → left wing: go straight down, no corners needed
      _routeWaypoints.add(destPos);

    } else if (isMainCorridor(dest)) {
      if (isFromLeftWing) {
        // Left wing → main corridor: up to top-left, across to top-right, then down to room
        _routeWaypoints.add(topLeftCorner);
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(destPos);
      } else if (isFromJunction) {
        // Junction → main corridor: walk back through corridor center
        const corridorCenterX = 0.63;
        _routeWaypoints.add(const Offset(corridorCenterX, 0.55));
        _routeWaypoints.add(Offset(corridorCenterX, destPos.dy));
        _routeWaypoints.add(destPos);
      } else {
        // Elevator → main corridor: go right along top, then down to room
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(destPos);
      }

    } else if (isBottomRight(dest)) {
      if (isFromJunction) {
        // Already at junction — go directly to right elbow then room
        _routeWaypoints.add(bottomRightElbow);
        _routeWaypoints.add(destPos);
      } else if (isFromLeftWing) {
        // Left wing → bottom right: up to top-left, across top, down to junction,
        // right elbow, then straight down to room's y-level, then across to room
        _routeWaypoints.add(topLeftCorner);
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(bottomJunction);
        _routeWaypoints.add(bottomRightElbow);
        _routeWaypoints.add(Offset(bottomRightElbow.dx, destPos.dy));
        _routeWaypoints.add(destPos);
      } else {
        // Elevator → bottom right: across top, down to junction, right elbow,
        // straight down to room's y-level, then across to room
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(bottomJunction);
        _routeWaypoints.add(bottomRightElbow);
        _routeWaypoints.add(Offset(bottomRightElbow.dx, destPos.dy));
        _routeWaypoints.add(destPos);
      }

    } else if (isBottomLeft(dest)) {
      if (isFromJunction) {
        // Already at junction — go directly to left elbow then room
        _routeWaypoints.add(bottomLeftElbow);
        _routeWaypoints.add(destPos);
      } else if (isFromLeftWing) {
        _routeWaypoints.add(topLeftCorner);
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(bottomJunction);
        _routeWaypoints.add(bottomLeftElbow);
        _routeWaypoints.add(Offset(bottomLeftElbow.dx, destPos.dy));
        _routeWaypoints.add(destPos);
      } else {
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(bottomJunction);
        _routeWaypoints.add(bottomLeftElbow);
        _routeWaypoints.add(Offset(bottomLeftElbow.dx, destPos.dy));
        _routeWaypoints.add(destPos);
      }

    } else if (dest == '408' || dest == '511') {
      if (isFromJunction) {
        // Already at junction — destination IS the junction
        _routeWaypoints.add(destPos);
      } else if (isFromLeftWing) {
        // Left wing → 408/511: up to top-left, across top, down to junction
        _routeWaypoints.add(topLeftCorner);
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(Offset(topRightCorner.dx, 0.55));
        _routeWaypoints.add(destPos);
      } else {
        // Elevator → 408/511: across top, down to junction
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(Offset(topRightCorner.dx, 0.55));
        _routeWaypoints.add(destPos);
      }

    } else {
      // Fallback
      if (isFromLeftWing) {
        _routeWaypoints.add(topLeftCorner);
        _routeWaypoints.add(topRightCorner);
      } else if (isFromJunction) {
        _routeWaypoints.add(Offset(topRightCorner.dx, 0.55));
        _routeWaypoints.add(topRightCorner);
        _routeWaypoints.add(topLeftCorner);
      }
      _routeWaypoints.add(destPos);
    }
  }

  Offset _calcPinPos(BeaconService svc) {
    final b = svc.currentBeacon;
    if (b == null || _routeWaypoints.isEmpty) {
      return _routeWaypoints.isNotEmpty ? _routeWaypoints.first : const Offset(0.41, 0.28);
    }
    final currentPos = _beaconScreenPos(b.mac);
    final rssi = svc.currentRssi ?? -70;
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
    _currentFloor = BeaconService().currentBeacon?.floor ?? _destFloor;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.4).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _routeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _routeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _routeCtrl, curve: Curves.easeInOut));
    _sheetCtrl = DraggableScrollableController();
    _tts.setVolume(1.0);
    BeaconService().startContinuousScanning();
    _loadRoute();
  }

  @override
  void dispose() {
    _tts.stop();
    _pulseCtrl.dispose();
    _routeCtrl.dispose();
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.reset();
    }
    _sheetCtrl.dispose();
    BeaconService().stopContinuousScanning();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    final svc = BeaconService();
    BeaconModel? b = svc.currentBeacon ?? await svc.detectCurrentLocation(durationSeconds: 2);
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';    if (apiKey.isEmpty) {
      setState(() {
        _state = _NavState.preview;
        _error = 'Demo mode';
        _currentFloor = b?.floor ?? 4;
      });
      _buildRouteWaypoints();
      _routeCtrl.forward();
      return;
    }
    final result = await NavigationService().navigate(
      currentBeaconMac: b?.mac ?? 'C6:2A:90:A1:99:CB',
      currentFloor: b?.floor ?? 4,
      destinationNumber: widget.roomNumber,
      apiKey: apiKey,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _state = _NavState.preview;
      _currentFloor = b?.floor ?? 4;
    });
    _buildRouteWaypoints();
    _routeCtrl.forward();
  }

  void _start() async {
    final svc = context.read<BeaconService>();
    await svc.checkHardwareOrExit();
    _logNavigation();

    // ── 1-STEP ROUTE: skip direction panel, show arrived immediately ─────
    final realSteps = _result?.path
        .where((s) => s.beaconMac != 'STAIRS')
        .toList() ?? [];
    if (realSteps.length == 1) {
      _speak('${realSteps[0].instruction}. You have arrived.');
      setState(() {
        _state = _NavState.arrived;
        _step = 0;
      });
      BeaconService().startContinuousScanning();
      return;
    }

    setState(() {
      _state = _NavState.active;
      _stairsTransitionFired = false;
      _step = 0;
    });
    _prevRssi = null;
    _offRouteCount = 0;
    _lastSpokenMac = null;
    _lastBeaconMatchTime = null;
    BeaconService().startContinuousScanning();
  }

  void _recalcRoute() {
    setState(() {
      _state = _NavState.loading;
      _step = 0;
      _offRouteCount = 0;
      _stairsTransitionFired = false;
    });
    _speak('Recalculating route.');
    _loadRoute().then((_) { if (mounted && _state == _NavState.preview) _start(); });
  }

  // ── MAP SWITCH: Called when user is detected on the DESTINATION FLOOR ──────
  // At this point the user has physically taken the stairs/elevator.
  // We switch the map, advance to the first step on the dest floor,
  // and speak that step's instruction.
  void _handleStairsBeaconDetected(String mac) {
    if (_stairsTransitionFired) return;
    _stairsTransitionFired = true;

    final stairsIdx = _result?.path.indexWhere((s) => s.beaconMac == 'STAIRS') ?? -1;
    final afterStairsIdx = stairsIdx >= 0 ? stairsIdx + 1 : _step + 1;

    // Recreate the sheet controller to avoid "already attached" crash
    // when the active sheet rebuilds after the floor switch
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.reset();
    }
    _sheetCtrl.dispose();
    _sheetCtrl = DraggableScrollableController();

    setState(() {
      _currentFloor = _destFloor;
      _buildRouteWaypoints();
      _routeCtrl.forward(from: 0);
      if (_result != null && afterStairsIdx < _result!.path.length) {
        _step = afterStairsIdx;
      }
    });

    // Speak the first instruction on the destination floor
    // BUT if it's also the last step, don't speak it — it will show on arrived panel
    if (_result != null && afterStairsIdx < _result!.path.length) {
      final nextStep = _result!.path[afterStairsIdx];
      final lastRealStepIndex = _result!.path.lastIndexWhere(
              (s) => s.beaconMac != 'STAIRS');
      final isLastStep = afterStairsIdx == lastRealStepIndex;
      if (!isLastStep) {
        _speak(nextStep.instruction);
      }
      _lastSpokenMac = nextStep.beaconMac;
    }
  }

  IconData _dirIcon(String d) {
    switch (d.toLowerCase()) {
      case 'left': return Icons.turn_left_rounded;
      case 'right': return Icons.turn_right_rounded;
      case 'up': return Icons.north_rounded;
      case 'down': return Icons.south_rounded;
      default: return Icons.straight_rounded;
    }
  }

  String _dirLabel(String d) {
    switch (d.toLowerCase()) {
      case 'left': return 'Turn left';
      case 'right': return 'Turn right';
      case 'up': return 'Go upstairs';
      case 'down': return 'Go downstairs';
      default: return 'Go straight';
    }
  }

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

    // ── LIVE STEP TRACKING ────────────────────────────────────────────────
    if (_state == _NavState.active && beacon != null && _result != null && _result!.success) {
      final isCrossFloor = _result!.path.any((s) => s.beaconMac == 'STAIRS');

      if (isCrossFloor && !_stairsTransitionFired) {
        final mac = beacon.mac;
        final stairsIdx = _result!.path.indexWhere((s) => s.beaconMac == 'STAIRS');
        final stairsEntryStep = stairsIdx > 0 ? _result!.path[stairsIdx - 1] : null;

        // ── STEP 1: User is at the STARTING-FLOOR stairs beacon ─────────
        // Only speak the stairs instruction here — skip normal step tracker
        // for this beacon so there's no conflict.
        if (stairsEntryStep != null &&
            mac.toUpperCase() == stairsEntryStep.beaconMac.toUpperCase() &&
            _lastSpokenMac != mac) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _state != _NavState.active) return;
            // Speak the hardcoded stairs instruction (not the AI-generated one)
            _speak(_buildStairsInstruction(mac));
            _lastSpokenMac = mac;
            // Show the STAIRS virtual step in the panel — it has the correct
            // direction (up/down) and a clean instruction, not the AI room text
            setState(() => _step = stairsIdx);
          });
        }

        // ── STEP 2: User has physically crossed to DESTINATION FLOOR ────
        if (_isArrivalBeaconOnDestFloor(mac)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _state != _NavState.active) return;
            _handleStairsBeaconDetected(mac);
          });
        }
      }

      // ── Check if current beacon is the stairs-entry beacon ───────────────
      // If so, skip the normal step tracking entirely — the stairsEntryStep
      // block above already handles speaking and setting _step to STAIRS index.
      final _stairsIdx2 = _result!.path.indexWhere((s) => s.beaconMac == 'STAIRS');
      final _stairsEntryMac = _stairsIdx2 > 0
          ? _result!.path[_stairsIdx2 - 1].beaconMac.toUpperCase()
          : null;
      final _isAtStairsEntry = isCrossFloor &&
          !_stairsTransitionFired &&
          _stairsEntryMac != null &&
          beacon.mac.toUpperCase() == _stairsEntryMac;

      bool found = false;
      if (!_isAtStairsEntry) for (int i = 0; i < _result!.path.length; i++) {
        final stepData = _result!.path[i];
        if (stepData.beaconMac == 'STAIRS') continue;

        if (stepData.beaconMac.toUpperCase() == beacon.mac.toUpperCase()) {
          found = true;

          // ── CORRECT isLastStep definition ────────────────────────────────
          // The last REAL step is the one with the highest index among all
          // non-STAIRS steps. This ensures an intermediate beacon (like the
          // elevator in a 2-step route) is never treated as "arrived".
          final lastRealStepIndex = _result!.path.lastIndexWhere(
                  (s) => s.beaconMac != 'STAIRS');
          final bool isLastStep = i == lastRealStepIndex;

          if (i != _step || _lastSpokenMac != beacon.mac) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _offRouteCount = 0;
              // Set match time immediately so dwell starts counting now
              _lastBeaconMatchTime = DateTime.now();

              if (_lastSpokenMac != beacon.mac) {
                _lastSpokenMac = beacon.mac;
                // Don't speak the last step here — it will be shown on arrived panel
                if ((!_stairsTransitionFired || _currentFloor == _destFloor) && !isLastStep) {
                  _speak(stepData.instruction);
                }
              }

              setState(() => _step = i);

              // Arrived: fire immediately on last beacon detection
              if (isLastStep && _currentFloor == _destFloor) {
                _speak("${stepData.instruction}. You have arrived.");
                setState(() => _state = _NavState.arrived);
              }
            });
          } else if (isLastStep && _currentFloor == _destFloor && _state == _NavState.active) {
            // Already matched this step in a previous scan cycle.
            // Check dwell — if 3s have passed since we first matched, arrive.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _state != _NavState.active) return;
              if (_lastBeaconMatchTime != null) {
                final sinceMatch = DateTime.now().difference(_lastBeaconMatchTime!);
                _speak("${stepData.instruction}. You have arrived.");
                setState(() => _state = _NavState.arrived);
              }
            });
          }
          break;
        }
      }

      if (!_isAtStairsEntry && !found && beacon.mac != (_lastSpokenMac ?? '')) {
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
        Positioned.fill(child: Image.asset('assets/images/map.png', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _bg))),

        if (_state != _NavState.loading && _routeWaypoints.length >= 2)
          Positioned.fill(child: AnimatedBuilder(
              animation: _routeAnim,
              builder: (_, __) => CustomPaint(painter: _WaypointRoutePainter(
                  waypoints: _routeWaypoints,
                  progress: _routeAnim.value,
                  liveProgress: _state == _NavState.active ? _routeProgress : 0,
                  isActive: _state == _NavState.active)))),

        // Room labels
        ...floorRooms.map((r) {
          final pos = roomPosMap[r.number];
          if (pos == null) return const SizedBox.shrink();
          final isDest = r.number == widget.roomNumber;
          return Positioned(
              left: size.width * pos.dx - 18,
              top: size.height * pos.dy - 9,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: isDest ? _primary : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: isDest ? 0.18 : 0.08),
                          blurRadius: isDest ? 6 : 3,
                          offset: const Offset(0, 1))]),
                  child: Text(
                      r.number.contains('WC') ? 'WC' : r.number,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDest ? Colors.white : _text))));
        }),

        // User pin
        if (beacon != null)
          Positioned(
            left: size.width * pinPos.dx - 20,
            top: size.height * pinPos.dy - 38,
            child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Stack(alignment: Alignment.center, children: [
                  Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primary.withValues(alpha: 0.15)))),
                  Image.asset('assets/images/pin1.png', width: 32, height: 32, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primary,
                              border: Border.all(color: Colors.white, width: 2)))),
                ])),
          ),

        // Time badge
        if ((_state == _NavState.preview || _state == _NavState.active) && _routeWaypoints.length >= 2)
          Positioned(
              left: size.width * _routeWaypoints[_routeWaypoints.length ~/ 2].dx - 20,
              top: size.height * _routeWaypoints[_routeWaypoints.length ~/ 2].dy - 24,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(9999)),
                  child: Text('$time min',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),

        // Header
        Positioned(top: 0, left: 0, right: 0,
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2))]),
                padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + 8, 0, 0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.arrow_back_rounded, color: _text, size: 22),
                            padding: const EdgeInsets.only(top: 10)),
                        Expanded(child: Column(children: [
                          Container(
                              height: 42,
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: _bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _border)),
                              child: Row(children: [
                                Container(width: 8, height: 8,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _primary)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(
                                    beacon != null
                                        ? beacon.location.replaceAll('Floor ${beacon.floor} - ', '')
                                        : 'Your location',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: beacon != null ? _primary : _muted),
                                    overflow: TextOverflow.ellipsis)),
                              ])),
                          Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: _bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _primary)),
                              child: Row(children: [
                                Image.asset('assets/images/pin1.png', width: 18, height: 18, fit: BoxFit.contain),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                    _resolveDestinationName(),
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, fontWeight: FontWeight.w500, color: _text),
                                    overflow: TextOverflow.ellipsis)),
                                Text('F$_destFloor',
                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _muted)),
                              ])),
                        ])),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.swap_vert_rounded, color: _muted, size: 22),
                            padding: const EdgeInsets.only(top: 20)),
                      ])),
                  const SizedBox(height: 8),
                  Container(height: 1, color: _border),
                ]))),

        // State overlays
        if (_state == _NavState.loading) _buildLoading(),
        if (_state == _NavState.preview) _buildPreview(room, dist, time),
        if (_state == _NavState.active) _buildActiveSheet(room, beaconSvc),
        if (_state == _NavState.arrived) _buildArrivedOverlay(room),
        if (_state == _NavState.offRoute) _buildOffRouteOverlay(),
      ]),
    );
  }

  Widget _buildLoading() => Positioned(
      bottom: 0, left: 0, right: 0, height: 180,
      child: Container(
          decoration: _cardDeco(),
          child: const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5))));

  Widget _buildPreview(RoomModel? room, int dist, int time) => Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
          decoration: _cardDeco(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(
                    width: 32, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(9999)))),
                RichText(text: TextSpan(children: [
                  TextSpan(text: '$time min ',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _primary)),
                  TextSpan(text: '(${dist}m)',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w400, color: _text)),
                ])),
                const SizedBox(height: 2),
                Text('Indoor navigation via BLE beacons',
                    style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
                // Show floor-change indicator in preview
                if (_currentFloor != _destFloor)
                  Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(children: [
                        Icon(Icons.swap_vert_rounded, size: 14, color: _primary),
                        const SizedBox(width: 4),
                        Text('Floor $_currentFloor → Floor $_destFloor',
                            style: GoogleFonts.poppins(fontSize: 11, color: _primary, fontWeight: FontWeight.w600)),
                      ])),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_error!,
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFF59E0B)))),
                const SizedBox(height: 16),
                GestureDetector(
                    onTap: _start,
                    child: Container(
                        width: double.infinity, height: 50,
                        decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                                color: _primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3))]),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Start Navigation',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]))),
                const SizedBox(height: 16),
              ]))));

  Widget _buildActiveSheet(RoomModel? room, BeaconService svc) {
    if (_sheetCtrl.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_sheetCtrl.isAttached) {
          _sheetCtrl = DraggableScrollableController();
        }
      });
    }
    final has = _result != null && _result!.success && _result!.path.isNotEmpty;
    final total = has ? _result!.path.length : 1;

    NavigationStep? step;
    if (has && _step < _result!.path.length) {
      step = _result!.path[_step];
    }

    final lastRealStepIndex = _result?.path.lastIndexWhere(
            (s) => s.beaconMac != 'STAIRS') ?? -1;
    final isLastRealStep = has && _step == lastRealStepIndex;

    // For the STAIRS virtual step, show a special direction
    final isStairsStep = step?.beaconMac == 'STAIRS';
    final String instr;
    final String dir;
    if (isStairsStep) {
      instr = step!.instruction;
      dir = step.direction;
    } else if (isLastRealStep) {
      instr = step?.instruction ?? '';
      dir = step?.direction ?? 'forward';
    } else {
      instr = step?.instruction ?? 'Walking toward ${widget.roomNumber}...';
      dir = step?.direction ?? 'forward';
    }

    final beaconObj = svc.currentBeacon;

    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: 0.2,
        minChildSize: 0.12,
        maxChildSize: 0.50,
        snap: true,
        snapSizes: const [0.12, 0.30, 0.50],
        builder: (context, scrollCtrl) => Material(
          color: Colors.transparent,
          child: Container(
            decoration: _cardDeco(),
            child: ListView.builder(
              controller: scrollCtrl,
              padding: EdgeInsets.zero,
              addSemanticIndexes: false,
              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.transparent,
                    child: Center(child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                            color: _border, borderRadius: BorderRadius.circular(10)))),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Progress bar
                    Container(
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: LinearProgressIndicator(
                                value: ((_step + 1) / total),
                                backgroundColor: _border,
                                valueColor: AlwaysStoppedAnimation(_primary)))),
                    // Status row
                    Row(children: [
                      Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: beaconObj != null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))),
                      const SizedBox(width: 8),
                      Text(
                          beaconObj != null
                              ? 'Live · Floor ${_currentFloor}'
                              : 'Scanning...',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: beaconObj != null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))),
                      const Spacer(),
                      Text('Step ${_step + 1} of $total',
                          style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                    ]),
                    const SizedBox(height: 16),
                    // Direction card — highlight stairs step differently
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                              color: isStairsStep ? const Color(0xFFF59E0B) : _primary,
                              borderRadius: BorderRadius.circular(16)),
                          child: Icon(_dirIcon(dir), color: Colors.white, size: 28)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_dirLabel(dir),
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
                        const SizedBox(height: 4),
                        Text(instr,
                            style: GoogleFonts.poppins(fontSize: 14, color: _muted, height: 1.4)),
                      ])),
                    ]),
                    const SizedBox(height: 24),
                    GestureDetector(
                        onTap: () { _tts.stop(); widget.onClose(); },
                        child: Container(
                            width: double.infinity, height: 48,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border, width: 1.5)),
                            child: Center(child: Text('Cancel Navigation',
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: _muted))))),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrivedOverlay(RoomModel? room) {
    final realSteps = _result?.path
        .where((s) => s.beaconMac != 'STAIRS')
        .toList() ?? [];
    final isOneStep = realSteps.length == 1;
    final lastStep = realSteps.isNotEmpty ? realSteps.last : null;

    // Always show the final direction for 1-step routes —
    // that single instruction IS the only guidance the user gets.
    // For multi-step routes, hide it only when the destination sits
    // exactly on a beacon (408/511) because the user is already there.
    final showFinalDirection = lastStep != null && lastStep.beaconMac != 'STAIRS';
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
                    offset: const Offset(0, 10))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (showFinalDirection) ...[
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(_dirIcon(lastStep!.direction), color: _primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(lastStep.instruction,
                          style: GoogleFonts.poppins(fontSize: 13, color: _text, height: 1.4))),
                    ])),
                const SizedBox(height: 16),
                Container(height: 1, color: _border),
                const SizedBox(height: 16),
              ],
              Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)),
              const SizedBox(height: 16),
              Text("You've arrived!",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
              const SizedBox(height: 6),
              Text(_resolveDestinationName(),
                  style: GoogleFonts.poppins(fontSize: 14, color: _muted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                      width: double.infinity, height: 50,
                      decoration: BoxDecoration(
                          color: _primary, borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text('Done',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))))),
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
                              fontSize: 14, fontWeight: FontWeight.w600, color: _muted))))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildOffRouteOverlay() => Positioned.fill(
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
                          offset: const Offset(0, 10))]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFF59E0B), size: 40)),
                    const SizedBox(height: 16),
                    Text('Off Route',
                        style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
                    const SizedBox(height: 6),
                    Text('You seem to have taken a wrong turn.\nWould you like to recalculate your route?',
                        style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    GestureDetector(
                        onTap: _recalcRoute,
                        child: Container(
                            width: double.infinity, height: 50,
                            decoration: BoxDecoration(
                                color: _primary, borderRadius: BorderRadius.circular(14)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('Recalculate Route',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            ]))),
                    const SizedBox(height: 10),
                    GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                            width: double.infinity, height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border, width: 1.5)),
                            child: Center(child: Text('Cancel Navigation',
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: _muted))))),
                  ])))));

  BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, -6))]);
}

class _WaypointRoutePainter extends CustomPainter {
  final List<Offset> waypoints;
  final double progress, liveProgress;
  final bool isActive;
  static const _primary = Color(0xFF007A6E);

  const _WaypointRoutePainter({
    required this.waypoints,
    required this.progress,
    this.liveProgress = 0,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.length < 2) return;
    final path = Path();
    path.moveTo(size.width * waypoints[0].dx, size.height * waypoints[0].dy);
    for (int i = 1; i < waypoints.length; i++) {
      path.lineTo(size.width * waypoints[i].dx, size.height * waypoints[i].dy);
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    double totalLen = 0;
    for (final m in metrics) totalLen += m.length;

    if (isActive && liveProgress > 0) {
      final completedLen = totalLen * liveProgress;
      double drawn = 0;
      for (final m in metrics) {
        final done = (completedLen - drawn).clamp(0.0, m.length);
        if (done > 0) {
          canvas.drawPath(m.extractPath(0, done),
              Paint()
                ..color = _primary
                ..strokeWidth = 6
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke);
        }
        if (done < m.length) {
          double d = done;
          while (d < m.length) {
            canvas.drawPath(
                m.extractPath(d, (d + 8).clamp(0, m.length)),
                Paint()
                  ..color = _primary.withValues(alpha: 0.3)
                  ..strokeWidth = 4
                  ..strokeCap = StrokeCap.round
                  ..style = PaintingStyle.stroke);
            d += 16;
          }
        }
        drawn += m.length;
      }
    } else {
      final animLen = totalLen * progress;
      double drawn = 0;
      for (final m in metrics) {
        final segLen = (animLen - drawn).clamp(0.0, m.length);
        if (segLen <= 0) break;
        double d = 0;
        while (d < segLen) {
          canvas.drawPath(
              m.extractPath(d, (d + 8).clamp(0, segLen)),
              Paint()
                ..color = _primary.withValues(alpha: 0.6)
                ..strokeWidth = 4
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke);
          d += 16;
        }
        drawn += m.length;
      }
    }
  }

  @override
  bool shouldRepaint(_WaypointRoutePainter old) =>
      old.progress != progress ||
          old.liveProgress != liveProgress ||
          old.waypoints.length != waypoints.length;
}