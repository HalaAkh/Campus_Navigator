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

CRITICAL RULE: Each instruction describes what to do STARTING FROM that beacon position, looking FORWARD. Never describe rooms already passed.

BEACONS (3 total):
1. C6:2A:90:A1:99:CB = Elevator/Stairs Junction - 4th Floor
2. E5:65:DD:D0:91:EC = Room 408 Junction Area
3. C8:93:08:09:B2:CA = Left Offices Corridor - 4th Floor

WHAT YOU SEE AT EACH BEACON:
- At Elevator (C6:2A:90:A1:99:CB): You are at elevator/stairs area.
    TURN RIGHT → main corridor ahead: 423, 422, 421, 420 near elevator, then 401 & 419, 402 & 418, 403 & 417, 404 & 416, then Room 408 at the end.
    TURN LEFT → left offices corridor: 424, 425, 426, 427, 428, 429, 430 on your RIGHT.
    BACK STAIRS are at Room 408 end (turn RIGHT past 408).
    MAIN STAIRS/ELEVATOR are right here.

- At Room 408 Junction (E5:65:DD:D0:91:EC): You are at end of main corridor.
    TURN RIGHT → Back Stairs (Stairs 2), then 406 Conference at end, 407 next to it.
    TURN LEFT → 409 & 415, 410 & 414, 411 & 413, 412 at end.
    STRAIGHT BACK → return through main corridor toward elevator.

- At Left Offices (C8:93:08:09:B2:CA): You are in left offices corridor.
    ROOMS AHEAD on RIGHT: 424 first, then 425, 426, 427, 428, 429, 430 at end.
    STRAIGHT BACK → returns to elevator junction.

FLOOR 4 ROOMS BY ZONE:
- Elevator zone: 420, 421, 422, 423
- Main corridor (between elevator and 408): 401, 402, 403, 404, 416, 417, 418, 419
- Room 408 zone: 406, 407, 408, 409, 410, 411, 412, 413, 414, 415
- Left Offices zone: 424, 425, 426, 427, 428, 429, 430

ROUTING RULES:
1. Each step fires when user ARRIVES at that beacon. Instruction tells them what to do NEXT from there.
2. For rooms in main corridor (401-404, 416-419): instruct FROM ELEVATOR since user passes these walking to 408.
3. For rooms in 408 zone: instruct FROM 408 junction.
4. FINAL STEP must pinpoint the exact door: which side, how far, what landmark.
5. ALWAYS choose the SHORTEST physical path.

CORRECT EXAMPLES:

From Elevator → Room 407:
  Step 1 (fires at elevator): beacon_mac="C6:2A:90:A1:99:CB", direction="right",
    instruction="Turn RIGHT from elevator. Walk past 423, 422, 421, 420 on your LEFT. Continue past 401 on RIGHT & 419 on LEFT, 402 & 418, 403 & 417, 404 & 416. Room 408 is at the end — continue to it."
  Step 2 (fires at 408): beacon_mac="E5:65:DD:D0:91:EC", direction="right",
    instruction="Turn RIGHT at Room 408 junction past Back Stairs. Room 406 Conference is at the END facing you. Room 407 is on your LEFT just before it."

From Elevator → Room 402:
  Step 1 (fires at elevator): beacon_mac="C6:2A:90:A1:99:CB", direction="right",
    instruction="Turn RIGHT from elevator. Walk past 423, 422, 421, 420. Room 401 is the first door on your RIGHT. Room 402 is the NEXT door on your RIGHT."

From Elevator → Room 426:
  Step 1 (fires at elevator): beacon_mac="C6:2A:90:A1:99:CB", direction="left",
    instruction="Turn LEFT from elevator into the left offices corridor."
  Step 2 (fires at left offices): beacon_mac="C8:93:08:09:B2:CA", direction="forward",
    instruction="Walk straight. Room 424 is first on your RIGHT, then 425. Room 426 is the THIRD door on your RIGHT."

From Room 408 → Room 425:
  Step 1 (fires at 408): beacon_mac="E5:65:DD:D0:91:EC", direction="forward",
    instruction="Walk straight back through main corridor toward elevator. Pass 404 & 416, 403 & 417, 402 & 418, 401 & 419, then 420-423."
  Step 2 (fires at elevator): beacon_mac="C6:2A:90:A1:99:CB", direction="left",
    instruction="Turn LEFT at elevator into the left offices corridor."
  Step 3 (fires at left offices): beacon_mac="C8:93:08:09:B2:CA", direction="forward",
    instruction="Walk straight. Room 424 is first on your RIGHT. Room 425 is the SECOND door on your RIGHT."
    
From Room 408 to Room 429:
  Step 1 (fires at 408): beacon_mac="E5:65:DD:D0:91:EC", direction="forward",
    instruction="Walk straight back through main corridor toward elevator. Pass 404 & 416, 403 & 417, 402 & 418, 401 & 419, then 420-423."
  Step 2 (fires at elevator): beacon_mac="C6:2A:90:A1:99:CB", direction="left",
    instruction="At elevator junction, turn LEFT into the left offices corridor."
  Step 3 (fires at left offices): beacon_mac="C8:93:08:09:B2:CA", direction="forward",
    instruction="Walk straight. Room 424 first on RIGHT, 425, 426, 427, 428. Room 429 is near the END on your RIGHT."

⚠️ CRITICAL: Rooms 424-430 are ONLY in the LEFT OFFICES corridor.
NEVER route 424-430 through Room 408 junction directly — always go back to elevator first.

Output ONLY valid JSON:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":4,"instruction":"...","direction":"left/right/forward"}],"total_beacons":2,"total_distance_meters":30,"estimated_time_minutes":2,"accessibility_compliant":true}
''';

  static const String _floor5Prompt = '''
You are an indoor navigation assistant for Floor 5 of Nicol Building at LAU.

CRITICAL RULE: Each instruction describes what to do STARTING FROM that beacon position, looking FORWARD. Never describe rooms already passed.

BEACONS (3 total):
1. F4:7B:74:76:D5:8A = Elevator/Stairs Junction - 5th Floor
2. C7:A4:5A:D0:74:D8 = Room 511 Junction Area
3. F3:55:BD:A3:65:2E = Left Office Corridor - 5th Floor

WHAT YOU SEE AT EACH BEACON:
- At Elevator (F4:7B:74:76:D5:8A): You are at elevator/stairs area. 
    ROTATE RIGHT → you see 525, 524, 523 on your LEFT going toward 522.
    At 522 turn RIGHT → main corridor ahead: 501 & 521, then 502 & 520, then 503 & Men's Toilet, then Room 511 at the end.
    TURN LEFT → left offices corridor: 526, 527, 528, 529 on your RIGHT.
    MAIN STAIRS/ELEVATOR are right here.

- At Room 511 Junction (C7:A4:5A:D0:74:D8): You are at the end of the main corridor.
    TURN RIGHT path→ Back Stairs (Stairs 2), then Women's Toilet, then 504 & 510, 505 & 509, 506 & 508, 507 at end.
    TURN LEFT path → 512 & 519, 513 & 518, 514 & 517, 515, 516 Journalism Lab at end.
    STRAIGHT BACK → return through main corridor toward elevator (501,502,520,503 behind you now on reversed sides).

- At Left Offices (F3:55:BD:A3:65:2E): You are in left offices corridor.
    ROOMS AHEAD on RIGHT: 526 first, then 527, 528, 529 at end.
    STRAIGHT BACK → returns to elevator junction.

FLOOR 5 ROOMS BY ZONE:
- Elevator zone: 521, 522, 523, 524, 525
- Main corridor (between elevator and 511): 501, 502, 503, 520
- Room 511 zone: 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519
- Left Offices zone: 526, 527, 528, 529

ROOMS BY BEACON ZONE:
- Elevator zone (F4:7B:74:76:D5:8A): 521, 522, 523, 524, 525
- Main corridor (between elevator and 511): 501, 502, 503, 520
- Room 511 zone (C7:A4:5A:D0:74:D8): 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519
- Left Offices zone (F3:55:BD:A3:65:2E): 526, 527, 528, 529

⚠️ CRITICAL: Rooms 526, 527, 528, 529 are ONLY accessible from the LEFT OFFICES corridor.
They are reached by turning LEFT at the ELEVATOR — NOT from Room 511 junction.
NEVER route 526-529 through Room 511.

⚠️ CRITICAL: Rooms 512, 513, 514, 515, 516, 517, 518, 519 are the LEFT branch from Room 511 junction.
These are completely separate from 526-529.

ROUTING RULES:
1. Each step fires when user ARRIVES at that beacon. Instruction tells them what to do NEXT from there.
2. For rooms in main corridor (501,502,503,520,521): instruct FROM ELEVATOR since user passes these walking toward 511.
3. For rooms in 511 zone: instruct FROM 511 junction.
4. FINAL STEP must pinpoint the exact door: which side, how far, what landmark.
5. ALWAYS choose the SHORTEST physical path.

From Room 511 to Room 529:
  Step 1 (fires at 511): beacon_mac="C7:A4:5A:D0:74:D8", direction="forward",
    instruction="Walk straight back through the main corridor toward the elevator. Pass 503, 502 & 520, 501 & 521."
  Step 2 (fires at elevator): beacon_mac="F4:7B:74:76:D5:8A", direction="left",
    instruction="At the elevator junction, turn LEFT into the left offices corridor."
  Step 3 (fires at left offices): beacon_mac="F3:55:BD:A3:65:2E", direction="forward",
    instruction="Walk straight. Room 526 is first on your RIGHT, 527, 528. Room 529 is the LAST room at the END on your RIGHT."
    
From Elevator → Room 507:
  Step 1 (fires at elevator): beacon_mac="F4:7B:74:76:D5:8A", direction="right",
    instruction="Rotate RIGHT from elevator. Walk past 525, 524, 523 on your LEFT. At Room 522 turn RIGHT into main corridor. Walk past 501 on LEFT, 521 on RIGHT, then 502 & 520, then 503. Room 511 is at the end — continue to it."
  Step 2 (fires at 511): beacon_mac="C7:A4:5A:D0:74:D8", direction="right",
    instruction="Turn RIGHT at Room 511 junction. Walk past Back Stairs and Women's Toilet on your LEFT. Continue past 504 & 510, 505 & 509, 506 & 508. Room 507 is at the very END on your LEFT."

From Elevator → Room 502:
  Step 1 (fires at elevator): beacon_mac="F4:7B:74:76:D5:8A", direction="right",
    instruction="Rotate RIGHT from elevator. Walk past 525, 524, 523 on your LEFT. At Room 522 turn RIGHT. Room 501 is on your LEFT, Room 521 on your RIGHT. Room 502 is the NEXT door on your LEFT."

From Elevator → Room 527:
  Step 1 (fires at elevator): beacon_mac="F4:7B:74:76:D5:8A", direction="left",
    instruction="Turn LEFT from elevator into the left offices corridor."
  Step 2 (fires at left offices): beacon_mac="F3:55:BD:A3:65:2E", direction="forward",
    instruction="Walk straight. Room 526 is first on your RIGHT. Room 527 is the NEXT door on your RIGHT."

From Room 511 → Room 526:
  Step 1 (fires at 511): beacon_mac="C7:A4:5A:D0:74:D8", direction="forward",
    instruction="Walk straight back through main corridor. Pass 503, 502 & 520, 501 & 521. At Room 522 turn LEFT toward the elevator."
  Step 2 (fires at elevator): beacon_mac="F4:7B:74:76:D5:8A", direction="left",
    instruction="Turn LEFT at elevator into the left offices corridor."
  Step 3 (fires at left offices): beacon_mac="F3:55:BD:A3:65:2E", direction="forward",
    instruction="Room 526 is the FIRST room on your RIGHT."

Output ONLY valid JSON:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":5,"instruction":"...","direction":"left/right/forward"}],"total_beacons":2,"total_distance_meters":30,"estimated_time_minutes":2,"accessibility_compliant":true}
''';

  Future<NavigationResult> _callOpenAI(String systemPrompt,
      Map<String, dynamic> userRequest, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
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
          final steps = pathList.map((s) =>
              NavigationStep.fromJson(s as Map<String, dynamic>)).toList();

          // Safety: if OpenAI returned only 1 step, we can't do live tracking
          // but we still show the instruction
          return NavigationResult(
            success: true,
            path: steps,
            totalBeacons: (result['total_beacons'] as num?)?.toInt() ??
                steps.length,
            totalDistanceMeters: (result['total_distance_meters'] as num?)
                ?.toInt() ?? 30,
            estimatedTimeMinutes: (result['estimated_time_minutes'] as num?)
                ?.toInt() ?? 2,
            accessibilityCompliant: result['accessibility_compliant'] as bool? ??
                true,
          );
        }
        return NavigationResult.failure(
            result['error']?.toString() ?? 'Navigation failed');
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

    final beaconSvc = BeaconService();
    final stairsChoice = beaconSvc.chooseBestStairs(
        currentBeaconMac, currentFloor);
    final stairsInfo = stairsChoice == 'primary'
        ? StairConnections.primary
        : StairConnections.secondary;

    final List<NavigationStep> path = [];
    int totalDistance = 0;

    // ── STEP 1: Navigate to stairs on current floor ──
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
          apiKey: apiKey);
      if (step1.success) {
        path.addAll(step1.path);
        totalDistance += step1.totalDistanceMeters;
      }
    } else {
      // ← CRITICAL FIX: Already at stairs — add a dummy step so the
      // beacon can be matched and arrival at stairs is detected
      path.add(NavigationStep(
        beaconMac: stairsBeacon,
        location: stairsInfo['name'] as String,
        floor: currentFloor,
        instruction: stairsChoice == 'primary'
            ? 'You are at the elevator. Take the Main Stairs ${currentFloor >
            destFloor
            ? "DOWN"
            : "UP"} to Floor $destFloor — the stairs are immediately next to you.'
            : 'You are at the junction. Turn to the Back Stairs (Stairs 2) and go ${currentFloor >
            destFloor ? "DOWN" : "UP"} to Floor $destFloor.',
        direction: currentFloor > destFloor ? 'down' : 'up',
      ));
      totalDistance += 5;
    }

    // ── STEP 2: Floor transition marker ──
    final direction = currentFloor < destFloor ? 'up' : 'down';
    path.add(NavigationStep(
      beaconMac: 'STAIRS',
      location: stairsInfo['name'] as String,
      floor: '$currentFloor→$destFloor',
      instruction: stairsChoice == 'primary'
          ? 'Take the Main Stairs ${direction == "up"
          ? "UP"
          : "DOWN"} to Floor $destFloor. Stairs are next to the elevator.'
          : 'Take the Back Stairs (Stairs 2) ${direction == "up"
          ? "UP"
          : "DOWN"} to Floor $destFloor.',
      direction: direction,
    ));
    totalDistance += 10;

    // ── STEP 3: Navigate on destination floor ──
    final arrivalBeacon = destFloor == 4
        ? stairsInfo['floor4_beacon'] as String
        : stairsInfo['floor5_beacon'] as String;

    final step3 = await navigateSameFloor(
        currentBeaconMac: arrivalBeacon,
        floor: destFloor,
        destinationNumber: destinationNumber,
        apiKey: apiKey);
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