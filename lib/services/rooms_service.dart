import 'package:cloud_firestore/cloud_firestore.dart';
import '/data/rooms.dart';

class RoomsService {
  static final RoomsService _instance = RoomsService._();
  factory RoomsService() => _instance;
  RoomsService._();

  List<RoomModel> _rooms = [];
  bool _loaded = false;

  List<RoomModel> get allRooms => _rooms;
  List<RoomModel> get floor4Rooms => _rooms.where((r) => r.floor == 4).toList();
  List<RoomModel> get floor5Rooms => _rooms.where((r) => r.floor == 5).toList();

  RoomModel? getRoomByNumber(String number) {
    try {
      return _rooms.firstWhere((r) => r.number == number);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRooms() async {
    if (_loaded) return;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('rooms').get();
      _rooms = snapshot.docs.map((doc) {
        final d = doc.data();
        return RoomModel(
          number: d['number'] ?? doc.id,
          name: d['name'] ?? 'Room ${doc.id}',
          fullName: d['fullName'] ?? d['name'] ?? 'Room ${doc.id}',
          floor: d['floor'] ?? 4,
          category: d['category'] ?? 'Office',
          beaconMac: d['beaconMac'] ?? '',
          building: d['building'] ?? 'Nicol Hall',
          accessibility: d['accessibility'] ?? '',
          active: d['active'] ?? true,
          keywords: List<String>.from(d['keywords'] ?? []),
        );
      }).toList();
      _loaded = true;
    } catch (e) {
      // Fallback to local data if Firebase fails
      _rooms = allRooms;
      _loaded = true;
    }
  }
}