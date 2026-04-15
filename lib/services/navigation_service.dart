import 'dart:convert';
import 'package:http/http.dart' as http;
import 'beacon_service.dart';

// ============================================
// NAVIGATION STEP — mirrors Python path dict
// ============================================
class NavigationStep {
  final String beaconMac;
  final String location;
  final dynamic floor; // can be int or String like "4→5"
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

// ============================================
// NAVIGATION SERVICE
// Mirrors multi_floor_navigator.py + floor4/floor5 scripts exactly
// ============================================
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Full floor 4 prompt from app_config
  static const String _floor4Prompt = '''
You are an indoor navigation assistant for Floor 4 of Nicol Building at LAU.

CRITICAL: ALWAYS START FROM THE USER\'S CURRENT LOCATION!
The user provides their CURRENT beacon location in "user_current_beacon" field.

BEACON LOCATIONS:
- C6:2A:90:A1:99:CB = Elevator/Stairs Junction
- E5:65:DD:D0:91:EC = Room 408 Junction Area
- C8:93:08:09:B2:CA = Left Offices Corridor

FLOOR 4 LAYOUT:
From Elevator/Stairs Junction:
DIRECTION 1: Turn RIGHT (Main Right Corridor)
  First section: On LEFT: 423, 422, 421. FACING STRAIGHT: 420, Women\'s Toilet.
  Turn RIGHT into main corridor:
    On RIGHT: Room 401 (FIRST)
    On LEFT: Room 419, 418
    On RIGHT: Room 402, 403, 404
    On LEFT: Room 417, 416, Men\'s Toilet
    FACING STRAIGHT: Room 408 (JUNCTION)
  AT ROOM 408:
    Turn RIGHT: Back Stairs, Room 406 (Conference), Room 407
    Turn LEFT: Room 409, 415, 414, 413, 410, 411, 412
DIRECTION 2: Turn LEFT (Left Offices Corridor)
  On RIGHT: 424, 425, 426. FACING: 427, 428 (Stairs F5). On LEFT: 429, 430.

CRITICAL RULES:
1. Left/Right REVERSED when walking FROM 408 TOWARD Elevator.
2. Rooms 409-415: MUST go through Room 408 first (NOT directly from Elevator).
3. Rooms 424-430: MUST go through Elevator Junction then turn LEFT.
4. Always specify corridor name.
5. Never say "look around".

BEACON GRAPH:
- C6:2A:90 (Elevator) ↔ E5:65:DD (Room 408): 30m
- C6:2A:90 (Elevator) ↔ C8:93:08 (Left Offices): 15m
- E5:65:DD ↔ C8:93:08: NO DIRECT CONNECTION

Output ONLY valid JSON:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":4,"instruction":"precise directions","direction":"left/right/forward/straight"}],"total_beacons":0,"total_distance_meters":0,"estimated_time_minutes":0,"accessibility_compliant":true}
''';

  static const String _floor5Prompt = '''
You are an indoor navigation assistant for Floor 5 of Nicol Building at LAU.

BEACON LOCATIONS:
- FC:17:8A:61:EC:6D = Elevator/Stairs 1 Junction
- F3:55:BD:A3:65:2E = Left Office Corridor
- C7:A4:5A:D0:74:D8 = Room 511 Junction Area

FLOOR 5 LAYOUT:
From Elevator Junction:
  Turn LEFT: Rooms 526, 527, 528, 529 (all on RIGHT).
  Rotate RIGHT straight: 525, 524, 523 on LEFT. Room 522 at END on LEFT.
  Turn RIGHT at 522 into main corridor:
    On RIGHT: 501 (Computer Lab, FIRST), 502, 503
    On LEFT: 520 (Computer Lab, 2 doors), Men\'s Toilet
    FACING END: Room 511 (JUNCTION)
AT ROOM 511:
  STRAIGHT (back): returns through 503, 502, 520, 501, 522, elevator (Left/Right REVERSED)
  Turn RIGHT: Back Stairs, Women\'s Toilet, Offices 504, 510, 509, 505, 506, 508, 507
  Turn LEFT: Offices 512, 519, 513, 514, 518, 517, 515, Room 516 (Journalism Lab)

CRITICAL: Room 522 is the CORNER/GATEWAY between main corridor and elevator path.
DO NOT route through elevator if destination is reachable directly.
Never say "look around" - give exact directions.

Output ONLY valid JSON:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":5,"instruction":"precise directions","direction":"left/right/forward/straight"}],"total_beacons":0,"total_distance_meters":0,"estimated_time_minutes":0,"accessibility_compliant":true,"warnings":[]}
''';

  // ── mirrors find_navigation_path() ───────────────────────────────
  Future<NavigationResult> _callOpenAI(
      String systemPrompt,
      Map<String, dynamic> userRequest,
      String apiKey,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': jsonEncode(userRequest)},
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final result = jsonDecode(content) as Map<String, dynamic>;

        if (result['success'] == true) {
          final pathList = result['path'] as List<dynamic>? ?? [];
          final steps = pathList
              .map((s) => NavigationStep.fromJson(s as Map<String, dynamic>))
              .toList();
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

  // ── Same-floor navigation ────────────────────────────────────────
  Future<NavigationResult> navigateSameFloor({
    required String currentBeaconMac,
    required int floor,
    required String destinationNumber,
    required String apiKey,
  }) async {
    final prompt = floor == 4 ? _floor4Prompt : _floor5Prompt;
    final request = {
      'user_current_beacon': currentBeaconMac,
      'destination': destinationNumber,
      'accessibility_requirements': 'none',
      'avoid_stairs': false,
    };
    return _callOpenAI(prompt, request, apiKey);
  }

  // ── Multi-floor navigation — mirrors navigate_multi_floor() ──────
  Future<NavigationResult> navigate({
    required String currentBeaconMac,
    required int currentFloor,
    required String destinationNumber,
    required String apiKey,
  }) async {
    // Determine destination floor from room number prefix
    final destFloor = destinationNumber.startsWith('5') ? 5 : 4;

    // Same floor
    if (currentFloor == destFloor) {
      return navigateSameFloor(
        currentBeaconMac: currentBeaconMac,
        floor: currentFloor,
        destinationNumber: destinationNumber,
        apiKey: apiKey,
      );
    }

    // Multi-floor — mirrors navigate_multi_floor()
    final beaconSvc = BeaconService();
    final stairsChoice = beaconSvc.chooseBestStairs(currentBeaconMac, currentFloor);
    final stairsInfo = stairsChoice == 'primary'
        ? StairConnections.primary
        : StairConnections.secondary;

    final List<NavigationStep> path = [];
    int totalDistance = 0;

    // STEP 1: Navigate to stairs on current floor
    final stairsBeacon = currentFloor == 4
        ? stairsInfo['floor4_beacon'] as String
        : stairsInfo['floor5_beacon'] as String;

    if (currentBeaconMac.toUpperCase() != stairsBeacon.toUpperCase()) {
      final stairsDest = currentFloor == 4
          ? (stairsChoice == 'primary' ? '420' : '408')
          : (stairsChoice == 'primary' ? '501' : '511');

      final step1 = await navigateSameFloor(
        currentBeaconMac: currentBeaconMac,
        floor: currentFloor,
        destinationNumber: stairsDest,
        apiKey: apiKey,
      );
      if (step1.success) {
        // Modify last instruction to point toward stairs (mirrors Python)
        final modifiedPath = step1.path.map((s) {
          final isLast = s == step1.path.last;
          if (isLast) {
            final newInstruction = stairsChoice == 'primary'
                ? '${s.instruction.replaceAll('Room $stairsDest is in this area.', '')} Continue to Elevator/Stairs Junction.'
                : '${s.instruction.replaceAll('Room $stairsDest is in this area.', '')} ${currentFloor == 4 ? 'Turn RIGHT for Back Stairs.' : 'Turn LEFT for Back Stairs.'}';
            return NavigationStep(
              beaconMac: s.beaconMac,
              location: s.location,
              floor: s.floor,
              instruction: newInstruction,
              direction: s.direction,
            );
          }
          return s;
        }).toList();
        path.addAll(modifiedPath);
        totalDistance += step1.totalDistanceMeters;
      }
    }

    // STEP 2: Floor transition step (mirrors Python stairs step)
    final direction = currentFloor < destFloor ? 'up' : 'down';
    path.add(NavigationStep(
      beaconMac: 'STAIRS',
      location: stairsInfo['name'] as String,
      floor: '$currentFloor→$destFloor',
      instruction:
      'Go ${direction == 'up' ? 'UP ⬆' : 'DOWN ⬇'} the stairs to Floor $destFloor (${stairsInfo['name']})',
      direction: direction,
    ));
    totalDistance += 10;

    // STEP 3: Navigate from stairs to destination on target floor
    final arrivalBeacon = destFloor == 4
        ? stairsInfo['floor4_beacon'] as String
        : stairsInfo['floor5_beacon'] as String;

    final step3 = await navigateSameFloor(
      currentBeaconMac: arrivalBeacon,
      floor: destFloor,
      destinationNumber: destinationNumber,
      apiKey: apiKey,
    );
    if (step3.success) {
      path.addAll(step3.path);
      totalDistance += step3.totalDistanceMeters;
    }

    return NavigationResult(
      success: true,
      path: path,
      totalBeacons: path.length,
      totalDistanceMeters: totalDistance,
      estimatedTimeMinutes: (totalDistance / 20).ceil().clamp(2, 99),
      accessibilityCompliant: false,
      floorChanges: ['Floor $currentFloor → Floor $destFloor'],
      stairsUsed: stairsInfo['name'] as String,
    );
  }
}