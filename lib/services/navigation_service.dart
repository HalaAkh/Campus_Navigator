import 'dart:convert';
import 'package:http/http.dart' as http;
import 'beacon_service.dart';

class NavigationStep {
  final String beaconMac;
  final String location;
  final dynamic floor;
  final String instruction;
  final String direction;

  NavigationStep({
    required this.beaconMac,
    required this.location,
    required this.floor,
    required this.instruction,
    required this.direction,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> j) => NavigationStep(
    beaconMac: j['beacon_mac']?.toString() ?? '',
    location: j['location']?.toString() ?? '',
    floor: j['floor'] ?? 4,
    instruction: j['instruction']?.toString() ?? '',
    direction: j['direction']?.toString() ?? 'forward',
  );
}

class NavigationResult {
  final bool success;
  final List<NavigationStep> path;
  final int totalBeacons;
  final int totalDistanceMeters;
  final int estimatedTimeMinutes;
  final bool accessibilityCompliant;
  final String? error;
  final List<String> floorChanges;
  final String? stairsUsed;

  NavigationResult({
    required this.success,
    this.path = const [],
    this.totalBeacons = 0,
    this.totalDistanceMeters = 0,
    this.estimatedTimeMinutes = 0,
    this.accessibilityCompliant = true,
    this.error,
    this.floorChanges = const [],
    this.stairsUsed,
  });

  factory NavigationResult.failure(String error) =>
      NavigationResult(success: false, error: error);
}

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static const String _floor4Prompt = '''
You are an indoor navigation assistant for Floor 4 of Nicol Building at LAU.

The user provides their CURRENT beacon in "user_current_beacon".

BEACONS (3 total):
1. C6:2A:90:A1:99:CB = Elevator/Stairs Junction- 4th Floor
2. E5:65:DD:D0:91:EC = Room 408 Junction Area  
3. C8:93:08:09:B2:CA = Left Offices Corridor- 4th Floor

BEACON CONNECTIONS:
- Elevator ↔ Room 408: 30m (main corridor)
- Elevator ↔ Left Offices: 15m (left corridor)
- Room 408 ↔ Left Offices: NO DIRECT CONNECTION (must go through Elevator)

FLOOR 4 LAYOUT:
From Elevator (C6:2A:90:A1:99:CB):
  RIGHT → Main corridor: 423, 422, 421, 420 (near elevator), then 401-404 (right side), 419-416 (left side), ending at Room 408
  LEFT → Left corridor: 424, 425, 426, 427, 428, 429, 430

From Room 408 (E5:65:DD:D0:91:EC):
  STRAIGHT back → returns to elevator through main corridor (left/right REVERSED)
  RIGHT → 406 (Conference), 407
  LEFT → 409, 415, 414, 413, 410, 411, 412

ROOMS BY BEACON ZONE:
- Elevator zone: 420, 421, 422, 423
- Room 408 zone: 401, 402, 403, 404, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419
- Left Offices zone: 424, 425, 426, 427, 428, 429, 430

═══ CRITICAL ROUTING RULE ═══
You MUST return ONE step PER BEACON the user passes through.
EVERY route needs MINIMUM 2 steps with DIFFERENT beacon_mac values.

ROUTING EXAMPLES:
From Elevator to Room 407:
  Step 1: beacon_mac="C6:2A:90:A1:99:CB", direction="right", instruction="Turn RIGHT from elevator. Walk straight through main corridor past rooms 423-420, then past 401, 419, 418, 402, 403, 404, 417, 416 until you reach Room 408 at the end."
  Step 2: beacon_mac="E5:65:DD:D0:91:EC", direction="right", instruction="At Room 408 junction, turn RIGHT. Walk past Back Stairs. Room 406 Conference is straight ahead, Room 407 is next to it on your LEFT."

From Elevator to Room 426:
  Step 1: beacon_mac="C6:2A:90:A1:99:CB", direction="left", instruction="Turn LEFT from elevator into the left offices corridor."
  Step 2: beacon_mac="C8:93:08:09:B2:CA", direction="forward", instruction="Walk straight. Room 424 on your RIGHT, then 425, then 426 on your RIGHT."

From Left Offices to Room 408:
  Step 1: beacon_mac="C8:93:08:09:B2:CA", direction="forward", instruction="Walk back toward elevator/stairs junction."
  Step 2: beacon_mac="C6:2A:90:A1:99:CB", direction="right", instruction="At elevator junction, turn RIGHT into main corridor. Walk straight."
  Step 3: beacon_mac="E5:65:DD:D0:91:EC", direction="forward", instruction="You have reached Room 408 junction area."

From Room 408 to Room 424:
  Step 1: beacon_mac="E5:65:DD:D0:91:EC", direction="forward", instruction="Walk straight through main corridor toward elevator."
  Step 2: beacon_mac="C6:2A:90:A1:99:CB", direction="left", instruction="At elevator junction, turn LEFT into left offices corridor."
  Step 3: beacon_mac="C8:93:08:09:B2:CA", direction="forward", instruction="Room 424 is the first room on your RIGHT."

NEVER return only 1 step. Always at least 2 steps with different beacon_mac.
Give PRECISE turn-by-turn directions. Never say "look around".
Always specify which side (LEFT/RIGHT) rooms are on.

Output ONLY valid JSON:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":4,"instruction":"...","direction":"left/right/forward"}],"total_beacons":2,"total_distance_meters":30,"estimated_time_minutes":2,"accessibility_compliant":true}
''';

  static const String _floor5Prompt = '''
You are an indoor navigation assistant for Floor 5 of Nicol Building at LAU.

The user provides their CURRENT beacon in "user_current_beacon".

BEACONS (3 total):
1. F4:7B:74:76:D5:8A = Elevator/Stairs Junction- 5th Floor
2. C7:A4:5A:D0:74:D8 = Room 511 Junction Area
3. F3:55:BD:A3:65:2E = Left Office Corridor- 5th Floor

BEACON CONNECTIONS:
- Elevator ↔ Room 511: 30m (main corridor)
- Elevator ↔ Left Offices: 15m (left corridor)
- Room 511 ↔ Left Offices: NO DIRECT CONNECTION (must go through Elevator)

FLOOR 5 LAYOUT:
From Elevator (F4:7B:74:76:D5:8A):
  RIGHT → rotate right straight: 525, 524, 523 on LEFT, Room 522 at end. Turn RIGHT at 522 into main corridor: 501, 502, 503 on RIGHT, 520 on LEFT, ending at Room 511
  LEFT → Left corridor: 526, 527, 528, 529 (all on RIGHT)

From Room 511 (C7:A4:5A:D0:74:D8):
  STRAIGHT → returns through 503, 502, 520, 501, 522 to elevator (left/right REVERSED)
  RIGHT → Back Stairs, Women's Toilet, 504, 510, 509, 505, 506, 508, 507 (at end)
  LEFT → 512, 519, 513, 514, 518, 517, 515, 516 Journalism Lab (at end)

ROOMS BY BEACON ZONE:
- Elevator zone: 522, 523, 524, 525, 501, 520, 521
- Room 511 zone: 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519
- Left Offices zone: 526, 527, 528, 529

═══ CRITICAL ROUTING RULE ═══
You MUST return ONE step PER BEACON the user passes through.
EVERY route needs MINIMUM 2 steps with DIFFERENT beacon_mac values.

ROUTING EXAMPLES:
From Elevator to Room 507:
  Step 1: beacon_mac="F4:7B:74:76:D5:8A", direction="right", instruction="From elevator, rotate RIGHT. Walk straight past 525, 524, 523. At Room 522, turn RIGHT into main corridor. Walk past 501, 502, 520, 503 until Room 511 at end."
  Step 2: beacon_mac="C7:A4:5A:D0:74:D8", direction="right", instruction="At Room 511 junction, turn RIGHT. Walk past Back Stairs, Women's Toilet. Pass 504, 510, 509, 505, 506, 508. Room 507 is STRAIGHT at the END on the LEFT."

From Elevator to Room 527:
  Step 1: beacon_mac="F4:7B:74:76:D5:8A", direction="left", instruction="Turn LEFT from elevator into left office corridor."
  Step 2: beacon_mac="F3:55:BD:A3:65:2E", direction="forward", instruction="Walk straight. 526 on RIGHT, then 527 on your RIGHT."

From Left Offices to Room 511:
  Step 1: beacon_mac="F3:55:BD:A3:65:2E", direction="forward", instruction="Walk back toward elevator junction."
  Step 2: beacon_mac="F4:7B:74:76:D5:8A", direction="right", instruction="At elevator, rotate RIGHT. Walk past 525-523, turn RIGHT at 522 into main corridor."
  Step 3: beacon_mac="C7:A4:5A:D0:74:D8", direction="forward", instruction="Walk past 501, 502, 520, 503. Room 511 is at the end."

From Room 511 to Room 526:
  Step 1: beacon_mac="C7:A4:5A:D0:74:D8", direction="forward", instruction="Walk straight back through main corridor toward elevator."
  Step 2: beacon_mac="F4:7B:74:76:D5:8A", direction="left", instruction="At elevator junction, turn LEFT into left offices corridor."
  Step 3: beacon_mac="F3:55:BD:A3:65:2E", direction="forward", instruction="Room 526 is the FIRST room on your RIGHT."

NEVER return only 1 step. Always at least 2 steps with different beacon_mac.
Give PRECISE turn-by-turn directions. Never say "look around".
Always specify which side (LEFT/RIGHT) rooms are on.

Output ONLY valid JSON:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":5,"instruction":"...","direction":"left/right/forward"}],"total_beacons":2,"total_distance_meters":30,"estimated_time_minutes":2,"accessibility_compliant":true}
''';

  Future<NavigationResult> _callOpenAI(String systemPrompt, Map<String, dynamic> userRequest, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': jsonEncode(userRequest)},
          ],
          'temperature': 0.2,
          'max_tokens': 1500,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final result = jsonDecode(content) as Map<String, dynamic>;

        if (result['success'] == true) {
          final pathList = result['path'] as List<dynamic>? ?? [];
          final steps = pathList.map((s) => NavigationStep.fromJson(s as Map<String, dynamic>)).toList();

          // Safety: if OpenAI returned only 1 step, we can't do live tracking
          // but we still show the instruction
          return NavigationResult(
            success: true,
            path: steps,
            totalBeacons: (result['total_beacons'] as num?)?.toInt() ?? steps.length,
            totalDistanceMeters: (result['total_distance_meters'] as num?)?.toInt() ?? 30,
            estimatedTimeMinutes: (result['estimated_time_minutes'] as num?)?.toInt() ?? 2,
            accessibilityCompliant: result['accessibility_compliant'] as bool? ?? true,
          );
        }
        return NavigationResult.failure(result['error']?.toString() ?? 'Navigation failed');
      }
      return NavigationResult.failure('API error: ${response.statusCode}');
    } catch (e) {
      return NavigationResult.failure('Error: $e');
    }
  }

  Future<NavigationResult> navigateSameFloor({
    required String currentBeaconMac,
    required int floor,
    required String destinationNumber,
    required String apiKey,
  }) async {
    final prompt = floor == 4 ? _floor4Prompt : _floor5Prompt;
    final request = {
      'user_current_beacon': currentBeaconMac,
      'destination': 'Room $destinationNumber',
      'destination_room_number': destinationNumber,
      'floor': floor,
    };
    return _callOpenAI(prompt, request, apiKey);
  }

  Future<NavigationResult> navigate({
    required String currentBeaconMac,
    required int currentFloor,
    required String destinationNumber,
    required String apiKey,
  }) async {
    final destFloor = destinationNumber.startsWith('5') ? 5 : 4;

    if (currentFloor == destFloor) {
      return navigateSameFloor(
        currentBeaconMac: currentBeaconMac,
        floor: currentFloor,
        destinationNumber: destinationNumber,
        apiKey: apiKey,
      );
    }

    // Multi-floor
    final beaconSvc = BeaconService();
    final stairsChoice = beaconSvc.chooseBestStairs(currentBeaconMac, currentFloor);
    final stairsInfo = stairsChoice == 'primary' ? StairConnections.primary : StairConnections.secondary;

    final List<NavigationStep> path = [];
    int totalDistance = 0;

    // Step 1: Navigate to stairs on current floor
    final stairsBeacon = currentFloor == 4
        ? stairsInfo['floor4_beacon'] as String
        : stairsInfo['floor5_beacon'] as String;

    if (currentBeaconMac.toUpperCase() != stairsBeacon.toUpperCase()) {
      final stairsDest = currentFloor == 4
          ? (stairsChoice == 'primary' ? '420' : '408')
          : (stairsChoice == 'primary' ? '501' : '511');
      final step1 = await navigateSameFloor(currentBeaconMac: currentBeaconMac, floor: currentFloor, destinationNumber: stairsDest, apiKey: apiKey);
      if (step1.success) { path.addAll(step1.path); totalDistance += step1.totalDistanceMeters; }
    }

    // Step 2: Floor transition
    final direction = currentFloor < destFloor ? 'up' : 'down';
    path.add(NavigationStep(beaconMac: 'STAIRS', location: stairsInfo['name'] as String,
        floor: '$currentFloor→$destFloor',
        instruction: 'Take the ${stairsInfo['name']} ${direction == 'up' ? 'UP' : 'DOWN'} to Floor $destFloor.',
        direction: direction));
    totalDistance += 10;

    // Step 3: Navigate on destination floor
    final arrivalBeacon = destFloor == 4
        ? stairsInfo['floor4_beacon'] as String
        : stairsInfo['floor5_beacon'] as String;    final step3 = await navigateSameFloor(currentBeaconMac: arrivalBeacon, floor: destFloor, destinationNumber: destinationNumber, apiKey: apiKey);
    if (step3.success) { path.addAll(step3.path); totalDistance += step3.totalDistanceMeters; }

    return NavigationResult(success: true, path: path, totalBeacons: path.length,
        totalDistanceMeters: totalDistance, estimatedTimeMinutes: (totalDistance / 20).ceil().clamp(2, 99),
        accessibilityCompliant: false, floorChanges: ['Floor $currentFloor → Floor $destFloor'],
        stairsUsed: stairsInfo['name'] as String);
  }
}