import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

// ============================================================================
// BEACON DATA MODEL
// ============================================================================
class BeaconData {
  final String mac;
  final String name;
  final String locationDescription;
  final Offset physicalPosition; // Real-world coordinates (x, y in meters)
  final List<String> connectedBeacons; // Adjacent beacons (for pathfinding)
  final String floor;
  final Map<String, dynamic> metadata;

  BeaconData({
    required this.mac,
    required this.name,
    required this.locationDescription,
    required this.physicalPosition,
    required this.connectedBeacons,
    required this.floor,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'mac': mac,
    'name': name,
    'location_description': locationDescription,
    'physical_position': {
      'x': physicalPosition.dx,
      'y': physicalPosition.dy,
    },
    'connected_beacons': connectedBeacons,
    'floor': floor,
    'metadata': metadata,
  };
}

// ============================================================================
// DESTINATION MODEL
// ============================================================================
class Destination {
  final String id;
  final String name;
  final String description;
  final String nearestBeaconMac;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.nearestBeaconMac,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'nearest_beacon_mac': nearestBeaconMac,
  };
}

// ============================================================================
// AI PATH PLANNER SERVICE
// ============================================================================
class AIPathPlannerService {
  static const String apiKey = ''; // Replace with your key
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Using GPT-3.5-turbo for fastest response and lowest cost
  // This model is optimized for quick computations like pathfinding
  static String model = const String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-3.5-turbo');

  /// Simple HTTP POST helper with exponential backoff and jitter to handle 429/5xx
  static Future<http.Response> _postWithRetry(
      Uri url, {
        required Map<String, String> headers,
        required String body,
        int maxRetries = 3,
      }) async {
    int attempt = 0;
    while (true) {
      try {
        final resp = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) return resp;

        // Retry on rate limiting or server errors
        if (resp.statusCode == 429 || resp.statusCode >= 500) {
          attempt++;
          if (attempt > maxRetries) return resp;

          final retryAfter = resp.headers['retry-after'];
          int waitSeconds = retryAfter != null ? int.tryParse(retryAfter) ?? (2 << attempt) : (2 * (1 << attempt));
          final jitterMs = DateTime.now().millisecondsSinceEpoch % 500;
          await Future.delayed(Duration(milliseconds: waitSeconds * 1000 + jitterMs));
          continue;
        }

        // Non-retryable response - return as-is
        return resp;
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
      }
    }
  }

  // Optimized system prompt - concise but complete
  static const String systemPrompt = '''
You are an indoor navigation pathfinding AI. Calculate the shortest path between beacons using Dijkstra's algorithm.

INPUT FORMAT:
- Current beacon: MAC, name, position (x,y meters), floor, connections
- Destination beacon: MAC, name, position, floor
- Beacon network: All beacons with positions and connections

ALGORITHM:
1. Use Euclidean distance: √[(x₂-x₁)² + (y₂-y₁)²]
2. Only traverse connected beacons
3. Find shortest path by total distance
4. Walking speed: 1.3 m/s for time estimates

OUTPUT (JSON ONLY):
{
  "success": true,
  "path": [
    {
      "beacon_mac": "MAC_ADDRESS",
      "beacon_name": "Location Name",
      "instruction": "Walk from [location] to [next location]",
      "distance_to_next": 20.5,
      "estimated_time_seconds": 16
    }
  ],
  "total_distance": 40.0,
  "total_time_seconds": 31,
  "floor_changes": 0,
  "path_summary": "Route from A to B via C",
  "alternative_paths_available": false,
  "warnings": []
}

ERROR FORMAT:
{
  "success": false,
  "error": "Error description",
  "reason": "no_path_available|same_location|invalid_input",
  "suggestion": "What to do next"
}

INSTRUCTIONS:
- Be specific: "Walk 20m down the corridor to East Wing"
- Last step: "You have arrived at [destination]"
- If same location: return error with reason "same_location"
- If no connection: return error with reason "no_path_available"

Return ONLY valid JSON, no explanation.
''';

  static Future<Map<String, dynamic>> calculatePath({
    required String currentBeaconMac,
    required Destination destination,
    required List<BeaconData> beaconNetwork,
  }) async {
    try {
      // Find current beacon details
      final currentBeacon = beaconNetwork.firstWhere(
            (b) => b.mac == currentBeaconMac,
        orElse: () => throw Exception('Current beacon not found in network'),
      );

      // Find destination beacon details
      final destBeacon = beaconNetwork.firstWhere(
            (b) => b.mac == destination.nearestBeaconMac,
        orElse: () => throw Exception('Destination beacon not found in network'),
      );

      // Prepare compact user prompt
      final String userPrompt = '''
NAVIGATE FROM: ${currentBeacon.name} (${currentBeacon.mac}) at (${currentBeacon.physicalPosition.dx}, ${currentBeacon.physicalPosition.dy})
TO: ${destination.name} via ${destBeacon.name} (${destBeacon.mac}) at (${destBeacon.physicalPosition.dx}, ${destBeacon.physicalPosition.dy})

BEACONS:
${_formatBeaconNetworkCompact(beaconNetwork)}

Calculate shortest path. Return JSON only.
''';

      // Ensure API key is configured
      if (apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
        print('⚠️ No API key configured, using local Dijkstra algorithm');
        return await calculateLocalPath(
          currentBeaconMac: currentBeaconMac,
          destination: destination,
          beaconNetwork: beaconNetwork,
        );
      }

      final requestBody = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.0,
        'max_tokens': 800,
      });

      final response = await _postWithRetry(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final pathResult = jsonDecode(content);

        return pathResult;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Unauthorized - invalid API key',
          'reason': 'auth_error',
          'suggestion': 'Validate your API key and rotate it if it was leaked. See your OpenAI dashboard to confirm key status.'
        };
      } else if (response.statusCode == 429) {
        // Rate limit hit - fall back to local computation
        print('⚠️ OpenAI rate limit exceeded, using local Dijkstra algorithm');
        return await calculateLocalPath(
          currentBeaconMac: currentBeaconMac,
          destination: destination,
          beaconNetwork: beaconNetwork,
        );
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('⚠️ API error: $e - falling back to local computation');
      return await calculateLocalPath(
        currentBeaconMac: currentBeaconMac,
        destination: destination,
        beaconNetwork: beaconNetwork,
      );
    }
  }

  /// Local pathfinding helper using Dijkstra's algorithm (fallback when API unavailable)
  static Future<Map<String, dynamic>> calculateLocalPath({
    required String currentBeaconMac,
    required Destination destination,
    required List<BeaconData> beaconNetwork,
  }) async {
    final Map<String, BeaconData> byMac = { for (var b in beaconNetwork) b.mac : b };

    if (!byMac.containsKey(currentBeaconMac)) {
      return {
        'success': false,
        'error': 'Current beacon not found in network',
        'reason': 'invalid_input',
        'suggestion': 'Verify the current beacon MAC is present in the beacon network'
      };
    }

    if (!byMac.containsKey(destination.nearestBeaconMac)) {
      return {
        'success': false,
        'error': 'Destination beacon not found in network',
        'reason': 'invalid_input',
        'suggestion': 'Verify the destination nearest beacon MAC is present in the beacon network'
      };
    }

    final start = byMac[currentBeaconMac]!;
    final goal = byMac[destination.nearestBeaconMac]!;

    if (start.mac == goal.mac) {
      return {
        'success': false,
        'error': 'Source and destination are the same',
        'reason': 'same_location',
        'suggestion': 'You are already at the destination'
      };
    }

    final Set<String> visited = {};
    final Map<String, double> dist = {};
    final Map<String, String?> prev = {};

    for (var m in byMac.keys) {
      dist[m] = double.infinity;
      prev[m] = null;
    }
    dist[start.mac] = 0.0;

    while (visited.length < byMac.length) {
      String? u;
      double best = double.infinity;
      for (var entry in dist.entries) {
        if (visited.contains(entry.key)) continue;
        if (entry.value < best) {
          best = entry.value;
          u = entry.key;
        }
      }
      if (u == null) break;
      if (u == goal.mac) break;
      visited.add(u);

      final node = byMac[u]!;
      for (var neighborMac in node.connectedBeacons) {
        if (!byMac.containsKey(neighborMac)) continue;
        if (visited.contains(neighborMac)) continue;
        final neighbor = byMac[neighborMac]!;
        final dx = node.physicalPosition.dx - neighbor.physicalPosition.dx;
        final dy = node.physicalPosition.dy - neighbor.physicalPosition.dy;
        final edgeLen = math.sqrt(dx * dx + dy * dy);
        final alt = dist[u]! + edgeLen;
        if (alt < dist[neighborMac]!) {
          dist[neighborMac] = alt;
          prev[neighborMac] = u;
        }
      }
    }

    if (dist[goal.mac] == double.infinity) {
      return {
        'success': false,
        'error': 'No path found to destination',
        'reason': 'no_path_available',
        'suggestion': 'Check beacon connectivity and ensure there is a connected route'
      };
    }

    final List<String> pathMacs = [];
    String? cur = goal.mac;
    while (cur != null) {
      pathMacs.insert(0, cur);
      cur = prev[cur];
    }

    final List<Map<String, dynamic>> pathSteps = [];
    double totalDist = 0.0;
    int floorChanges = 0;
    final walkingSpeed = 1.3; // m/s

    for (int i = 0; i < pathMacs.length; i++) {
      final m = pathMacs[i];
      final beacon = byMac[m]!;
      double distanceToNext = 0.0;
      int estimatedTime = 0;
      if (i < pathMacs.length - 1) {
        final next = byMac[pathMacs[i + 1]]!;
        final dx = beacon.physicalPosition.dx - next.physicalPosition.dx;
        final dy = beacon.physicalPosition.dy - next.physicalPosition.dy;
        distanceToNext = math.sqrt(dx * dx + dy * dy);
        totalDist += distanceToNext;
        estimatedTime = (distanceToNext / walkingSpeed).round();
        if (beacon.floor != next.floor) floorChanges += 1;
      }

      final instruction = (i < pathMacs.length - 1)
          ? 'Proceed from ${beacon.name} to ${byMac[pathMacs[i + 1]]!.name} for ${distanceToNext.toStringAsFixed(1)} meters.'
          : 'You have arrived at ${beacon.name}.';

      pathSteps.add({
        'beacon_mac': beacon.mac,
        'beacon_name': beacon.name,
        'instruction': instruction,
        'distance_to_next': double.parse(distanceToNext.toStringAsFixed(1)),
        'estimated_time_seconds': estimatedTime,
      });
    }

    final totalTime = totalDist / walkingSpeed;

    return {
      'success': true,
      'path': pathSteps,
      'total_distance': double.parse(totalDist.toStringAsFixed(1)),
      'total_time_seconds': totalTime.round(),
      'floor_changes': floorChanges,
      'path_summary': 'Local shortest path computed using Dijkstra algorithm',
      'alternative_paths_available': false,
      'warnings': ['⚠️ Computed locally - OpenAI API unavailable or rate limited'],
    };
  }

  static String _formatBeaconNetworkCompact(List<BeaconData> beacons) {
    final buffer = StringBuffer();
    for (var beacon in beacons) {
      buffer.writeln('${beacon.mac}: ${beacon.name} at (${beacon.physicalPosition.dx}, ${beacon.physicalPosition.dy}) → [${beacon.connectedBeacons.join(", ")}]');
    }
    return buffer.toString();
  }

  static String _formatBeaconNetwork(List<BeaconData> beacons) {
    final buffer = StringBuffer();
    for (var beacon in beacons) {
      buffer.writeln('''
Beacon ID: ${beacon.mac}
  - Name: ${beacon.name}
  - Location: ${beacon.locationDescription}
  - Position: (${beacon.physicalPosition.dx}m, ${beacon.physicalPosition.dy}m)
  - Floor: ${beacon.floor}
  - Connected to: ${beacon.connectedBeacons.join(', ')}
  - Metadata: ${beacon.metadata}
''');
    }
    return buffer.toString();
  }
}

// ============================================================================
// DEMO WIDGET: PATH PLANNING INTERFACE
// ============================================================================
class PathPlanningDemo extends StatefulWidget {
  const PathPlanningDemo({Key? key}) : super(key: key);

  @override
  State<PathPlanningDemo> createState() => _PathPlanningDemoState();
}

class _PathPlanningDemoState extends State<PathPlanningDemo> {
  // Sample beacon network with 3 beacons forming a linear path
  final List<BeaconData> beaconNetwork = [
    BeaconData(
      mac: 'D3:5F:B3:48:14:CA',
      name: 'Main Entrance',
      locationDescription: 'Building A main entrance lobby, near information desk',
      physicalPosition: Offset(0, 0),
      connectedBeacons: ['F3:55:BD:A3:65:2E'],
      floor: 'Ground Floor',
      metadata: {'building': 'A', 'accessibility': 'wheelchair_accessible'},
    ),
    BeaconData(
      mac: 'F3:55:BD:A3:65:2E',
      name: 'Main Corridor',
      locationDescription: 'Central corridor connecting east and west wings',
      physicalPosition: Offset(20, 0),
      connectedBeacons: ['D3:5F:B3:48:14:CA', 'C7:A4:5A:D0:74:D8'],
      floor: 'Ground Floor',
      metadata: {'building': 'A', 'width': 'wide_corridor'},
    ),
    BeaconData(
      mac: 'C7:A4:5A:D0:74:D8',
      name: 'East Wing',
      locationDescription: 'East wing hallway near rooms 101-105',
      physicalPosition: Offset(40, 0),
      connectedBeacons: ['F3:55:BD:A3:65:2E'],
      floor: 'Ground Floor',
      metadata: {'building': 'A', 'rooms': '101-105'},
    ),
  ];

  // Two test destinations
  final List<Destination> destinations = [
    Destination(
      id: 'dest_1',
      name: 'Computer Lab',
      description: 'Room 103 - Computer Lab with 30 workstations',
      nearestBeaconMac: 'C7:A4:5A:D0:74:D8',
    ),
    Destination(
      id: 'dest_2',
      name: 'Information Desk',
      description: 'Main lobby information and help desk',
      nearestBeaconMac: 'D3:5F:B3:48:14:CA',
    ),
  ];

  String selectedCurrentBeacon = 'D3:5F:B3:48:14:CA';
  Destination? selectedDestination;
  bool isCalculating = false;
  Map<String, dynamic>? pathResult;

  Future<void> calculatePath() async {
    if (selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    setState(() {
      isCalculating = true;
      pathResult = null;
    });

    final result = await AIPathPlannerService.calculatePath(
      currentBeaconMac: selectedCurrentBeacon,
      destination: selectedDestination!,
      beaconNetwork: beaconNetwork,
    );

    setState(() {
      isCalculating = false;
      pathResult = result;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Path Planning Demo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Location Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCurrentBeacon,
                      items: beaconNetwork.map((beacon) {
                        return DropdownMenuItem(
                          value: beacon.mac,
                          child: Text(beacon.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCurrentBeacon = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Destination Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Destination',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ...destinations.map((dest) {
                      return RadioListTile<Destination>(
                        title: Text(dest.name),
                        subtitle: Text(dest.description),
                        value: dest,
                        groupValue: selectedDestination,
                        onChanged: (value) {
                          setState(() {
                            selectedDestination = value;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Calculate Button
            ElevatedButton(
              onPressed: isCalculating ? null : calculatePath,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: isCalculating
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Calculating Path...'),
                ],
              )
                  : Text(
                'Calculate Shortest Path',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '💡 Uses OpenAI when available, falls back to local Dijkstra algorithm',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Results Display
            if (pathResult != null) ...[
              Card(
                color: pathResult!['success'] ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pathResult!['success'] ? Icons.check_circle : Icons.error,
                            color: pathResult!['success'] ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            pathResult!['success'] ? 'Path Found!' : 'Error',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      if (pathResult!['success']) ...[
                        _buildResultRow('Total Distance', '${pathResult!['total_distance']}m'),
                        _buildResultRow('Estimated Time', '${pathResult!['total_time_seconds']}s'),
                        _buildResultRow('Floor Changes', '${pathResult!['floor_changes']}'),
                        SizedBox(height: 16),
                        Text(
                          'Path Summary:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(pathResult!['path_summary']),
                        if (pathResult!['warnings'] != null && (pathResult!['warnings'] as List).isNotEmpty) ...[
                          SizedBox(height: 8),
                          ...((pathResult!['warnings'] as List).map((w) => Text(
                            '⚠️ $w',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ))),
                        ],
                        SizedBox(height: 16),
                        Text(
                          'Navigation Steps:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        ...(pathResult!['path'] as List).asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(step['beacon_name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step['instruction']),
                                  if (step['distance_to_next'] != null && step['distance_to_next'] > 0)
                                    Text(
                                      'Next: ${step['distance_to_next']}m (${step['estimated_time_seconds']}s)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ] else ...[
                        Text(
                          'Error: ${pathResult!['error']}',
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text('Reason: ${pathResult!['reason']}'),
                        SizedBox(height: 8),
                        Text('Suggestion: ${pathResult!['suggestion']}'),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Raw JSON Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  JsonEncoder.withIndent('  ').convert(pathResult),
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'AI Beacon Navigation',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: PathPlanningDemo(),
    debugShowCheckedModeBanner: false,
  ));
}