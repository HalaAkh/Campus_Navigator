import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/beacon_service.dart';
import '../../services/navigation_service.dart';
import '../../utils/app_state.dart';
import '../../data/rooms.dart';

class ActiveNavigationScreen extends StatefulWidget {
  final String roomNumber;
  final VoidCallback onArrived;
  final VoidCallback onEnd;

  const ActiveNavigationScreen({
    super.key,
    required this.roomNumber,
    required this.onArrived,
    required this.onEnd,
  });

  @override
  State<ActiveNavigationScreen> createState() => _ActiveNavigationScreenState();
}

class _ActiveNavigationScreenState extends State<ActiveNavigationScreen> {
  bool _isLoading = true;
  String? _error;
  int _currentStep = 0;
  NavigationResult? _result;
  int _currentFloor = 4;
  BeaconModel? _currentBeacon;
  bool _noBeaconsDetected = false;

  late final List<Map<String, String>> _fallbackSteps;

  @override
  void initState() {
    super.initState();
    _initFallbackSteps();
    _loadNavigation();
    BeaconService().startContinuousScanning();
  }

  void _initFallbackSteps() {
    _fallbackSteps = [
      {'arrow': '↱', 'title': 'Turn right from the elevator', 'desc': 'Enter the main corridor heading toward Room 408', 'landmark': 'Room 401 will appear on your right'},
      {'arrow': '↰', 'title': 'Turn left at Room 408', 'desc': 'Enter the 409–415 office corridor', 'landmark': 'Room 409 will be on your right'},
      {'arrow': '➡', 'title': 'Walk to the end of the corridor', 'desc': 'Your destination is at the end', 'landmark': 'You are almost there!'},
      {'arrow': '🏁', 'title': 'You have arrived!', 'desc': 'Destination reached', 'landmark': '🎉 You made it!'},
    ];
  }

  @override
  void dispose() {
    BeaconService().stopContinuousScanning();
    super.dispose();
  }

  Future<void> _loadNavigation() async {
    final state = context.read<AppState>();
    final beaconSvc = BeaconService();

    setState(() => _isLoading = true);
    final detected = await beaconSvc.detectCurrentLocation(durationSeconds: 5);

    if (detected == null) {
      setState(() {
        _isLoading = false;
        _noBeaconsDetected = true;
        _currentFloor = 4;
      });
      return;
    }

    _currentBeacon = detected;
    final currentMac = detected.mac;
    final currentFloor = detected.floor;

    setState(() => _currentFloor = currentFloor);

    const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

    if (apiKey.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '⚠️ OpenAI API key not configured. Using fallback directions.';
      });
      return;
    }

    final result = await NavigationService().navigate(
      currentBeaconMac: currentMac,
      currentFloor: currentFloor,
      destinationNumber: widget.roomNumber,
      apiKey: apiKey,
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;

        // If OpenAI failed, show error
        if (!result.success) {
          _error = '❌ Navigation error: ${result.error}';
        } else {
          _error = null;
          state.startNavigation(result, getRoomByNumber(widget.roomNumber)!);
          state.incrementNavigationCount();
        }
      });
    }
  }

  String _directionToArrow(String dir) {
    switch (dir.toLowerCase()) {
      case 'left': return '↰';
      case 'right': return '↱';
      case 'up': return '⬆';
      case 'down': return '⬇';
      case 'straight':
      case 'forward': return '➡';
      default: return '➡';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_noBeaconsDetected) return _buildNoBeaconsScreen();
    return _buildNavigationScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF007A6E)),
            const SizedBox(height: 16),
            Text('Scanning for beacons...', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Looking for nearby MOKO beacons', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7B7A))),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBeaconsScreen() {
    final room = getRoomByNumber(widget.roomNumber);
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_outlined, size: 40, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 24),
            Text(
              'No beacons detected',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1C2B2A)),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007A6E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Please go to Floor ${room?.floor ?? _currentFloor} and get closer to the nearest beacon to start navigation.',
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1C2B2A)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    BeaconService().stopContinuousScanning();
                    widget.onEnd();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF007A6E), width: 2),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text('End', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF007A6E))),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLoading = true);
                    _loadNavigation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF007A6E), Color(0xFF00BCD4)]),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text('Retry', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationScreen() {
    final beaconSvc = context.watch<BeaconService>();
    final room = getRoomByNumber(widget.roomNumber);
    final displayRoom = room?.number ?? widget.roomNumber;

    final hasSteps = _result != null && _result!.success && _result!.path.isNotEmpty;
    final totalSteps = hasSteps ? _result!.path.length : _fallbackSteps.length;
    final progress = ((_currentStep + 1) / totalSteps).clamp(0.0, 1.0);
    final isLastStep = _currentStep >= totalSteps - 1;

    String arrow = '↱', title = '', desc = '', landmark = '';
    String debugInfo = '';

    if (hasSteps && _currentStep < _result!.path.length) {
      final step = _result!.path[_currentStep];
      arrow = _directionToArrow(step.direction);
      final parts = step.instruction.split('.');
      title = parts.first.trim();
      desc = parts.skip(1).join('.').trim();
      if (desc.isEmpty) desc = step.location;
      landmark = '📍 ${step.location}';
      debugInfo = '🔹 Beacon: ${step.beaconMac} | Floor: ${step.floor} | Dir: ${step.direction}';
    } else {
      final step = _fallbackSteps[_currentStep.clamp(0, _fallbackSteps.length - 1)];
      arrow = step['arrow']!;
      title = step['title']!;
      desc = step['desc']!;
      landmark = step['landmark']!;
      debugInfo = '⚠️ Using fallback directions (no OpenAI)';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Stack(
        children: [
          // ...existing code...
          CustomPaint(
            painter: FullScreenFloorPainter(
              floor: room?.floor ?? _currentFloor,
              destinationRoom: displayRoom,
              currentStep: _currentStep,
              totalSteps: totalSteps,
              currentBeaconMac: beaconSvc.currentBeacon?.mac ?? '',
              navigationPath: hasSteps ? _result!.path : [],
            ),
            child: const SizedBox.expand(),
          ),

          // Top bar
          Container(
            color: Colors.white.withOpacity(0.95),
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room $displayRoom · Floor ${room?.floor ?? _currentFloor}',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1C2B2A)),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: beaconSvc.currentBeacon != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              beaconSvc.currentBeacon != null
                                  ? '${beaconSvc.currentBeacon!.location} · ${beaconSvc.signalStrength} dBm'
                                  : 'Scanning...',
                              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF6B7B7A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    BeaconService().stopContinuousScanning();
                    widget.onEnd();
                  },
                  child: Text('✕ End', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Direction card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -4))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: const Color(0xFFE5EBEB), borderRadius: BorderRadius.circular(9999)),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE8EDED),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('STEP ${_currentStep + 1} OF $totalSteps',
                        style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF6B7B7A), letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 12),
                  Text(arrow, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(title,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1C2B2A)),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7B7A)),
                      textAlign: TextAlign.center,
                      maxLines: 2),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A6E).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(landmark,
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1C2B2A)),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(debugInfo,
                            style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF6B7B7A)),
                            textAlign: TextAlign.center),
                        if (_currentBeacon != null) ...[
                          const SizedBox(height: 4),
                          Text('📍 Current: ${_currentBeacon!.location}',
                              style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF007A6E), fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _error!.contains('❌')
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : const Color(0xFFF59E0B).withOpacity(0.1),
                          border: Border.all(
                            color: _error!.contains('❌')
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _error!.contains('❌')
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: _currentStep > 0 ? const Color(0xFF007A6E) : const Color(0xFFE5EBEB), width: 2),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Center(
                              child: Text('← Prev',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _currentStep > 0 ? const Color(0xFF007A6E) : const Color(0xFF6B7B7A))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (isLastStep) {
                              BeaconService().stopContinuousScanning();
                              widget.onArrived();
                            } else {
                              setState(() => _currentStep++);
                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF007A6E), Color(0xFF00BCD4)]),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Center(
                              child: Text(isLastStep ? 'Finish 🏁' : 'Next →',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      BeaconService().stopContinuousScanning();
                      widget.onEnd();
                    },
                    child: Text('End Navigation',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444).withOpacity(0.7))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Full screen floor painter with live navigation
class FullScreenFloorPainter extends CustomPainter {
  final int floor;
  final String destinationRoom;
  final int currentStep;
  final int totalSteps;
  final String currentBeaconMac;
  final List<NavigationStep> navigationPath;

  FullScreenFloorPainter({
    required this.floor,
    required this.destinationRoom,
    required this.currentStep,
    required this.totalSteps,
    required this.currentBeaconMac,
    required this.navigationPath,
  });

  static const Color _bg = Color(0xFFF7FAFA);
  static const Color _primary = Color(0xFF007A6E);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _visited = Color(0xFF00BCD4);
  static const Color _success = Color(0xFF10B981);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 290;

    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    if (floor == 4) {
      _drawFloor4(canvas, sx, sy);
    } else {
      _drawFloor5(canvas, sx, sy);
    }

    _drawRoute(canvas, sx, sy);
  }

  void _drawFloor4(Canvas canvas, double sx, double sy) {
    _drawCorridor(canvas, sx, sy, 5, 20, 80, 260);
    for (int i = 0; i < 7; i++) {
      _drawRoom(canvas, sx, sy, 8, 25 + i * 35, 74, 30, (424 + i).toString(), (424 + i).toString() == destinationRoom);
    }

    _drawRoom(canvas, sx, sy, 100, 20, 55, 45, '🛗', false, fill: const Color(0xFFE8F5E9), border: const Color(0xFF2E7D32));

    for (int i = 0; i < 4; i++) {
      _drawRoom(canvas, sx, sy, 95 + i * 22, 72, 20, 26, (420 + i).toString(), (420 + i).toString() == destinationRoom);
    }

    _drawCorridor(canvas, sx, sy, 95, 108, 295, 18);

    final topRooms = ['401', '402', '403', '404'];
    for (int i = 0; i < 4; i++) {
      _drawRoom(canvas, sx, sy, 170 + i * 48, 72, 43, 32, topRooms[i], topRooms[i] == destinationRoom);
    }

    final botRooms = ['419', '418', '417', '416'];
    for (int i = 0; i < 4; i++) {
      _drawRoom(canvas, sx, sy, 170 + i * 48, 130, 43, 32, botRooms[i], botRooms[i] == destinationRoom);
    }

    _drawRoom(canvas, sx, sy, 340, 88, 52, 52, '408', destinationRoom == '408',
        fill: const Color(0xFFE8F5E9), border: _primary);

    _drawCorridor(canvas, sx, sy, 354, 144, 18, 90);
    _drawRoom(canvas, sx, sy, 312, 150, 38, 28, '406', destinationRoom == '406');
    _drawRoom(canvas, sx, sy, 312, 182, 38, 28, '407', destinationRoom == '407');
    _drawRoom(canvas, sx, sy, 312, 216, 38, 22, '↑', false, fill: const Color(0xFFFFF3E0), border: _accent);

    _drawCorridor(canvas, sx, sy, 215, 168, 125, 14);
    final leftTop = ['409', '415', '414', '413'];
    for (int i = 0; i < 4; i++) {
      _drawRoom(canvas, sx, sy, 220 + i * 30, 148, 27, 18, leftTop[i], leftTop[i] == destinationRoom);
    }
    final leftBot = ['410', '411', '412'];
    for (int i = 0; i < 3; i++) {
      _drawRoom(canvas, sx, sy, 237 + i * 32, 185, 27, 20, leftBot[i], leftBot[i] == destinationRoom);
    }

    _drawBeacon(canvas, sx, sy, 127, 22, 'C6:2A', currentBeaconMac == 'C6:2A:90:A1:99:CB');
    _drawBeacon(canvas, sx, sy, 360, 115, 'E5:65', currentBeaconMac == 'E5:65:DD:D0:91:EC');
    _drawBeacon(canvas, sx, sy, 45, 22, 'C8:93', currentBeaconMac == 'C8:93:08:09:B2:CA');
  }

  void _drawFloor5(Canvas canvas, double sx, double sy) {
    _drawCorridor(canvas, sx, sy, 5, 20, 80, 140);
    for (int i = 0; i < 4; i++) {
      _drawRoom(canvas, sx, sy, 8, 25 + i * 32, 74, 28, (526 + i).toString(), (526 + i).toString() == destinationRoom);
    }

    _drawRoom(canvas, sx, sy, 100, 20, 55, 45, '🛗', false, fill: const Color(0xFFE8F5E9), border: const Color(0xFF2E7D32));

    for (int i = 0; i < 3; i++) {
      _drawRoom(canvas, sx, sy, 98 + i * 24, 72, 22, 26, (525 - i).toString(), (525 - i).toString() == destinationRoom);
    }

    _drawCorridor(canvas, sx, sy, 95, 108, 295, 18);

    final mainRooms = [
      ['522', 170.0, 72.0, 40.0, 32.0],
      ['501', 215.0, 72.0, 40.0, 32.0],
      ['502', 260.0, 72.0, 40.0, 32.0],
      ['503', 305.0, 72.0, 40.0, 32.0],
      ['520', 260.0, 130.0, 40.0, 32.0],
    ];
    for (final r in mainRooms) {
      _drawRoom(canvas, sx, sy, r[1] as double, r[2] as double, r[3] as double, r[4] as double, r[0] as String, r[0] == destinationRoom);
    }

    _drawRoom(canvas, sx, sy, 340, 88, 52, 52, '511', destinationRoom == '511',
        fill: const Color(0xFFE8F5E9), border: _primary);

    _drawCorridor(canvas, sx, sy, 215, 168, 125, 14);
    final rightRooms = ['512', '513', '514', '515', '516'];
    for (int i = 0; i < 5; i++) {
      _drawRoom(canvas, sx, sy, 220 + i * 25, 148, 22, 18, rightRooms[i], rightRooms[i] == destinationRoom);
    }

    _drawCorridor(canvas, sx, sy, 354, 144, 18, 90);
    final leftRooms = ['504', '505', '506', '507'];
    for (int i = 0; i < 4; i++) {
      _drawRoom(canvas, sx, sy, 312, 150 + i * 24, 38, 20, leftRooms[i], leftRooms[i] == destinationRoom);
    }

    _drawBeacon(canvas, sx, sy, 127, 22, 'FC:17', currentBeaconMac == 'FC:17:8A:61:EC:6D');
    _drawBeacon(canvas, sx, sy, 45, 80, 'F3:55', currentBeaconMac == 'F3:55:BD:A3:65:2E');
    _drawBeacon(canvas, sx, sy, 360, 115, 'C7:A4', currentBeaconMac == 'C7:A4:5A:D0:74:D8');
  }

  void _drawRoom(Canvas canvas, double sx, double sy, double x, double y, double w, double h,
      String label, bool isDestination, {Color fill = const Color(0xFFFFFFFF), Color border = _primary}) {
    final rect = Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(rrect, Paint()..color = isDestination ? _accent.withOpacity(0.25) : fill);
    canvas.drawRRect(rrect,
        Paint()
          ..color = isDestination ? _accent : border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isDestination ? 2 : 1);

    if (label != '↑') {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 7.5 * sx.clamp(0.8, 1.3),
            color: isDestination ? _accent : const Color(0xFF1C2B2A),
            fontWeight: isDestination ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: w * sx);
      tp.paint(canvas, Offset(x * sx + (w * sx - tp.width) / 2, y * sy + (h * sy - tp.height) / 2));
    }
  }

  void _drawCorridor(Canvas canvas, double sx, double sy, double x, double y, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE0F2F1).withOpacity(0.7),
    );
  }

  void _drawBeacon(Canvas canvas, double sx, double sy, double x, double y, String label, bool isActive) {
    final center = Offset(x * sx, y * sy);
    if (isActive) {
      canvas.drawCircle(center, 12 * sx, Paint()..color = _accent.withOpacity(0.25));
      canvas.drawCircle(center, 5 * sx, Paint()..color = _accent);
    } else {
      canvas.drawCircle(center, 3 * sx, Paint()..color = _primary.withOpacity(0.5));
    }

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 5 * sx.clamp(0.8, 1.2),
          color: isActive ? _accent : _primary.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x * sx - tp.width / 2, (y + 8) * sy));
  }

  void _drawRoute(Canvas canvas, double sx, double sy) {
    if (navigationPath.isEmpty) return;

    final Map<String, Offset> positions = floor == 4
        ? {
      'C6:2A:90:A1:99:CB': Offset(127 * sx, 45 * sy),
      'E5:65:DD:D0:91:EC': Offset(366 * sx, 115 * sy),
      'C8:93:08:09:B2:CA': Offset(45 * sx, 45 * sy),
    }
        : {
      'FC:17:8A:61:EC:6D': Offset(127 * sx, 45 * sy),
      'F3:55:BD:A3:65:2E': Offset(45 * sx, 80 * sy),
      'C7:A4:5A:D0:74:D8': Offset(366 * sx, 115 * sy),
    };

    final List<Offset> routePoints = [];
    for (final step in navigationPath) {
      final pos = positions[step.beaconMac];
      if (pos != null) routePoints.add(pos);
    }

    if (routePoints.length < 2) return;

    final visitedPaint = Paint()
      ..color = _visited
      ..strokeWidth = 4 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final remainingPaint = Paint()
      ..color = _primary.withOpacity(0.3)
      ..strokeWidth = 3 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < routePoints.length - 1; i++) {
      if (i < currentStep) {
        canvas.drawLine(routePoints[i], routePoints[i + 1], visitedPaint);
      } else {
        _drawDashedLine(canvas, routePoints[i], routePoints[i + 1], remainingPaint, 5 * sx);
      }
    }

    // Waypoint dots
    for (int i = 0; i < routePoints.length; i++) {
      if (i < currentStep) {
        canvas.drawCircle(routePoints[i], 7 * sx, Paint()..color = _success);
      } else if (i == currentStep) {
        canvas.drawCircle(routePoints[i], 7 * sx, Paint()..color = _accent);
      } else {
        canvas.drawCircle(routePoints[i], 6 * sx, Paint()
          ..color = _primary.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * sx);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashLen) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (Offset(dx, dy)).distance;
    if (dist == 0) return;
    final steps = (dist / (dashLen * 2)).ceil();
    for (int i = 0; i < steps; i++) {
      final t1 = (i * dashLen * 2) / dist;
      final t2 = ((i * dashLen * 2) + dashLen) / dist;
      canvas.drawLine(
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        Offset(start.dx + dx * t2.clamp(0.0, 1.0), start.dy + dy * t2.clamp(0.0, 1.0)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FullScreenFloorPainter old) =>
      old.currentStep != currentStep || old.currentBeaconMac != currentBeaconMac || old.floor != floor;
}