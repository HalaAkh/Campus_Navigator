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
      final snapshot =
      await FirebaseFirestore.instance.collection('rooms').get();
      _rooms = snapshot.docs.map((doc) {
        final d = doc.data();
        return RoomModel(
          number:        d['number']        ?? doc.id,
          name:          d['name']          ?? 'Room ${doc.id}',
          fullName:      d['fullName']      ?? d['name'] ?? 'Room ${doc.id}',
          floor:         d['floor']         ?? 4,
          category:      d['category']      ?? 'Office',
          beaconMac:     d['beaconMac']     ?? '',
          building:      d['building']      ?? 'Nicol Hall',
          accessibility: d['accessibility'] ?? '',
          active:        d['active']        ?? true,
          keywords:      List<String>.from(d['keywords'] ?? []),
          // ── Professor / Office fields (optional) ──────────────────────
          // These are only present in Firestore for office rooms.
          // All four map to null when the field doesn't exist in the doc.
          professorsName:  d['professorsName']  as String?,
          professorTitle: d['description']    as String?, // Firestore field is "description"
          professorEmail: d['email']          as String?,
          officeHours:    d['OfficeHours']    as String?,
        );
      }).toList();
      _loaded = true;
    } catch (e) {
      _rooms = [];
      _loaded = true;
    }
  }

  /// Search across all fields including professor info.
  /// Used by SearchScreen to support searching by professor name, email, etc.
  List<RoomModel> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase().trim();
    return _rooms.where((r) {
      if (r.number.toLowerCase().contains(q))           return true;
      if (r.name.toLowerCase().contains(q))             return true;
      if (r.fullName.toLowerCase().contains(q))         return true;
      if (r.category.toLowerCase().contains(q))         return true;
      if (r.keywords.any((k) => k.toLowerCase().contains(q))) return true;
      if (r.professorsName?.toLowerCase().contains(q)  == true) return true;
      if (r.professorTitle?.toLowerCase().contains(q) == true) return true;
      if (r.professorEmail?.toLowerCase().contains(q) == true) return true;
      if (r.officeHours?.toLowerCase().contains(q)    == true) return true;
      return false;
    }).toList();
  }
}