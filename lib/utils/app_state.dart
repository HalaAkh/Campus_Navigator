import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/rooms.dart';
import '../services/beacon_service.dart';
import '../services/navigation_service.dart';

class AppState extends ChangeNotifier {
  // Auth
  // start empty — will be set after sign-in or sign-up
  String _userName = '';
  String _userEmail = '';
  String get userName => _userName;
  String get userEmail => _userEmail;

  bool get isLoggedIn => _userEmail.isNotEmpty;

  /// Set user fields from a Firebase [User]. Pass null to clear.
  void setUserFromAuth(User? user) {
    if (user == null) return clearUser();
    setUser(user.displayName ?? '', user.email ?? '');
  }

  void clearUser() {
    _userName = '';
    _userEmail = '';
    notifyListeners();
  }

  void setUser(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  // Beacon / Location
  BeaconModel? _currentBeacon;
  bool _isScanning = false;

  BeaconModel? get currentBeacon => _currentBeacon;
  bool get isScanning => _isScanning;
  int get currentFloor => _currentBeacon?.floor ?? 4;
  String get currentLocationLabel => _currentBeacon?.location ?? 'Unknown Location';
  int get activeBeaconCount => _currentBeacon != null ? 3 : 0;

  void setCurrentBeacon(BeaconModel? beacon) {
    _currentBeacon = beacon;
    notifyListeners();
  }

  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // Navigation
  NavigationResult? _currentRoute;
  int _currentStep = 0;
  RoomModel? _destinationRoom;

  NavigationResult? get currentRoute => _currentRoute;
  int get currentStep => _currentStep;
  RoomModel? get destinationRoom => _destinationRoom;

  bool get isNavigating => _currentRoute != null && _currentRoute!.success;

  void startNavigation(NavigationResult result, RoomModel destination) {
    _currentRoute = result;
    _currentStep = 0;
    _destinationRoom = destination;
    notifyListeners();
  }

  void nextStep() {
    if (_currentRoute != null && _currentStep < _currentRoute!.path.length - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void endNavigation() {
    _currentRoute = null;
    _currentStep = 0;
    _destinationRoom = null;
    notifyListeners();
  }

  bool get isLastStep =>
      _currentRoute != null && _currentStep >= _currentRoute!.path.length - 1;

  NavigationStep? get currentStepData {
    if (_currentRoute == null || _currentRoute!.path.isEmpty) return null;
    if (_currentStep >= _currentRoute!.path.length) return null;
    return _currentRoute!.path[_currentStep];
  }

  double get progressPercent {
    if (_currentRoute == null || _currentRoute!.path.isEmpty) return 0;
    return (_currentStep + 1) / _currentRoute!.path.length;
  }

  // Saved Rooms
  List<RoomModel> _savedRooms = [
    getRoomByNumber('408')!,
    getRoomByNumber('516')!,
    getRoomByNumber('522')!,
  ];

  List<RoomModel> get savedRooms => _savedRooms;

  void saveRoom(RoomModel room) {
    if (!_savedRooms.any((r) => r.number == room.number)) {
      _savedRooms = [..._savedRooms, room];
      notifyListeners();
    }
  }

  void removeRoom(String number) {
    _savedRooms = _savedRooms.where((r) => r.number != number).toList();
    notifyListeners();
  }

  bool isRoomSaved(String number) => _savedRooms.any((r) => r.number == number);

  // Settings
  int _defaultFloor = 4;
  bool _autoDetect = true;
  bool _showBeaconZones = true;
  bool _bgScanning = false;
  bool _largeText = false;
  bool _highContrast = false;
  bool _reducedMotion = false;

  int get defaultFloor => _defaultFloor;
  bool get autoDetect => _autoDetect;
  bool get showBeaconZones => _showBeaconZones;
  bool get bgScanning => _bgScanning;
  bool get largeText => _largeText;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;

  void setDefaultFloor(int f) { _defaultFloor = f; notifyListeners(); }
  void setAutoDetect(bool v) { _autoDetect = v; notifyListeners(); }
  void setShowBeaconZones(bool v) { _showBeaconZones = v; notifyListeners(); }
  void setBgScanning(bool v) { _bgScanning = v; notifyListeners(); }
  void setLargeText(bool v) { _largeText = v; notifyListeners(); }
  void setHighContrast(bool v) { _highContrast = v; notifyListeners(); }
  void setReducedMotion(bool v) { _reducedMotion = v; notifyListeners(); }

  // Stats
  int _navigationCount = 12;
  int get navigationCount => _navigationCount;
  void incrementNavigationCount() { _navigationCount++; notifyListeners(); }
}
