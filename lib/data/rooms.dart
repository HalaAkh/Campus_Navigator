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

  // ── Professor / Office fields (optional — only set for office rooms) ──
  final String? professorsName;
  final String? professorTitle;   // e.g. "Assistant Professor"
  final String? professorEmail;
  final String? officeHours;

  bool get hasProfessorInfo =>
      professorsName != null ||
          professorTitle != null ||
          professorEmail != null ||
          officeHours != null;

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
    this.professorsName,
    this.professorTitle,
    this.professorEmail,
    this.officeHours,
  });

  /// Creates a copy with updated professor fields
  RoomModel copyWithProfessor({
    String? professorName,
    String? professorTitle,
    String? professorEmail,
    String? officeHours,
  }) {
    return RoomModel(
      number: number,
      name: name,
      fullName: fullName,
      floor: floor,
      category: category,
      beaconMac: beaconMac,
      building: building,
      accessibility: accessibility,
      active: active,
      keywords: keywords,
      professorsName: professorName ?? this.professorsName,
      professorTitle: professorTitle ?? this.professorTitle,
      professorEmail: professorEmail ?? this.professorEmail,
      officeHours: officeHours ?? this.officeHours,
    );
  }
}