import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BeaconModel {
  final String mac;
  final String location;
  final int floor;
  final String type;
  final List<String> connections;

  const BeaconModel({
    required this.mac,
    required this.location,
    required this.floor,
    required this.type,
    required this.connections,
  });
}

class DetectedBeacon {
  final BeaconModel beacon;
  final int rssi;
  DetectedBeacon({required this.beacon, required this.rssi});
}

class AppBeacons {
  static const List<BeaconModel> floor4 = [
    BeaconModel(mac: 'C6:2A:90:A1:99:CB', location: 'Floor 4 - Elevator/Stairs Junction', floor: 4, type: 'elevator', connections: ['E5:65:DD:D0:91:EC', 'C8:93:08:09:B2:CA']),
    BeaconModel(mac: 'E5:65:DD:D0:91:EC', location: 'Floor 4 - Room 408 Junction Area', floor: 4, type: 'corridor', connections: ['C6:2A:90:A1:99:CB']),
    BeaconModel(mac: 'C8:93:08:09:B2:CA', location: 'Floor 4 - Left Offices Corridor', floor: 4, type: 'corridor', connections: ['C6:2A:90:A1:99:CB']),
  ];

  static const List<BeaconModel> floor5 = [
    BeaconModel(mac: 'FC:17:8A:61:EC:6D', location: 'Floor 5 - Elevator/Stairs 1 Junction', floor: 5, type: 'elevator', connections: ['F3:55:BD:A3:65:2E', 'C7:A4:5A:D0:74:D8']),
    BeaconModel(mac: 'F3:55:BD:A3:65:2E', location: 'Floor 5 - Left Office Corridor', floor: 5, type: 'corridor', connections: ['FC:17:8A:61:EC:6D']),
    BeaconModel(mac: 'C7:A4:5A:D0:74:D8', location: 'Floor 5 - Room 511 Junction Area', floor: 5, type: 'corridor', connections: ['FC:17:8A:61:EC:6D']),
  ];

  static List<BeaconModel> get all => [...floor4, ...floor5];

  static BeaconModel? getByMac(String mac) {
    final upper = mac.toUpperCase().replaceAll('-', ':');
    try {
      return all.firstWhere((b) => b.mac.toUpperCase() == upper);
    } catch (_) {
      return null;
    }
  }
}

class StairConnections {
  static const Map<String, dynamic> primary = {
    'name': 'Main Stairs (Elevator Area)',
    'floor4_beacon': 'C6:2A:90:A1:99:CB',
    'floor5_beacon': 'FC:17:8A:61:EC:6D',
  };
  static const Map<String, dynamic> secondary = {
    'name': 'Back Stairs (Stairs 2)',
    'floor4_beacon': 'E5:65:DD:D0:91:EC',
    'floor5_beacon': 'C7:A4:5A:D0:74:D8',
  };
}

class BeaconService extends ChangeNotifier {
  static final BeaconService _instance = BeaconService._internal();
  factory BeaconService() => _instance;
  BeaconService._internal();

  BeaconModel? _currentBeacon;
  bool _isScanning = false;
  int _signalStrength = 0;
  List<DetectedBeacon> _nearbyBeacons = [];
  Timer? _continuousTimer;

  BeaconModel? get currentBeacon => _currentBeacon;
  bool get isScanning => _isScanning;
  int get signalStrength => _signalStrength;
  List<DetectedBeacon> get nearbyBeacons => _nearbyBeacons;
  int get currentFloor => _currentBeacon?.floor ?? 4;
  int get activeBeaconCount => _nearbyBeacons.length;

  Future<List<DetectedBeacon>> scanBleBeacons({int durationSeconds = 5}) async {
    _isScanning = true;
    notifyListeners();
    final List<DetectedBeacon> matched = [];
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('Bluetooth OFF');
        _isScanning = false;
        notifyListeners();
        return [];
      }
      final Map<String, int> rssiMap = {};
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final mac = r.device.remoteId.str.toUpperCase().replaceAll('-', ':');
          rssiMap[mac] = r.rssi;
        }
      });
      await FlutterBluePlus.startScan(timeout: Duration(seconds: durationSeconds));
      await Future.delayed(Duration(seconds: durationSeconds));
      await FlutterBluePlus.stopScan();
      subscription.cancel();
      for (final entry in rssiMap.entries) {
        final beacon = AppBeacons.getByMac(entry.key);
        if (beacon != null) {
          matched.add(DetectedBeacon(beacon: beacon, rssi: entry.value));
          debugPrint('FOUND: ${beacon.location} RSSI:${entry.value}');
        }
      }
    } catch (e) {
      debugPrint('BLE error: $e');
    }
    _isScanning = false;
    notifyListeners();
    return matched;
  }

  Future<BeaconModel?> detectCurrentLocation({int durationSeconds = 5}) async {
    final detected = await scanBleBeacons(durationSeconds: durationSeconds);
    if (detected.isEmpty) return null;
    detected.sort((a, b) => b.rssi.compareTo(a.rssi));
    final closest = detected.first;
    _currentBeacon = closest.beacon;
    _signalStrength = closest.rssi;
    _nearbyBeacons = detected;
    notifyListeners();
    return _currentBeacon;
  }

  void startContinuousScanning() {
    stopContinuousScanning();
    _continuousTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isScanning) await detectCurrentLocation(durationSeconds: 4);
    });
  }

  void stopContinuousScanning() {
    _continuousTimer?.cancel();
    _continuousTimer = null;
  }

  int calculateDistanceToStairs(String currentMac, String stairsMac, int floor) {
    final upper = currentMac.toUpperCase();
    final stairsUpper = stairsMac.toUpperCase();
    if (upper == stairsUpper) return 0;
    final beacons = floor == 4 ? AppBeacons.floor4 : AppBeacons.floor5;
    final current = beacons.cast<BeaconModel?>().firstWhere(
            (b) => b!.mac.toUpperCase() == upper, orElse: () => null);
    if (current != null && current.connections.any((c) => c.toUpperCase() == stairsUpper)) return 15;
    return 30;
  }

  String chooseBestStairs(String currentMac, int floor) {
    final primaryBeacon = floor == 4
        ? StairConnections.primary['floor4_beacon'] as String
        : StairConnections.primary['floor5_beacon'] as String;
    final secondaryBeacon = floor == 4
        ? StairConnections.secondary['floor4_beacon'] as String
        : StairConnections.secondary['floor5_beacon'] as String;
    final dPrimary = calculateDistanceToStairs(currentMac, primaryBeacon, floor);
    final dSecondary = calculateDistanceToStairs(currentMac, secondaryBeacon, floor);
    return dPrimary <= dSecondary ? 'primary' : 'secondary';
  }

  void setMockBeacon(BeaconModel beacon) {
    _currentBeacon = beacon;
    _signalStrength = -65;
    _nearbyBeacons = [DetectedBeacon(beacon: beacon, rssi: -65)];
    notifyListeners();
  }

  @override
  void dispose() {
    stopContinuousScanning();
    super.dispose();
  }
}