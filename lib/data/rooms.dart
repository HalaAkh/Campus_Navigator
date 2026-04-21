class RoomModel {
  final String number;
  final String name;
  final String fullName;
  final int floor;
  final String category;
  final String beaconMac;
  final String building;
  final String accessibility;
  final bool active;
  final List<String> keywords;

  const RoomModel({
    required this.number,
    required this.name,
    required this.fullName,
    required this.floor,
    required this.category,
    required this.beaconMac,
    required this.building,
    required this.accessibility,
    required this.active,
    required this.keywords,
  });
}