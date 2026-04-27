import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/rooms.dart';
import '../services/beacon_service.dart';
import '../services/navigation_service.dart';
import '/services/rooms_service.dart';

class AppState extends ChangeNotifier {
  // Auth
  String _userName = '';
  String _userEmail = '';
  String get userName => _userName;
  String get userEmail => _userEmail;

  bool get isLoggedIn => _userEmail.isNotEmpty;

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

  // ── UPDATE DISPLAY NAME ──────────────────────────────────────────────────
  /// Updates the display name in Firebase Auth, Firestore, and local state.
  Future<void> updateUserName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Update Firebase Auth profile
      await user.updateDisplayName(newName);
      // Update Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': newName});
      // Update local state
      _userName = newName;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update username: $e');
      rethrow; // Let the UI handle and show an error if needed
    }
  }

  // ── UPDATE PASSWORD ──────────────────────────────────────────────────────
  /// Re-authenticates with [currentPassword] then updates to [newPassword].
  /// Throws a descriptive [Exception] on failure so the UI can show it.
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user found.');
    if (user.email == null) throw Exception('User has no email address.');

    try {
      // Re-authenticate — required by Firebase before sensitive operations
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Now update the password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: [${e.code}] msg: ${e.message}');
      final raw = '${e.code} ${e.message ?? ''}'.toLowerCase();
      if (raw.contains('wrong-password') ||
          raw.contains('invalid-credential') ||
          raw.contains('invalid_login_credentials') ||
          raw.contains('auth credential is incorrect') ||
          raw.contains('malformed or has expired')) {
        throw Exception('Current password is incorrect.');
      }
      if (raw.contains('weak-password')) {
        throw Exception('New password is too weak. Use at least 8 characters with uppercase, lowercase, number, and special character.');
      }
      if (raw.contains('requires-recent-login') || raw.contains('user-token-expired')) {
        throw Exception('Session expired. Please sign out and sign back in, then try again.');
      }
      if (raw.contains('too-many-requests')) {
        throw Exception('Too many failed attempts. Please wait a few minutes and try again.');
      }
      if (raw.contains('user-disabled')) {
        throw Exception('This account has been disabled. Contact support.');
      }
      throw Exception('Password update failed. Please try again.');
    } catch (e) {
      debugPrint('Failed to update password (raw): $e');
      final raw = e.toString().toLowerCase();
      // Firebase sometimes bypasses FirebaseAuthException on newer SDKs
      // and wraps the error in a PlatformException — catch by message content
      if (raw.contains('invalid-credential') ||
          raw.contains('invalid_login_credentials') ||
          raw.contains('wrong-password') ||
          raw.contains('signinwithpassword') ||
          raw.contains('auth credential is incorrect') ||
          raw.contains('malformed or has expired') ||
          raw.contains('recaptchaaction')) {
        throw Exception('Current password is incorrect.');
      }
      if (raw.contains('weak-password') || raw.contains('weak password')) {
        throw Exception('New password is too weak. Use at least 8 characters with uppercase, lowercase, number, and special character.');
      }
      if (raw.contains('requires-recent-login') || raw.contains('token-expired')) {
        throw Exception('Session expired. Please sign out and sign back in, then try again.');
      }
      if (raw.contains('too-many-requests') || raw.contains('too many')) {
        throw Exception('Too many failed attempts. Please wait a few minutes and try again.');
      }
      throw Exception('Password update failed. Please try again.');
    }
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

  void toggleSavedRoom(String roomNumber) {
    if (_savedRooms.any((r) => r.number == roomNumber)) {
      _savedRooms = _savedRooms.where((r) => r.number != roomNumber).toList();
    } else {
      final room = RoomsService().getRoomByNumber(roomNumber);
      if (room != null) _savedRooms = [..._savedRooms, room];
    }
    notifyListeners();
    _syncSavedRoomsToFirebase();
  }

  Future<void> _syncSavedRoomsToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'savedRooms': _savedRooms.map((r) => r.number).toList()});
    }
  }

  Future<void> loadSavedRoomsFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null && data['savedRooms'] != null) {
        final numbers = List<String>.from(data['savedRooms']);
        _savedRooms = numbers
            .map((n) => RoomsService().getRoomByNumber(n))
            .where((r) => r != null)
            .cast<RoomModel>()
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load saved rooms: $e');
    }
  }

  // Navigation History
  List<String> _navigationHistory = [];
  List<String> get navigationHistory => _navigationHistory;

  void addToNavigationHistory(String roomNumber) {
    _navigationHistory.remove(roomNumber);
    _navigationHistory.insert(0, roomNumber);
    if (_navigationHistory.length > 10) {
      _navigationHistory = _navigationHistory.sublist(0, 10);
    }
    _navigationCount++;
    notifyListeners();
    _syncHistoryToFirebase();
  }

  Future<void> _syncHistoryToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'navigations': _navigationCount,
        'navigationHistory': _navigationHistory,
      });
    }
  }

  Future<void> loadNavigationHistoryFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        _navigationCount =
        data['navigations'] is int ? data['navigations'] as int : 0;
        _navigationHistory = data['navigationHistory'] is List
            ? List<String>.from(data['navigationHistory'])
            : [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
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
  List<RoomModel> _savedRooms = [];
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
  int _navigationCount = 0;
  int get navigationCount => _navigationCount;
  void incrementNavigationCount() { _navigationCount++; notifyListeners(); }
}