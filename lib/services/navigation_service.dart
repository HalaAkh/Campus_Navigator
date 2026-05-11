import 'dart:convert';
import 'package:http/http.dart' as http;

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

CRITICAL RULE: Each instruction fires when the user ARRIVES at that beacon. It tells them what to do NEXT from that position. Never describe rooms already passed.

══════════════════════════════════════════════
BEACONS
══════════════════════════════════════════════
1. C6:2A:90:A1:99:CB = Elevator / Main Stairs Junction - Floor 4
2. E5:65:DD:D0:91:EC = Room 408 Junction - Floor 4
3. C8:93:08:09:B2:CA = Left Offices Corridor - Floor 4

══════════════════════════════════════════════
EXACT LAYOUT
══════════════════════════════════════════════

BEACON 1 - ELEVATOR (C6:2A:90:A1:99:CB):
  ROTATE RIGHT → elevator zone (LEFT SIDE): 423, 422, 421, 420.
  At Room 420, TURN RIGHT → main corridor toward 408:
    LEFT SIDE : WOMEN'S TOILET (4WC2), 419, 418, 417, 416, MEN'S TOILET (4WC), then Room 408 FACING at far end.
    RIGHT SIDE: 401, 402, 403, 404.
  TURN LEFT (directly from elevator) → left offices corridor:
    RIGHT SIDE: 424, 425, 426, 427, 428, 429, 430.

BEACON 2 - ROOM 408 JUNCTION (E5:65:DD:D0:91:EC):
  TURN RIGHT → Back Stairs corridor:
    LEFT SIDE: 407, then 406 FACING at far end.
  TURN LEFT → side corridor:
    RIGHT SIDE: 409, 410, 411.
    LEFT SIDE : 415, 414, 413, 412.
  STRAIGHT BACK → main corridor toward elevator:
    LEFT SIDE : 404, 403, 402, 401.
    RIGHT SIDE: MEN'S TOILET (4WC), 416, 417, 418, 419, WOMEN'S TOILET (4WC2), 420, 421, 422, 423.

BEACON 3 - LEFT OFFICES (C8:93:08:09:B2:CA):
  FORWARD: RIGHT SIDE: 424, 425, 426, 427, 428, 429, 430 (430 at end).
  BACK → elevator junction.

══════════════════════════════════════════════
ROOM ZONES
══════════════════════════════════════════════
Elevator zone : 420, 421, 422, 423
Main corridor : 401, 402, 403, 404, 416, 417, 418, 419, WOMEN'S TOILET (4WC2), MEN'S TOILET (4WC)
408 zone      : 406, 407, 408, 409, 410, 411, 412, 413, 414, 415
Left offices  : 424, 425, 426, 427, 428, 429, 430

══════════════════════════════════════════════
ROUTING RULES
══════════════════════════════════════════════
- WOMEN'S TOILET (4WC2) / MEN'S TOILET (4WC) from ELEVATOR: single step.
- WOMEN'S TOILET (4WC2) / MEN'S TOILET (4WC) from 408 JUNCTION: single step back through corridor.
- 424-430 ONLY via Left Offices. From 408: go 408→Elevator→Left Offices (3 steps).
- 408-zone rooms from Elevator: 2 steps (Elevator→408, then turn).
- 408-zone rooms from Left Offices: 3 steps (LeftOffices→Elevator→408, then turn).
- Main corridor rooms (401,402,403,404,416,417,418,419,Women's Toilet,Men's Toilet) from 408: SINGLE STEP — walk straight back, stop at the correct door. Do NOT go to elevator first.
- 408-zone rooms from Elevator: 2 steps (Elevator→408, then turn).
- Elevator-zone rooms (420,421,422,423) from 408: 2 steps (408 back to Elevator, then rotate).
- Elevator-zone/main-corridor rooms from Left Offices: 2 steps (LeftOffices back to Elevator, then instruct).
- Always shortest path. Final step: exact side (LEFT/RIGHT), door count, landmark.

══════════════════════════════════════════════
ALL PATHS — FROM ELEVATOR
══════════════════════════════════════════════

From Elevator → Room 423:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT from the elevator. Room 423 is the FIRST door on your LEFT."

From Elevator → Room 422:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT from the elevator. Pass Room 423. Room 422 is the SECOND door on your LEFT."

From Elevator → Room 421:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT from the elevator. Pass Rooms 423, 422. Room 421 is the THIRD door on your LEFT."

From Elevator → Room 420:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT from the elevator. Pass Rooms 423, 422, 421. Room 420 is the FOURTH door on your LEFT."

From Elevator → Room 401:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Room 401 is the FIRST door on your RIGHT."

From Elevator → Room 402:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass Room 401 on your RIGHT. Room 402 is the SECOND door on your RIGHT."

From Elevator → Room 403:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass Rooms 401, 402 on your RIGHT. Room 403 is the THIRD door on your RIGHT."

From Elevator → Room 404:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass Rooms 401, 402, 403 on your RIGHT. Room 404 is the FOURTH door on your RIGHT."

From Elevator → WOMEN'S TOILET (4WC2):
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. WOMEN'S TOILET (4WC2) is the FIRST door on your LEFT."

From Elevator → Room 419:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, Room 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass WOMEN'S TOILET (4WC2) on your LEFT. Room 419 is the NEXT door on your LEFT."

From Elevator → Room 418:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass WOMEN'S TOILET (4WC2) and Room 419 on your LEFT. Room 418 is the NEXT door on your LEFT."

From Elevator → Room 417:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass WOMEN'S TOILET (4WC2), Rooms 419, 418 on your LEFT. Room 417 is the NEXT door on your LEFT."

From Elevator → Room 416:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass WOMEN'S TOILET (4WC2), Rooms 419, Room 418, 417 on your LEFT. Room 416 is the NEXT door on your LEFT."

From Elevator → MEN'S TOILET (4WC):
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Pass WOMEN'S TOILET (4WC2), Rooms 419, 418, 417, 416 on your LEFT. MEN'S TOILET (4WC) is on your LEFT after Room 416."

From Elevator → Room 408:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor. Room 408 is FACING YOU at the far end."

From Elevator → Room 409:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Room 409 is the FIRST door on your RIGHT."

From Elevator → Room 410:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Room 409. Room 410 is the SECOND door on your RIGHT."

From Elevator → Room 411:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Rooms 409, 410. Room 411 is the THIRD door on your RIGHT."

From Elevator → Room 415:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Room 415 is the FIRST door on your LEFT."

From Elevator → Room 414:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Room 415. Room 414 is the SECOND door on your LEFT."

From Elevator → Room 413:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Rooms 415, 414. Room 413 is the THIRD door on your LEFT."

From Elevator → Room 412:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Walk to the far end. Room 412 is the LAST Room on your LEFT."

From Elevator → Room 407:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC right
  "At Room 408, turn RIGHT past the Back Stairs. Room 407 is on your LEFT just before Room 406 at the far end."

From Elevator → Room 406:
  Step 1 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 422, 421, 420 on your LEFT, turn RIGHT at Room 420 into the main corridor. Walk the full corridor until you REACH Room 408 at the far end."
  Step 2 | E5:65:DD:D0:91:EC right
  "At Room 408, turn RIGHT past the Back Stairs. Room 406 is FACING YOU at the end."

From Elevator → Room 424:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Room 424 is the FIRST door on your RIGHT."

From Elevator → Room 425:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Pass Room 424. Room 425 is the SECOND door on your RIGHT."

From Elevator → Room 426:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425. Room 426 is the THIRD door on your RIGHT."

From Elevator → Room 427:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426. Room 427 is the FOURTH door on your RIGHT."

From Elevator → Room 428:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426, 427. Room 428 is the FIFTH door on your RIGHT."

From Elevator → Room 429:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426, 427, 428. Room 429 is the SIXTH door on your RIGHT."

From Elevator → Room 430:
  Step 1 | C6:2A:90:A1:99:CB left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | C8:93:08:09:B2:CA forward
  "Walk to the end. Room 430 is the LAST door on your RIGHT."

══════════════════════════════════════════════
ALL PATHS — FROM ROOM 408 JUNCTION
══════════════════════════════════════════════

From Room 408 → Room 409:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Room 409 is the FIRST door on your RIGHT."

From Room 408 → Room 410:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Pass Room 409. Room 410 is the SECOND door on your RIGHT."

From Room 408 → Room 411:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Pass Rooms 409, 410. Room 411 is the THIRD door on your RIGHT."

From Room 408 → Room 415:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Room 415 is the FIRST door on your LEFT."

From Room 408 → Room 414:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Pass Room 415. Room 414 is the SECOND door on your LEFT."

From Room 408 → Room 413:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Pass Rooms 415, 414. Room 413 is the THIRD door on your LEFT."

From Room 408 → Room 412:
  Step 1 | E5:65:DD:D0:91:EC left
  "Turn LEFT at Room 408 junction. Walk to the end. Room 412 is the LAST Room on your LEFT."

From Room 408 → Room 407:
  Step 1 | E5:65:DD:D0:91:EC right
  "Turn RIGHT at Room 408 junction the Back Stairs. Room 407 is on your LEFT just before Room 406 at the far end."

From Room 408 → Room 406:
  Step 1 | E5:65:DD:D0:91:EC right
  "Turn RIGHT at Room 408 junction past the Back Stairs. Walk to the end. Room 406 is FACING YOU."

From Room 408 → Room 401:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor; Room 401 is the LAST door on your LEFT before the elevator turn."

From Room 408 → Room 402:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor; Room 402 is the THIRD door on your LEFT."

From Room 408 → Room 403:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor; Room 403 is the SECOND door on your LEFT."

From Room 408 → Room 404:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor; Room 404 is the FIRST door on your LEFT."

From Room 408 → WOMEN'S TOILET (4WC2):
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor; WOMEN'S TOILET (4WC2) is the LAST room on your RIGHT before the elevator turn."

From Room 408 → MEN'S TOILET (4WC):
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor. MEN'S TOILET (4WC) is the FIRST door on your RIGHT."

From Room 408 → Room 419:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor. Room 419 is the FOURTH door on your RIGHT, before WOMEN'S TOILET (4WC2)."

From Room 408 → Room 418:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor. Room 418 is the THIRD door on your RIGHT."

From Room 408 → Room 417:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor. Room 417 is the SECOND door on your RIGHT."

From Room 408 → Room 416:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the main corridor. Room 416 is the FIRST door on your RIGHT after MEN'S TOILET (4WC)."

From Room 408 → Room 420:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "Rotate LEFT. Room 420 is the FIRST door on your RIGHT."

From Room 408 → Room 421:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "Rotate LEFT. Room 421 is the SECOND door on your RIGHT."

From Room 408 → Room 422:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "Rotate LEFT. Room 422 is the THIRD door on your RIGHT."

From Room 408 → Room 423:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator ."
  Step 2 | C6:2A:90:A1:99:CB left
  "Rotate LEFT. Room 423 is the FOURTH door on your RIGHT."

From Room 408 → Room 424:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Room 424 is the FIRST door on your RIGHT."

From Room 408 → Room 425:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Pass Room 424. Room 425 is the SECOND door on your RIGHT."

From Room 408 → Room 426:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425. Room 426 is the THIRD door on your RIGHT."

From Room 408 → Room 427:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426. Room 427 is the FOURTH door on your RIGHT."

From Room 408 → Room 428:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426, 427. Room 428 is the FIFTH door on your RIGHT."

From Room 408 → Room 429:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426, 427, 428. Room 429 is the SIXTH door on your RIGHT."

From Room 408 → Room 430:
  Step 1 | E5:65:DD:D0:91:EC forward
  "Walk BACK into the elevator."
  Step 2 | C6:2A:90:A1:99:CB left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | C8:93:08:09:B2:CA forward
  "Walk to the end. Room 430 is the LAST door on your RIGHT."
  
  ⚠️ IMPORTANT — DIRECTION DEPENDS ON HOW YOU ENTERED LEFT OFFICES:
- If you came FROM THE ELEVATOR (walking forward into corridor): rooms are on your RIGHT. Use paths below.
- If you came FROM THE STAIRS (arriving from Floor 5): rooms are on your LEFT, in REVERSE ORDER. Use the "FROM STAIRS ARRIVAL" paths.

══════════════════════════════════════════════
ALL PATHS — FROM LEFT OFFICES (ARRIVED FROM STAIRS / FLOOR 5)
══════════════════════════════════════════════

From Left Offices (stairs arrival) → Room 430:
  Step 1 | C8:93:08:09:B2:CA forward
  "Room 430 is the FIRST door on your LEFT."

From Left Offices (stairs arrival) → Room 429:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Room 430. Room 429 is the SECOND door on your LEFT."

From Left Offices (stairs arrival) → Room 428:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 430, 429. Room 428 is the THIRD door on your LEFT."

From Left Offices (stairs arrival) → Room 427:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 430, 429, 428. Room 427 is the FOURTH door on your LEFT."

From Left Offices (stairs arrival) → Room 426:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 430, 429, 428, 427. Room 426 is the FIFTH door on your LEFT."

From Left Offices (stairs arrival) → Room 425:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 430, 429, 428, 427, 426. Room 425 is the SIXTH door on your LEFT."

From Left Offices (stairs arrival) → Room 424:
  Step 1 | C8:93:08:09:B2:CA forward
  "Walk to the end. Room 424 is the LAST door on your LEFT."
  
══════════════════════════════════════════════
ALL PATHS — FROM LEFT OFFICES
══════════════════════════════════════════════

From Left Offices → Room 424:
  Step 1 | C8:93:08:09:B2:CA forward
  "Room 424 is the FIRST door on your RIGHT."

From Left Offices → Room 425:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Room 424. Room 425 is the SECOND door on your RIGHT."

From Left Offices → Room 426:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425. Room 426 is the THIRD door on your RIGHT."

From Left Offices → Room 427:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426. Room 427 is the FOURTH door on your RIGHT."

From Left Offices → Room 428:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426, 427. Room 428 is the FIFTH door on your RIGHT."

From Left Offices → Room 429:
  Step 1 | C8:93:08:09:B2:CA forward
  "Pass Rooms 424, 425, 426, 427, 428. Room 429 is the SIXTH door on your RIGHT."

From Left Offices → Room 430:
  Step 1 | C8:93:08:09:B2:CA forward
  "Walk to the end. Room 430 is the LAST door on your RIGHT."

From Left Offices → Room 423:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT. Room 423 is the FIRST door on your LEFT."

From Left Offices → Room 422:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT. Pass Room 423. Room 422 is the SECOND door on your LEFT."

From Left Offices → Room 421:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT. Pass Rooms 423, 422. Room 421 is the THIRD door on your LEFT."

From Left Offices → Room 420:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT. Pass Rooms 423, 422, 421. Room 420 is the FOURTH door on your LEFT."

From Left Offices → Room 401:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Room 401 is the FIRST door on your RIGHT."

From Left Offices → Room 402:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass Room 401. Room 402 is the SECOND door on your RIGHT."

From Left Offices → Room 403:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass Rooms 401, 402. Room 403 is the THIRD door on your RIGHT."

From Left Offices → Room 404:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass Rooms 401, 402, 403. Room 404 is the FOURTH door on your RIGHT."

From Left Offices → WOMEN'S TOILET (4WC2):
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. WOMEN'S TOILET (4WC2) is the FIRST door on your LEFT."

From Left Offices → Room 419:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass WOMEN'S TOILET (4WC2). Room 419 is the NEXT door on your LEFT."

From Left Offices → Room 418:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass WOMEN'S TOILET (4WC2), Room 419. Room 418 is the NEXT door on your LEFT."

From Left Offices → Room 417:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass WOMEN'S TOILET (4WC2), Rooms 419, 418. Room 417 is the NEXT door on your LEFT."

From Left Offices → Room 416:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Room 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Pass WOMEN'S TOILET (4WC2), Rooms 419, 418, 417. Room 416 is the NEXT door on your LEFT."

From Left Offices → MEN'S TOILET (4WC):
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. MEN'S TOILET (4WC) is on your LEFT after Room 416."

From Left Offices → Room 408:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor. Room 408 is FACING YOU at the far end."

From Left Offices → Room 409:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Room 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Room 409 is the FIRST door on your RIGHT."

From Left Offices → Room 410:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Room 409. Room 410 is the SECOND door on your RIGHT."

From Left Offices → Room 411:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Rooms 409, 410. Room 411 is the THIRD door on your RIGHT."

From Left Offices → Room 415:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Room 415 is the FIRST door on your LEFT."

From Left Offices → Room 414:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Room 415. Room 414 is the SECOND door on your LEFT."

From Left Offices → Room 413:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Pass Rooms 415, 414. Room 413 is the THIRD door on your LEFT."

From Left Offices → Room 412:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC left
  "At Room 408, turn LEFT. Walk to the far end. Room 412 is the LAST room on your LEFT."

From Left Offices → Room 407:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC right
  "At Room 408, turn RIGHT past the Back Stairs. Room 407 is on your LEFT just before Room 406."

From Left Offices → Room 406:
  Step 1 | C8:93:08:09:B2:CA forward
  "Turn BACK and walk to the elevator."
  Step 2 | C6:2A:90:A1:99:CB right
  "Rotate RIGHT, pass Rooms 423, 422, 421, 420 on your LEFT, turn RIGHT at Room 420. Walk the full corridor until you REACH Room 408."
  Step 3 | E5:65:DD:D0:91:EC right
  "At Room 408, turn RIGHT past the Back Stairs. Walk to the end. Room 406 is FACING YOU."

Output ONLY valid JSON — no markdown, no explanation:
{"success":true,"path":[{"beacon_mac":"...","location":"...","floor":4,"instruction":"...","direction":"left/right/forward"}],"total_beacons":2,"total_distance_meters":30,"estimated_time_minutes":2,"accessibility_compliant":true}
''';

  static const String _floor5Prompt = '''
You are an indoor navigation assistant for Floor 5 of Nicol Building at LAU.

CRITICAL RULE: Each instruction fires when the user ARRIVES at that beacon. It tells them what to do NEXT from that position. Never describe rooms already passed.

══════════════════════════════════════════════
BEACONS
══════════════════════════════════════════════
1. F4:7B:74:76:D5:8A = Elevator / Main Stairs Junction - Floor 5
2. C7:A4:5A:D0:74:D8 = Room 511 Junction - Floor 5
3. F3:55:BD:A3:65:2E = Left Offices Corridor - Floor 5

══════════════════════════════════════════════
EXACT LAYOUT
══════════════════════════════════════════════

BEACON 1 - ELEVATOR (F4:7B:74:76:D5:8A):
  ROTATE RIGHT → elevator zone (LEFT SIDE): 525, 524, 523, 522.
  At Room 522, TURN RIGHT → main corridor toward 511:
    RIGHT SIDE: 501, 502, 503.
    LEFT SIDE : 521, 520, MEN'S TOILET (5WC), then Room 511 FACING at far end.
  TURN LEFT (directly from elevator) → left offices corridor:
    RIGHT SIDE: 526, 527, 528, 529.

BEACON 2 - ROOM 511 JUNCTION (C7:A4:5A:D0:74:D8):
  TURN RIGHT → sub-corridor toward 504-510:
    RIGHT SIDE: WOMEN'S TOILET (5WC2) (just after Back Stairs), 504, 505, 506.
    LEFT SIDE : 510, 509, 508.
    FACING at far end: Room 507.
  TURN LEFT from 511 → sub-corridor toward 512-519:
    RIGHT SIDE: 512, 513, 514, 515.
    LEFT SIDE : 519, 518, 517.
    FACING at far end: Room 516 (Journalism Lab).
  STRAIGHT BACK from 511 → walking through main corridor:
    LEFT SIDE (as you walk back): 503 (FIRST door), 502 (SECOND door), 501 (THIRD/LAST door).
    RIGHT SIDE (as you walk back): MEN'S TOILET (FIRST door), 520 (SECOND door), 521 (THIRD door).
    NOTE: Rooms 501,502,503,520,521,Men's Toilet are all IN the corridor between 511 and the elevator.
    You reach them BEFORE reaching the elevator beacon. The elevator beacon is BEYOND Room 521/501.
    
BEACON 3 - LEFT OFFICES (F3:55:BD:A3:65:2E):
  FORWARD: RIGHT SIDE: 526, 527, 528, 529 (529 at end).
  BACK → elevator junction.

══════════════════════════════════════════════
ROOM ZONES
══════════════════════════════════════════════
Elevator zone : 522, 523, 524, 525  ← ONLY reachable at elevator beacon
Main corridor : 501, 502, 503, 520, 521, MEN'S TOILET (5WC)  ← IN the corridor, reached WITHOUT going to elevator beacon
511 right zone: WOMEN'S TOILET (5WC2), 504, 505, 506, 507, 508, 509, 510
511 left zone : 511, 512, 513, 514, 515, 516, 517, 518, 519
Left offices  : 526, 527, 528, 529

══════════════════════════════════════════════
ROUTING RULES
══════════════════════════════════════════════
- MEN'S TOILET (5WC) from ELEVATOR: single step.
- WOMEN'S TOILET (5WC2) from ELEVATOR: 2 steps (Elevator→511, turn RIGHT).
- WOMEN'S TOILET (5WC2) from 511 JUNCTION: single step (turn RIGHT).
- 526-529 ONLY via Left Offices. From 511: go 511→Elevator→Left Offices (3 steps).
- 511-zone rooms (504-519, Women's Toilet) from Elevator: 2 steps.
- 511-zone rooms from Left Offices: 3 steps (LeftOffices→Elevator→511, then turn).
⚠️ FROM 511 JUNCTION — CRITICAL SINGLE-STEP RULES:
- Main corridor rooms (501,502,503,520,521) from 511: SINGLE STEP direction=forward. Walk straight back through corridor. Stop at the door. Do NOT route via elevator.
- MEN'S TOILET (5WC) from 511: SINGLE STEP direction=forward. It is the FIRST door on your RIGHT when walking back. Do NOT turn right (right leads to Women's Toilet/Back Stairs).
- Elevator-zone rooms (522,523,524,525) from 511: 2 steps — step 1 forward to elevator, step 2 rotate left.
- Always shortest path. Final step: exact side, door count, landmark.

══════════════════════════════════════════════
ALL PATHS — FROM ELEVATOR
══════════════════════════════════════════════

From Elevator → Room 525:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT from the elevator. Room 525 is the FIRST door on your LEFT."

From Elevator → Room 524:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Pass Room 525. Room 524 is the SECOND door on your LEFT."

From Elevator → Room 523:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Pass Rooms 525, 524. Room 523 is the THIRD door on your LEFT."

From Elevator → Room 522:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Pass Rooms 525, 524, 523. Room 522 is the FOURTH door on your LEFT."

From Elevator → Room 501:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522 into the main corridor. Room 501 is the FIRST door on your RIGHT."

From Elevator → Room 502:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Room 501. Room 502 is the SECOND door on your RIGHT."

From Elevator → Room 503:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Rooms 501, 502. Room 503 is the THIRD door on your RIGHT."

From Elevator → Room 521:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Room 521 is the FIRST door on your LEFT."

From Elevator → Room 520:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Room 521. Room 520 is the SECOND door on your LEFT."

From Elevator → MEN'S TOILET (5WC):
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Room 521 and Room 520 on your LEFT. MEN'S TOILET (5WC) is on your LEFT after Room 520."

From Elevator → Room 511:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor. Room 511 is FACING YOU at the far end."

From Elevator → WOMEN'S TOILET (5WC2):
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 at the far end."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass the Back Stairs. WOMEN'S TOILET (5WC2) is immediately on your RIGHT after the stairs."

From Elevator → Room 504:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 at the far end."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Back Stairs and WOMEN'S TOILET (5WC2) on your RIGHT. Room 504 is the FIRST door on your RIGHT after the toilet."

From Elevator → Room 505:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Back Stairs, WOMEN'S TOILET (5WC2), Room 504. Room 505 is the SECOND door on your RIGHT."

From Elevator → Room 506:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Back Stairs, WOMEN'S TOILET (5WC2), Rooms 504, 505. Room 506 is the THIRD door on your RIGHT."

From Elevator → Room 507:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Room 507 is FACING YOU at the end."

From Elevator → Room 510:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Room 510 is the FIRST door on your LEFT."

From Elevator → Room 509:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Room 510. Room 509 is the SECOND door on your LEFT."

From Elevator → Room 508:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Rooms 510, 509. Room 508 is the THIRD door on your LEFT."

From Elevator → Room 512:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Room 512 is the FIRST door on your RIGHT."

From Elevator → Room 513:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Room 512. Room 513 is the SECOND door on your RIGHT."

From Elevator → Room 514:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Rooms 512, 513. Room 514 is the THIRD door on your RIGHT."

From Elevator → Room 515:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Rooms 512, 513, 514. Room 515 is the FOURTH door on your RIGHT."

From Elevator → Room 516 (Journalism Lab):
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Walk the full corridor. Room 516 is FACING YOU at the end."

From Elevator → Room 519:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Room 519 is the FIRST door on your LEFT."

From Elevator → Room 518:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Room 519. Room 518 is the SECOND door on your LEFT."

From Elevator → Room 517:
  Step 1 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 2 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Rooms 519, 518. Room 517 is the THIRD door on your LEFT."

From Elevator → Room 526:
  Step 1 | F4:7B:74:76:D5:8A left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | F3:55:BD:A3:65:2E forward
  "Room 526 is the FIRST door on your RIGHT."

From Elevator → Room 527:
  Step 1 | F4:7B:74:76:D5:8A left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | F3:55:BD:A3:65:2E forward
  "Pass Room 526. Room 527 is the SECOND door on your RIGHT."

From Elevator → Room 528:
  Step 1 | F4:7B:74:76:D5:8A left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | F3:55:BD:A3:65:2E forward
  "Pass Rooms 526, 527. Room 528 is the THIRD door on your RIGHT."

From Elevator → Room 529:
  Step 1 | F4:7B:74:76:D5:8A left
  "Turn LEFT from the elevator into the left offices corridor."
  Step 2 | F3:55:BD:A3:65:2E forward
  "Walk to the end. Room 529 is the LAST door on your RIGHT."

══════════════════════════════════════════════
ALL PATHS — FROM ROOM 511 JUNCTION
══════════════════════════════════════════════

From Room 511 → WOMEN'S TOILET (5WC2):
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Pass the Back Stairs. WOMEN'S TOILET (5WC2) is immediately on your RIGHT."

From Room 511 → Room 504:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Pass Back Stairs and WOMEN'S TOILET (5WC2). Room 504 is the FIRST door on your RIGHT after the toilet."

From Room 511 → Room 505:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Pass Back Stairs, WOMEN'S TOILET (5WC2), Room 504. Room 505 is the SECOND door on your RIGHT."

From Room 511 → Room 506:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Pass Back Stairs, WOMEN'S TOILET (5WC2), Rooms 504, 505. Room 506 is the THIRD door on your RIGHT."

From Room 511 → Room 507:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Walk the full corridor; Room 507 is FACING YOU at the end."

From Room 511 → Room 510:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Room 510 is the FIRST door on your LEFT."

From Room 511 → Room 509:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Pass Room 510. Room 509 is the SECOND door on your LEFT."

From Room 511 → Room 508:
  Step 1 | C7:A4:5A:D0:74:D8 right
  "Turn RIGHT at Room 511. Pass Rooms 510, 509. Room 508 is the THIRD door on your LEFT."

From Room 511 → Room 512:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Room 512 is the FIRST door on your RIGHT."

From Room 511 → Room 513:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Pass Room 512. Room 513 is the SECOND door on your RIGHT."

From Room 511 → Room 514:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Pass Rooms 512, 513. Room 514 is the THIRD door on your RIGHT."

From Room 511 → Room 515:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Pass Rooms 512, 513, 514. Room 515 is the FOURTH door on your RIGHT."

From Room 511 → Room 516 (Journalism Lab):
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Walk the full corridor. Room 516 is FACING YOU at the end."

From Room 511 → Room 519:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Room 519 is the FIRST door on your LEFT."

From Room 511 → Room 518:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Pass Room 519. Room 518 is the SECOND door on your LEFT."

From Room 511 → Room 517:
  Step 1 | C7:A4:5A:D0:74:D8 left
  "Turn LEFT at Room 511. Pass Rooms 519, 518. Room 517 is the THIRD door on your LEFT."

From Room 511 → MEN'S TOILET (5WC):
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK into the main corridor; MEN'S TOILET (5WC) is the FIRST door on your RIGHT."

From Room 511 → Room 501:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK into the main corridor; Room 501 is the LAST door on your LEFT."

From Room 511 → Room 502:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK into the main corridor; Room 502 is the SECOND door on your LEFT."

From Room 511 → Room 503:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK into the main corridor; Room 503 is the FIRST door on your LEFT."

From Room 511 → Room 520:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK into the main corridor. Pass MEN'S TOILET (5WC) on your RIGHT. Room 520 is the NEXT door on your RIGHT."

From Room 511 → Room 521:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK into the main corridor. Pass MEN'S TOILET (5WC) and Room 520 on your RIGHT. Room 521 is the NEXT door on your RIGHT."

From Room 511 → Room 522:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "Rotate LEFT. Room 522 is the FIRST door on your RIGHT."

From Room 511 → Room 523:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "Rotate LEFT. Room 523 is the SECOND door on your RIGHT."

From Room 511 → Room 524:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "Rotate LEFT. Pass 525. Room 524 is the THIRD door on your RIGHT."

From Room 511 → Room 525:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "Rotate LEFT. Room 525 is the LAST door on your RIGHT."

From Room 511 → Room 526:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | F3:55:BD:A3:65:2E forward
  "Room 526 is the FIRST door on your RIGHT."

From Room 511 → Room 527:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | F3:55:BD:A3:65:2E forward
  "Pass Room 526. Room 527 is the SECOND door on your RIGHT."

From Room 511 → Room 528:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | F3:55:BD:A3:65:2E forward
  "Pass Rooms 526, 527. Room 528 is the THIRD door on your RIGHT."

From Room 511 → Room 529:
  Step 1 | C7:A4:5A:D0:74:D8 forward
  "Walk BACK through the main corridor all the way into the ELEVATOR AREA."
  Step 2 | F4:7B:74:76:D5:8A left
  "At the elevator, turn LEFT into the left offices corridor."
  Step 3 | F3:55:BD:A3:65:2E forward
  "Walk to the end. Room 529 is the LAST door on your RIGHT."

══════════════════════════════════════════════
ALL PATHS — FROM LEFT OFFICES
══════════════════════════════════════════════

From Left Offices → Room 526:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Room 526 is the FIRST door on your RIGHT."

From Left Offices → Room 527:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Pass Room 526. Room 527 is the SECOND door on your RIGHT."

From Left Offices → Room 528:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Pass Rooms 526, 527. Room 528 is the THIRD door on your RIGHT."

From Left Offices → Room 529:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Walk to the end. Room 529 is the LAST door on your RIGHT."

From Left Offices → Room 525:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Room 525 is the FIRST door on your LEFT."

From Left Offices → Room 524:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Pass Room 525. Room 524 is the SECOND door on your LEFT."

From Left Offices → Room 523:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Pass Rooms 525, 524. Room 523 is the THIRD door on your LEFT."

From Left Offices → Room 522:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT. Pass Rooms 525, 524, 523. Room 522 is the FOURTH door on your LEFT."

From Left Offices → Room 501:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Room 501 is the FIRST door on your RIGHT."

From Left Offices → Room 502:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Room 501. Room 502 is the SECOND door on your RIGHT."

From Left Offices → Room 503:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Rooms 501, 502. Room 503 is the THIRD door on your RIGHT."

From Left Offices → Room 521:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Room 521 is the FIRST door on your LEFT."

From Left Offices → Room 520:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Room 521. Room 520 is the SECOND door on your LEFT."

From Left Offices → MEN'S TOILET (5WC):
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Pass Room 521 and Room 520. MEN'S TOILET (5WC) is the NEXT door on your LEFT."

From Left Offices → Room 511:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor. Room 511 is FACING YOU at the far end."

From Left Offices → WOMEN'S TOILET (5WC2):
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass the Back Stairs. WOMEN'S TOILET (5WC2) is immediately on your RIGHT."

From Left Offices → Room 504:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Back Stairs and WOMEN'S TOILET (5WC2). Room 504 is the FIRST door on your RIGHT."

From Left Offices → Room 505:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, Turn RIGHT. Pass Back Stairs, WOMEN'S TOILET (5WC2), Room 504. Room 505 is the SECOND door on your RIGHT."

From Left Offices → Room 506:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Back Stairs, WOMEN'S TOILET (5WC2), Rooms 504, 505. Room 506 is the THIRD door on your RIGHT."

From Left Offices → Room 507:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Walk the full corridor. Room 507 is FACING YOU at the end."

From Left Offices → Room 510:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Room 510 is the FIRST door on your LEFT."

From Left Offices → Room 509:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Room 510. Room 509 is the SECOND door on your LEFT."

From Left Offices → Room 508:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 right
  "At Room 511, turn RIGHT. Pass Room 510, Room 509. Room 508 is the THIRD door on your LEFT."

From Left Offices → Room 512:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Room 512 is the FIRST door on your RIGHT."

From Left Offices → Room 513:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Room 512. Room 513 is the SECOND door on your RIGHT."

From Left Offices → Room 514:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Rooms 512, 513. Room 514 is the THIRD door on your RIGHT."

From Left Offices → Room 515:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Rooms 512, 513, 514. Room 515 is the FOURTH door on your RIGHT."

From Left Offices → Room 516:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Walk the full corridor. Room 516 is FACING YOU at the end."

From Left Offices → Room 519:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Room 519 is the FIRST door on your LEFT."

From Left Offices → Room 518:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Room 519. Room 518 is the SECOND door on your LEFT."

From Left Offices → Room 517:
  Step 1 | F3:55:BD:A3:65:2E forward
  "Turn BACK and walk to the elevator."
  Step 2 | F4:7B:74:76:D5:8A right
  "Rotate RIGHT, pass Rooms 525, 524, 523, 522 on your LEFT, turn RIGHT at Room 522. Walk the full corridor until you REACH Room 511 in the end."
  Step 3 | C7:A4:5A:D0:74:D8 left
  "At Room 511, turn LEFT. Pass Rooms 519, 518. Room 517 is the THIRD door on your LEFT."
  
Output ONLY valid JSON — no markdown, no explanation:
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
          'model': 'gpt-4o',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': jsonEncode(userRequest)},
          ],
          'temperature': 0,
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
          final steps = pathList
              .map((s) => NavigationStep.fromJson(s as Map<String, dynamic>))
              .toList();

          print("AI returned ${steps.length} steps");
          for (var s in steps) {
            print("${s.beaconMac} | ${s.instruction}");
          }

          return NavigationResult(
            success: true,
            path: steps,
            totalBeacons: (result['total_beacons'] as num?)?.toInt() ?? steps.length,
            totalDistanceMeters: (result['total_distance_meters'] as num?)?.toInt() ?? 30,
            estimatedTimeMinutes: (result['estimated_time_minutes'] as num?)?.toInt() ?? 2,
            accessibilityCompliant: result['accessibility_compliant'] as bool? ?? true,
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
    bool arrivedFromStairs = false,
  }) async {

    final prompt = floor == 4 ? _floor4Prompt : _floor5Prompt;

    final beaconNames = {
      'C6:2A:90:A1:99:CB': 'Elevator - Floor 4',
      'E5:65:DD:D0:91:EC': 'Room 408 - Floor 4',
      'C8:93:08:09:B2:CA': 'Left Offices - Floor 4',
      'F4:7B:74:76:D5:8A': 'Elevator - Floor 5',
      'C7:A4:5A:D0:74:D8': 'Room 511 - Floor 5',
      'F3:55:BD:A3:65:2E': 'Left Offices - Floor 5',
    };
    final beaconLabel = beaconNames[currentBeaconMac] ?? beaconNames[currentBeaconMac.toUpperCase()] ?? currentBeaconMac;

    final sectionHeader = floor == 4
        ? (currentBeaconMac.toUpperCase() == 'C6:2A:90:A1:99:CB' ? 'ALL PATHS — FROM ELEVATOR'
        : currentBeaconMac.toUpperCase() == 'E5:65:DD:D0:91:EC' ? 'ALL PATHS — FROM ROOM 408 JUNCTION'
        : 'ALL PATHS — FROM LEFT OFFICES')
        : (currentBeaconMac.toUpperCase() == 'F4:7B:74:76:D5:8A' ? 'ALL PATHS — FROM ELEVATOR'
        : currentBeaconMac.toUpperCase() == 'C7:A4:5A:D0:74:D8' ? 'ALL PATHS — FROM ROOM 511 JUNCTION'
        : 'ALL PATHS — FROM LEFT OFFICES');

    final arrivalContext = (arrivedFromStairs && currentBeaconMac == 'C8:93:08:09:B2:CA')
        ? 'IMPORTANT: The user arrived at Left Offices from the stairs (coming down from Floor 5). '
        'Rooms are on the LEFT side in REVERSE order starting from 430. '
        'Use the "FROM STAIRS ARRIVAL" paths from the prompt.'
        : '';

    final request = {
      'user_current_location': beaconLabel,
      'user_current_beacon_mac': currentBeaconMac,
      'destination_room': destinationNumber,
      'floor': floor,
      'arrival_context': arrivalContext,
      'STRICT_INSTRUCTION':
      'You MUST use ONLY the section "$sectionHeader" from the prompt. '
          'Find the EXACT entry "From ${beaconLabel.split(' - ')[0]} → ${_resolveDestLabel(destinationNumber)}". '
          'Copy the route EXACTLY. '
          'Each source Step MUST become one separate JSON object in path[]. '
          'Never combine two Steps into one object. '
          'Never rewrite step count. '
          'Never skip beacon transitions. '
          'If a route contains Room 511 Junction beacon C7:A4:5A:D0:74:D8, it MUST appear as its own separate path object.'
          'If source route has 3 steps, output exactly 3 objects. '
          'If source route has 2 steps, output exactly 2 objects. '
          'Beacon MAC for each object must match its original step. '
          'Instructions must remain attached to their original beacon only.'
          'Room numbers 424-430 are LEFT OFFICES rooms — they are NEVER reached by turning left at Room 408 junction. '
          'From Room 408 Junction, reaching rooms 424-430 requires walking BACK to elevator first, then turning LEFT.'
          'CRITICAL: Never repeat the same beacon_mac in two different path objects. '
          'Each beacon MAC must appear EXACTLY ONCE in the path array. '
          'If the route has 1 step, output exactly 1 object. '
          'CRITICAL: Room 525 is in the ELEVATOR ZONE — it requires 2 steps: '
          'step 1 beacon C7:A4:5A:D0:74:D8 walks to elevator, '
          'step 2 beacon F4:7B:74:76:D5:8A rotates left to find Room 525. '
          'Never use main corridor instructions for elevator zone rooms. ',
    };
    return _callOpenAI(prompt, request, apiKey);
  }
  String _resolveDestLabel(String dest) {
    switch (dest) {
      case '4WC':  return "MEN'S TOILET (4WC)";
      case '4WC2': return "WOMEN'S TOILET (4WC2)";
      case '5WC':  return "MEN'S TOILET (5WC)";
      case '5WC2': return "WOMEN'S TOILET (5WC2)";
      default:     return 'Room $dest';
    }
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
    const backStairsDestinations = {
      '504','505','506','507','508','509','510','511',
      '512','513','514','515','516','517','518','519','5WC2'
    };

    const leftOfficesF4 = 'C8:93:08:09:B2:CA';
    const elevatorF4 = 'C6:2A:90:A1:99:CB';
    const elevatorF5 = 'F4:7B:74:76:D5:8A';
    const junctionF4 = 'E5:65:DD:D0:91:EC';
    const junctionF5 = 'C7:A4:5A:D0:74:D8';

    final mac = currentBeaconMac.toUpperCase();
    final isAtElevator = mac == elevatorF5.toUpperCase();
    final isAtJunction = mac == junctionF4.toUpperCase() ||
        mac == junctionF5.toUpperCase();

    final List<NavigationStep> path = [];
    int totalDistance = 0;
    final ud = destFloor > currentFloor ? 'UP' : 'DOWN';

    if (isAtElevator) {
      path.add(NavigationStep(
        beaconMac: currentBeaconMac,
        location: 'Elevator / Main Stairs — Floor $currentFloor',
        floor: currentFloor,
        instruction: 'You are at the elevator. '
            'Take the Main Stairs or Elevator $ud to Floor $destFloor — '
            'they are right next to you.',
        direction: ud.toLowerCase(),
      ));
      totalDistance += 5;

      path.add(NavigationStep(
        beaconMac: 'STAIRS',
        location: 'Main Stairs',
        floor: '$currentFloor→$destFloor',
        instruction: 'Take the Main Stairs or Elevator $ud to Floor $destFloor.',
        direction: ud.toLowerCase(),
      ));
      totalDistance += 10;

      final destArrivalBeacon = destFloor == 4 ? leftOfficesF4 : elevatorF5;
      final step3 = await navigateSameFloor(
          currentBeaconMac: destArrivalBeacon,
          floor: destFloor,
          destinationNumber: destinationNumber,
          apiKey: apiKey,
          arrivedFromStairs: destArrivalBeacon == leftOfficesF4);
      if (step3.success) {
        final existingMacs = path
            .where((s) => s.beaconMac != 'STAIRS')
            .map((s) => s.beaconMac.toUpperCase())
            .toSet();

        final seenInStep3 = <String>{};
        final deduped = step3.path.where((s) {
          final mac = s.beaconMac.toUpperCase();
          if (existingMacs.contains(mac)) return false;
          if (seenInStep3.contains(mac)) return false;
          seenInStep3.add(mac);
          return true;
        }).toList();

        path.addAll(deduped);
        totalDistance += step3.totalDistanceMeters;
      }

    } else if (isAtJunction) {
      path.add(NavigationStep(
        beaconMac: currentBeaconMac,
        location: currentFloor == 4
            ? 'Room 408 Junction — Floor 4'
            : 'Room 511 Junction — Floor 5',
        floor: currentFloor,
        instruction: 'Turn RIGHT from the junction toward the Back Stairs. '
            'Take the Back Stairs $ud to Floor $destFloor.',
        direction: 'right',
      ));
      totalDistance += 5;

      path.add(NavigationStep(
        beaconMac: 'STAIRS',
        location: 'Back Stairs',
        floor: '$currentFloor→$destFloor',
        instruction: 'Take the Back Stairs $ud to Floor $destFloor.',
        direction: ud.toLowerCase(),
      ));
      totalDistance += 10;

      final destJunctionBeacon = destFloor == 4 ? junctionF4 : junctionF5;
      final step3 = await navigateSameFloor(
          currentBeaconMac: destJunctionBeacon,
          floor: destFloor,
          destinationNumber: destinationNumber,
          apiKey: apiKey);
      if (step3.success) {
        final existingMacs = path
            .where((s) => s.beaconMac != 'STAIRS')
            .map((s) => s.beaconMac.toUpperCase())
            .toSet();

        final seenInStep3 = <String>{};
        final deduped = step3.path.where((s) {
          final mac = s.beaconMac.toUpperCase();
          if (existingMacs.contains(mac)) return false;
          if (seenInStep3.contains(mac)) return false;
          seenInStep3.add(mac);
          return true;
        }).toList();

        path.addAll(deduped);
        totalDistance += step3.totalDistanceMeters;
      }

    } else if (mac == leftOfficesF4.toUpperCase() && currentFloor == 4) {
      path.add(NavigationStep(
        beaconMac: leftOfficesF4,
        location: 'Main Stairs — Floor 4',
        floor: 4,
        instruction: 'You are at the main stairs. Take them UP to Floor 5.',
        direction: 'up',
      ));
      totalDistance += 5;

      path.add(NavigationStep(
        beaconMac: 'STAIRS',
        location: 'Main Stairs',
        floor: '4→5',
        instruction: 'Take the Main Stairs UP to Floor 5.',
        direction: 'up',
      ));
      totalDistance += 10;

      final step3 = await navigateSameFloor(
          currentBeaconMac: elevatorF5,
          floor: 5,
          destinationNumber: destinationNumber,
          apiKey: apiKey);
      if (step3.success) {
        final existingMacs = path
            .where((s) => s.beaconMac != 'STAIRS')
            .map((s) => s.beaconMac.toUpperCase())
            .toSet();

        final seenInStep3 = <String>{};
        final deduped = step3.path.where((s) {
          final mac = s.beaconMac.toUpperCase();
          if (existingMacs.contains(mac)) return false;
          if (seenInStep3.contains(mac)) return false;
          seenInStep3.add(mac);
          return true;
        }).toList();

        path.addAll(deduped);
        totalDistance += step3.totalDistanceMeters;
      }

    } else if (mac == elevatorF4.toUpperCase() && currentFloor == 4) {

      final useBackStairs = backStairsDestinations.contains(destinationNumber);

      if (useBackStairs) {
        path.add(NavigationStep(
          beaconMac: elevatorF4,
          location: 'Elevator / Main Stairs — Floor 4',
          floor: 4,
          instruction: 'Walk toward Room 408 junction to take the BACK STAIRS',
          direction: 'right',
        ));
        totalDistance += 10;

        path.add(NavigationStep(
          beaconMac: junctionF4,
          location: 'Room 408 Junction — Floor 4',
          floor: 4,
          instruction: 'Turn RIGHT toward the Back Stairs. Take them UP to Floor 5.',
          direction: 'right',
        ));
        totalDistance += 10;

        path.add(NavigationStep(
          beaconMac: 'STAIRS',
          location: 'Back Stairs',
          floor: '4→5',
          instruction: 'Take the Back Stairs UP to Floor 5.',
          direction: 'up',
        ));
        totalDistance += 10;

        final step3 = await navigateSameFloor(
            currentBeaconMac: junctionF5,
            floor: 5,
            destinationNumber: destinationNumber,
            apiKey: apiKey);
        if (step3.success) {
          final existingMacs = path
              .where((s) => s.beaconMac != 'STAIRS')
              .map((s) => s.beaconMac.toUpperCase())
              .toSet();
          final seenInStep3 = <String>{};
          final deduped = step3.path.where((s) {
            final m = s.beaconMac.toUpperCase();
            if (existingMacs.contains(m)) return false;
            if (seenInStep3.contains(m)) return false;
            seenInStep3.add(m);
            return true;
          }).toList();
          path.addAll(deduped);
          totalDistance += step3.totalDistanceMeters;
        }

      } else {
        path.add(NavigationStep(
          beaconMac: elevatorF4,
          location: 'Elevator / Main Stairs — Floor 4',
          floor: 4,
          instruction: 'Turn LEFT toward the Left Offices corridor to take the MAIN STAIRS.',
          direction: 'left',
        ));
        totalDistance += 5;

        path.add(NavigationStep(
          beaconMac: leftOfficesF4,
          location: 'Main Stairs — Floor 4',
          floor: 4,
          instruction: 'You have reached the Main Stairs. Take them UP to Floor 5.',
          direction: 'up',
        ));
        totalDistance += 5;

        path.add(NavigationStep(
          beaconMac: 'STAIRS',
          location: 'Main Stairs',
          floor: '4→5',
          instruction: 'Take the Main Stairs UP to Floor 5.',
          direction: 'up',
        ));
        totalDistance += 10;

        final destArrivalBeacon = elevatorF5;
        final step3 = await navigateSameFloor(
            currentBeaconMac: destArrivalBeacon,
            floor: 5,
            destinationNumber: destinationNumber,
            apiKey: apiKey);
        if (step3.success) {
          final existingMacs = path
              .where((s) => s.beaconMac != 'STAIRS')
              .map((s) => s.beaconMac.toUpperCase())
              .toSet();
          final seenInStep3 = <String>{};
          final deduped = step3.path.where((s) {
            final m = s.beaconMac.toUpperCase();
            if (existingMacs.contains(m)) return false;
            if (seenInStep3.contains(m)) return false;
            seenInStep3.add(m);
            return true;
          }).toList();
          path.addAll(deduped);
          totalDistance += step3.totalDistanceMeters;
        }
      }

    } else {
      final currentElevatorBeacon = currentFloor == 4 ? leftOfficesF4 : elevatorF5;

      final elevatorDestRoom = currentFloor == 4 ? '424' : '525';
      final step1 = await navigateSameFloor(
          currentBeaconMac: currentBeaconMac,
          floor: currentFloor,
          destinationNumber: elevatorDestRoom,
          apiKey: apiKey);
      if (step1.success) {
        path.addAll(step1.path);
        totalDistance += step1.totalDistanceMeters;
      }

      path.add(NavigationStep(
        beaconMac: currentElevatorBeacon,
        location: 'Elevator / Main Stairs — Floor $currentFloor',
        floor: currentFloor,
        instruction: 'You have reached the elevator. '
            'Take the Main Stairs or Elevator $ud to Floor $destFloor.',
        direction: ud.toLowerCase(),
      ));
      totalDistance += 5;

      path.add(NavigationStep(
        beaconMac: 'STAIRS',
        location: 'Main Stairs',
        floor: '$currentFloor→$destFloor',
        instruction: 'Take the Main Stairs or Elevator $ud to Floor $destFloor.',
        direction: ud.toLowerCase(),
      ));
      totalDistance += 10;

      final destArrivalBeacon = destFloor == 4 ? leftOfficesF4 : elevatorF5;
      final step3 = await navigateSameFloor(
          currentBeaconMac: destArrivalBeacon,
          floor: destFloor,
          destinationNumber: destinationNumber,
          apiKey: apiKey,
          arrivedFromStairs: destArrivalBeacon == leftOfficesF4);
      if (step3.success) {
        final existingMacs = path
            .where((s) => s.beaconMac != 'STAIRS')
            .map((s) => s.beaconMac.toUpperCase())
            .toSet();

        final seenInStep3 = <String>{};
        final deduped = step3.path.where((s) {
          final mac = s.beaconMac.toUpperCase();
          if (existingMacs.contains(mac)) return false;
          if (seenInStep3.contains(mac)) return false;
          seenInStep3.add(mac);
          return true;
        }).toList();

        path.addAll(deduped);
        totalDistance += step3.totalDistanceMeters;
      }
    }

    return NavigationResult(
      success: true,
      path: path,
      totalBeacons: path.length,
      totalDistanceMeters: totalDistance,
      estimatedTimeMinutes: (totalDistance / 20).ceil().clamp(2, 99),
      accessibilityCompliant: false,
      floorChanges: ['Floor $currentFloor → Floor $destFloor'],
      stairsUsed: isAtJunction ? 'Back Stairs' : 'Main Stairs / Elevator',
    );
  }
}