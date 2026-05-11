import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart' as gps;

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
  final double smoothedRssi;
  DetectedBeacon({required this.beacon, required this.rssi, required this.smoothedRssi});
}

class AppBeacons {
  static const List<BeaconModel> floor4 = [
    BeaconModel(mac: 'C6:2A:90:A1:99:CB', location: 'Floor 4 - Elevator/Stairs Junction- 4th Floor', floor: 4, type: 'elevator', connections: ['E5:65:DD:D0:91:EC', 'C8:93:08:09:B2:CA']),
    BeaconModel(mac: 'E5:65:DD:D0:91:EC', location: 'Floor 4 - Room 408 Junction Area', floor: 4, type: 'corridor', connections: ['C6:2A:90:A1:99:CB']),
    BeaconModel(mac: 'C8:93:08:09:B2:CA', location: 'Floor 4 - Left Offices Corridor- 4th Floor', floor: 4, type: 'corridor', connections: ['C6:2A:90:A1:99:CB']),
  ];

  static const List<BeaconModel> floor5 = [
    BeaconModel(mac: 'F4:7B:74:76:D5:8A', location: 'Floor 5 - Elevator/Stairs Junction- 5th Floor', floor: 5, type: 'elevator', connections: ['F3:55:BD:A3:65:2E', 'C7:A4:5A:D0:74:D8']),
    BeaconModel(mac: 'F3:55:BD:A3:65:2E', location: 'Floor 5 - Left Offices Corridor', floor: 5, type: 'corridor', connections: ['F4:7B:74:76:D5:8A']),
    BeaconModel(mac: 'C7:A4:5A:D0:74:D8', location: 'Floor 5 - Room 511 Junction Area', floor: 5, type: 'corridor', connections: ['F4:7B:74:76:D5:8A']),
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
    'floor5_beacon': 'F4:7B:74:76:D5:8A',
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

  BeaconService._internal() {
    _initHardwareMonitoring();
  }

  StreamSubscription? _scanSubscription;
  final Map<String, double> _emaRssi = {}; 
  static const double _alpha = 0.85;
  
  void _initHardwareMonitoring() {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.off ||
          state == BluetoothAdapterState.turningOff ||
          state == BluetoothAdapterState.unauthorized) {
        exit(0);
      }
    });

    gps.Location location = gps.Location();
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        bool isEnabled = await location.serviceEnabled();
        if (!isEnabled) exit(0);
      } catch (_) { exit(0); }
    });
  }

  Future<void> checkHardwareOrExit() async {
    gps.Location location = gps.Location();
    bool isLocationOn = await location.serviceEnabled();
    BluetoothAdapterState btState = await FlutterBluePlus.adapterState.first;
    if (!isLocationOn || btState != BluetoothAdapterState.on) exit(0);
  }

  BeaconModel? _currentBeacon;
  bool _isScanning = false;
  List<DetectedBeacon> _nearbyBeacons = [];
  int? _currentRssi;

  BeaconModel? get currentBeacon => _currentBeacon;
  bool get isScanning => _isScanning;
  List<DetectedBeacon> get nearbyBeacons => _nearbyBeacons;
  int? get currentRssi => _currentRssi;
  int get currentFloor => _currentBeacon?.floor ?? 4;

  void startContinuousScanning() async {
    await stopContinuousScanning();
    _isScanning = true;
    _emaRssi.clear();
    notifyListeners();

    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final now = DateTime.now();
      final List<DetectedBeacon> currentMatches = [];

      for (var r in results) {
        if (now.difference(r.timeStamp).inMilliseconds > 1000) continue;
        if (r.rssi < -85) continue;

        final mac = r.device.remoteId.str.toUpperCase().replaceAll('-', ':');
        final beacon = AppBeacons.getByMac(mac);
        if (beacon == null) continue;

        double currentEma = _emaRssi[mac] ?? r.rssi.toDouble();
        double updatedEma = (_alpha * r.rssi) + ((1 - _alpha) * currentEma);
        _emaRssi[mac] = updatedEma;

        currentMatches.add(DetectedBeacon(
          beacon: beacon,
          rssi: r.rssi,
          smoothedRssi: updatedEma,
        ));
      }

      if (currentMatches.isNotEmpty) {
        currentMatches.sort((a, b) => b.smoothedRssi.compareTo(a.smoothedRssi));
        _nearbyBeacons = currentMatches;

        final strongest = currentMatches.first;
        bool changed = false;
        
        if (_currentBeacon == null || strongest.beacon.mac != _currentBeacon!.mac) {
           double currentSmoothed = _emaRssi[_currentBeacon?.mac] ?? -100.0;
           if (strongest.smoothedRssi > (currentSmoothed + 2.0)) {
              _currentBeacon = strongest.beacon;
              changed = true;
           }
        }

        _currentRssi = strongest.smoothedRssi.toInt();
        if (changed) notifyListeners();
      }
    });
  }

  Future<void> stopContinuousScanning() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  Future<BeaconModel?> detectCurrentLocation({int durationSeconds = 3}) async {
    final List<DetectedBeacon> matched = [];
    final Map<String, int> rssiMap = {};
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final mac = r.device.remoteId.str.toUpperCase().replaceAll('-', ':');
        rssiMap[mac] = r.rssi;
      }
    });
    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: durationSeconds), 
      androidScanMode: AndroidScanMode.lowLatency
    );
    await Future.delayed(Duration(seconds: durationSeconds));
    await FlutterBluePlus.stopScan();
    await sub.cancel();
    for (final entry in rssiMap.entries) {
      final b = AppBeacons.getByMac(entry.key);
      if (b != null) matched.add(DetectedBeacon(beacon: b, rssi: entry.value, smoothedRssi: entry.value.toDouble()));
    }
    if (matched.isEmpty) return null;
    matched.sort((a, b) => b.rssi.compareTo(a.rssi));
    _currentBeacon = matched.first.beacon;
    _currentRssi = matched.first.rssi;
    notifyListeners();
    return _currentBeacon;
  }

  @override
  void dispose() {
    stopContinuousScanning();
    super.dispose();
  }
}
