import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/beacon_service.dart';
import '../../services/navigation_service.dart';
import '../../utils/app_state.dart';
import '../../data/rooms.dart';

const _teal = Color(0xFF1ABC9C);
const _tealDk = Color(0xFF16A085);
const _pinRed = Color(0xFFE74C3C);
const _pinGrn = Color(0xFF1ABC9C);
const _routeBlue = Color(0xFF4A90D9);
const _textDk = Color(0xFF2C3E50);
const _textMd = Color(0xFF6B7B7A);
const _textLt = Color(0xFFBDC3C7);

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

class _ActiveNavigationScreenState extends State<ActiveNavigationScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  int _currentStep = 0;
  NavigationResult? _result;

  late AnimationController _pulseCtrl, _routeCtrl, _stepCtrl;
  late Animation<double> _pulseAnim, _routeAnim, _stepFade, _stepSlide;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.5).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _routeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _routeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _routeCtrl, curve: Curves.easeInOut));
    _stepCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _stepFade = Tween<double>(begin: 0, end: 1).animate(_stepCtrl);
    _stepSlide = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut));
    _loadNavigation();
    BeaconService().startContinuousScanning();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _routeCtrl.dispose(); _stepCtrl.dispose(); BeaconService().stopContinuousScanning(); super.dispose(); }

  Future<void> _loadNavigation() async {
    final beaconSvc = BeaconService();
    BeaconModel? beacon = beaconSvc.currentBeacon ?? await beaconSvc.detectCurrentLocation(durationSeconds: 5);
    const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) { setState(() { _isLoading = false; _error = 'Demo mode'; }); _routeCtrl.forward(); _stepCtrl.forward(); return; }
    final result = await NavigationService().navigate(currentBeaconMac: beacon?.mac ?? 'C6:2A:90:A1:99:CB', currentFloor: beacon?.floor ?? 4, destinationNumber: widget.roomNumber, apiKey: apiKey);
    if (mounted) { setState(() { _result = result; _isLoading = false; }); _routeCtrl.forward(); _stepCtrl.forward(); }
  }

  void _nextStep() { final total = _result?.path.length ?? 4; if (_currentStep >= total - 1) { widget.onArrived(); return; } _stepCtrl.reset(); setState(() => _currentStep++); _stepCtrl.forward(); }
  void _prevStep() { if (_currentStep <= 0) return; _stepCtrl.reset(); setState(() => _currentStep--); _stepCtrl.forward(); }

  IconData _dirIcon(String d) { switch (d.toLowerCase()) { case 'left': return Icons.turn_left_rounded; case 'right': return Icons.turn_right_rounded; case 'up': return Icons.north_rounded; case 'down': return Icons.south_rounded; default: return Icons.straight_rounded; } }
  String _dirLabel(String d) { switch (d.toLowerCase()) { case 'left': return 'Turn Left'; case 'right': return 'Turn Right'; case 'up': return 'Go Upstairs'; case 'down': return 'Go Downstairs'; default: return 'Go Straight'; } }

  @override
  Widget build(BuildContext context) {
    final beaconSvc = context.watch<BeaconService>();
    final room = getRoomByNumber(widget.roomNumber);
    final size = MediaQuery.of(context).size;

    final hasSteps = _result != null && _result!.success && _result!.path.isNotEmpty;
    final totalSteps = hasSteps ? _result!.path.length : 4;
    final progress = (_currentStep + 1) / totalSteps;
    final isLast = _currentStep >= totalSteps - 1;

    NavigationStep? step;
    if (hasSteps && _currentStep < _result!.path.length) step = _result!.path[_currentStep];
    final instruction = step?.instruction ?? ['Turn RIGHT from elevator into main corridor', 'Walk straight through main corridor', 'Room ${widget.roomNumber} is ahead on your RIGHT', 'You have arrived!'][_currentStep.clamp(0, 3)];
    final direction = step?.direction ?? 'forward';
    final location = step?.location ?? 'Nicol Hall Floor ${room?.floor ?? 4}';
    final distMeters = _result?.totalDistanceMeters ?? 30;
    final estMin = _result?.estimatedTimeMinutes ?? 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // ── MAP (top 52%) ───────────────────────────────
        SizedBox(
          height: size.height * 0.52,
          child: Stack(children: [
            Positioned.fill(child: Image.asset('assets/images/campus_map.png', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDF2F7)))),
            Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.08))),

            // Route
            Positioned.fill(child: AnimatedBuilder(animation: _routeAnim,
                builder: (_, __) => CustomPaint(painter: _NavRoutePainter(progress: _routeAnim.value, currentStep: _currentStep, totalSteps: totalSteps)))),

            // Origin dot
            Positioned(left: size.width * 0.32 - 12, top: size.height * 0.52 * 0.40,
                child: AnimatedBuilder(animation: _pulseAnim,
                    builder: (_, __) => Stack(alignment: Alignment.center, children: [
                      Transform.scale(scale: _pulseAnim.value, child: Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: _pinGrn.withValues(alpha: 0.15)))),
                      Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _pinGrn, width: 2.5), boxShadow: [BoxShadow(color: _pinGrn.withValues(alpha: 0.3), blurRadius: 8)])),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _pinGrn)),
                    ]))),

            // Destination pin
            Positioned(left: size.width * 0.68 - 14, top: size.height * 0.52 * 0.55 - 34,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 30, height: 30,
                      decoration: BoxDecoration(color: _pinRed, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _pinRed.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Center(child: Text(widget.roomNumber, style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)))),
                  Container(width: 2, height: 8, color: _pinRed),
                  Container(width: 6, height: 3, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9999))),
                ])),

            // ── Top bar: close + destination + info chips ──
            Positioned(top: 0, left: 0, right: 0,
                child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(children: [
                    Row(children: [
                      _CircleBtn(icon: Icons.close_rounded, onTap: widget.onEnd),
                      const SizedBox(width: 10),
                      Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)]),
                        child: Row(children: [
                          const Icon(Icons.location_on_rounded, color: _pinRed, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Room ${widget.roomNumber}${room != null ? ' · ${room.name}' : ''}',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textDk), overflow: TextOverflow.ellipsis)),
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: beaconSvc.currentBeacon != null ? _teal : const Color(0xFFF59E0B))),
                        ]),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    // Distance + time chips
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      _InfoChip(icon: Icons.straighten_rounded, label: '${distMeters}m'),
                      const SizedBox(width: 6),
                      _InfoChip(icon: Icons.access_time_rounded, label: '${estMin} min'),
                      const SizedBox(width: 6),
                      _InfoChip(icon: Icons.stairs_rounded, label: 'F${room?.floor ?? 4}'),
                    ]),
                  ]),
                ))),

            // Progress bar
            Positioned(bottom: 0, left: 0, right: 0,
                child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.3), valueColor: const AlwaysStoppedAnimation(_teal), minHeight: 3)),
          ]),
        ),

        // ── STEP CARD (bottom 48%) ──────────────────────
        Expanded(child: Container(color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _teal))
              : AnimatedBuilder(animation: _stepCtrl,
            builder: (_, __) => Opacity(opacity: _stepFade.value,
              child: Transform.translate(offset: Offset(0, _stepSlide.value),
                child: Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Step counter
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _routeBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9999)),
                        child: Text('Step ${_currentStep + 1}/$totalSteps', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _routeBlue)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bluetooth_rounded, size: 10, color: _tealDk),
                          const SizedBox(width: 3),
                          Text(location, style: GoogleFonts.poppins(fontSize: 9, color: _tealDk, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Direction card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLast ? _teal.withValues(alpha: 0.06) : const Color(0xFFF7FAFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isLast ? _teal.withValues(alpha: 0.2) : const Color(0xFFE8EDEC)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 52, height: 52,
                            decoration: BoxDecoration(color: isLast ? _teal : _routeBlue, borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: (isLast ? _teal : _routeBlue).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]),
                            child: Icon(isLast ? Icons.check_rounded : _dirIcon(direction), color: Colors.white, size: 26)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isLast ? 'You have arrived!' : _dirLabel(direction),
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isLast ? _teal : _textDk)),
                          const SizedBox(height: 4),
                          Text(instruction, style: GoogleFonts.poppins(fontSize: 12, color: _textMd, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Step timeline dots
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalSteps, (i) {
                        final done = i <= _currentStep;
                        return Container(
                          width: i == _currentStep ? 20 : 8, height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                              color: done ? _teal : const Color(0xFFE0E7E7),
                              borderRadius: BorderRadius.circular(9999)),
                        );
                      }),
                    ),

                    const Spacer(),

                    // Prev / Next buttons
                    Row(children: [
                      if (_currentStep > 0)
                        GestureDetector(onTap: _prevStep,
                            child: Container(width: 52, height: 52,
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EDEC), width: 1.5), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textLt))),
                      if (_currentStep > 0) const SizedBox(width: 10),
                      Expanded(child: GestureDetector(onTap: _nextStep,
                          child: Container(height: 52,
                              decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))]),
                              child: Center(child: Text(isLast ? 'Confirm Arrival ✓' : 'Confirm',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)))))),
                    ]),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ),
          ),
        )),
      ]),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8)]),
          child: Icon(icon, size: 18, color: _textDk)));
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9999),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: _teal), const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _textDk)),
      ]));
}

class _NavRoutePainter extends CustomPainter {
  final double progress; final int currentStep; final int totalSteps;
  const _NavRoutePainter({required this.progress, required this.currentStep, required this.totalSteps});

  @override
  void paint(Canvas canvas, Size size) {
    final donePaint = Paint()..color = _teal..strokeWidth = 4.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    final remainPaint = Paint()..color = _routeBlue.withValues(alpha: 0.4)..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final shadowPaint = Paint()..color = _routeBlue.withValues(alpha: 0.1)..strokeWidth = 12..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final sx = size.width * 0.32; final sy = size.height * 0.42;
    final ex = size.width * 0.68; final ey = size.height * 0.57;

    final fullPath = Path()..moveTo(sx, sy)..cubicTo(sx, sy + (ey - sy) * 0.6, ex - 40, ey, ex, ey);
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.first.length;

    // Shadow
    canvas.drawPath(metrics.first.extractPath(0, total * progress), shadowPaint);

    // Done portion
    final doneLen = (currentStep / totalSteps.clamp(1, 999)) * total * progress;
    canvas.drawPath(metrics.first.extractPath(0, doneLen), donePaint);

    // Remaining dashed
    final remainPath = metrics.first.extractPath(doneLen, total);
    for (final m in remainPath.computeMetrics()) { double d = 0; while (d < m.length) { final end = (d + 8).clamp(0.0, m.length); canvas.drawPath(m.extractPath(d, end), remainPaint); d += 14; } }

    // Route dots on done portion
    for (double t = 0; t < doneLen / total; t += 0.12) {
      final pos = metrics.first.getTangentForOffset(total * t);
      if (pos != null) { canvas.drawCircle(pos.position, 3, Paint()..color = Colors.white); canvas.drawCircle(pos.position, 2, Paint()..color = _teal); }
    }
  }

  @override
  bool shouldRepaint(_NavRoutePainter old) => old.progress != progress || old.currentStep != currentStep;
}