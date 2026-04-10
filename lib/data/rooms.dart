// ============================================
// CAMPUS NAVIGATOR - Room Data
// ============================================

class RoomModel {
  final String number;
  final String name;
  final int floor;
  final String category;
  final String beaconMac;
  final String beacon;

  const RoomModel({
    required this.number,
    required this.name,
    required this.floor,
    required this.category,
    required this.beaconMac,
    required this.beacon,
  });
}

const List<RoomModel> floor4Rooms = [
  // Elevator Junction Area
  RoomModel(number: '420', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C6:2A:90:A1:99:CB', beacon: 'C6:2A'),
  RoomModel(number: '421', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C6:2A:90:A1:99:CB', beacon: 'C6:2A'),
  RoomModel(number: '422', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C6:2A:90:A1:99:CB', beacon: 'C6:2A'),
  RoomModel(number: '423', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C6:2A:90:A1:99:CB', beacon: 'C6:2A'),

  // Room 408 Junction Area
  RoomModel(number: '401', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '402', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '403', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '404', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '406', name: 'Conference Room', floor: 4, category: 'Conference', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '407', name: 'Classroom', floor: 4, category: 'Classroom', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '408', name: 'Classroom', floor: 4, category: 'Classroom', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '409', name: 'Classroom', floor: 4, category: 'Classroom', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '410', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '411', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '412', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '413', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '414', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '415', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '416', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '417', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '418', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),
  RoomModel(number: '419', name: 'Office', floor: 4, category: 'Office', beaconMac: 'E5:65:DD:D0:91:EC', beacon: 'E5:65'),

  // Left Offices Corridor
  RoomModel(number: '424', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
  RoomModel(number: '425', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
  RoomModel(number: '426', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
  RoomModel(number: '427', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
  RoomModel(number: '428', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
  RoomModel(number: '429', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
  RoomModel(number: '430', name: 'Office', floor: 4, category: 'Office', beaconMac: 'C8:93:08:09:B2:CA', beacon: 'C8:93'),
];

// ============================================
// FLOOR 5 ROOMS (28 rooms)
// ============================================

const List<RoomModel> floor5Rooms = [
  // Left Office Corridor
  RoomModel(number: '526', name: 'Office', floor: 5, category: 'Office', beaconMac: 'F3:55:BD:A3:65:2E', beacon: 'F3:55'),
  RoomModel(number: '527', name: 'Office', floor: 5, category: 'Office', beaconMac: 'F3:55:BD:A3:65:2E', beacon: 'F3:55'),
  RoomModel(number: '528', name: 'Office', floor: 5, category: 'Office', beaconMac: 'F3:55:BD:A3:65:2E', beacon: 'F3:55'),
  RoomModel(number: '529', name: 'Office', floor: 5, category: 'Office', beaconMac: 'F3:55:BD:A3:65:2E', beacon: 'F3:55'),

  // Elevator Junction Area
  RoomModel(number: '501', name: 'Computer Lab', floor: 5, category: 'Lab', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),
  RoomModel(number: '520', name: 'Computer Lab', floor: 5, category: 'Lab', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),
  RoomModel(number: '521', name: 'Office', floor: 5, category: 'Office', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),
  RoomModel(number: '522', name: "Dean's Office", floor: 5, category: 'Office', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),
  RoomModel(number: '523', name: 'Office', floor: 5, category: 'Office', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),
  RoomModel(number: '524', name: 'Office', floor: 5, category: 'Office', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),
  RoomModel(number: '525', name: 'Office', floor: 5, category: 'Office', beaconMac: 'FC:17:8A:61:EC:6D', beacon: 'FC:17'),

  // Room 511 Junction Area
  RoomModel(number: '502', name: 'Classroom', floor: 5, category: 'Classroom', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '503', name: 'Classroom', floor: 5, category: 'Classroom', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '504', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '505', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '506', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '507', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '508', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '509', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '510', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '511', name: 'Lab', floor: 5, category: 'Lab', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '512', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '513', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '514', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '515', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '516', name: 'Journalism Lab', floor: 5, category: 'Lab', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '517', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '518', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
  RoomModel(number: '519', name: 'Office', floor: 5, category: 'Office', beaconMac: 'C7:A4:5A:D0:74:D8', beacon: 'C7:A4'),
];

const List<RoomModel> allRooms = [...floor4Rooms, ...floor5Rooms];

RoomModel? getRoomByNumber(String number) {
  try {
    return allRooms.firstWhere((r) => r.number == number);
  } catch (_) {
    return null;
  }
}