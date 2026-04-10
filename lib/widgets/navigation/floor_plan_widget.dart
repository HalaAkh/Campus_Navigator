import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class FloorPlanWidget extends StatefulWidget {
  final int floor;
  final int step;
  final String destinationRoom;

  const FloorPlanWidget({
    super.key,
    required this.floor,
    required this.step,
    required this.destinationRoom,
  });

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 6, end: 14).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return CustomPaint(
          painter: widget.floor == 4
              ? Floor4Painter(
                  step: widget.step,
                  destinationRoom: widget.destinationRoom,
                  pulseRadius: _pulseAnimation.value,
                )
              : Floor5Painter(
                  step: widget.step,
                  destinationRoom: widget.destinationRoom,
                  pulseRadius: _pulseAnimation.value,
                ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ============================================
// FLOOR 4 PAINTER
// ============================================
class Floor4Painter extends CustomPainter {
  final int step;
  final String destinationRoom;
  final double pulseRadius;

  Floor4Painter({
    required this.step,
    required this.destinationRoom,
    required this.pulseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 380;
    final double scaleY = size.height / 280;

    // Background
    final bgPaint = Paint()..color = const Color(0xFFF7FAFA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bgPaint,
    );

    // Left wing rooms 424-430
    _drawRoomBlock(canvas, scaleX, scaleY, 10, 30, 80, 220, const Color(0xFFE0F2F1), '424-430');

    for (int i = 0; i < 7; i++) {
      final room = (424 + i).toString();
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 15, 35 + i * 30, 70, 26,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary,
          room);
    }

    // Elevator junction
    _drawRoom(canvas, scaleX, scaleY, 110, 30, 50, 40,
        const Color(0xFFE8F5E9), AppColors.forest, '🛗 Elev');

    // Rooms 420-423
    final nearElevatorRooms = ['420', '421', '422', '423'];
    for (int i = 0; i < 4; i++) {
      final room = nearElevatorRooms[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 100 + i * 18, 78, 16, 22,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Main corridor
    _drawCorridor(canvas, scaleX, scaleY, 100, 110, 270, 16);

    // Rooms along corridor top
    final topRooms = ['401', '402', '403', '404'];
    for (int i = 0; i < 4; i++) {
      final room = topRooms[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 175 + i * 45, 78, 40, 28,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Rooms along corridor bottom
    final bottomRooms = ['419', '418', '417', '416'];
    for (int i = 0; i < 4; i++) {
      final room = bottomRooms[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 175 + i * 45, 130, 40, 28,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Room 408 junction
    _drawRoom(canvas, scaleX, scaleY, 330, 95, 42, 46,
        const Color(0xFFE8F5E9), AppColors.primary, '408\nJct');

    // Split corridors from 408
    _drawCorridor(canvas, scaleX, scaleY, 345, 145, 16, 80);
    _drawCorridor(canvas, scaleX, scaleY, 220, 165, 120, 12);

    // Right split rooms (406, 407)
    for (int i = 0; i < 2; i++) {
      final room = i == 0 ? '406' : '407';
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 310, 150 + i * 28, 30, 22,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Left split rooms (409-415)
    final leftSplitTop = ['409', '415', '414', '413'];
    for (int i = 0; i < 4; i++) {
      final room = leftSplitTop[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 225 + i * 28, 145, 25, 18,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    final leftSplitBottom = ['410', '411', '412'];
    for (int i = 0; i < 3; i++) {
      final room = leftSplitBottom[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, scaleX, scaleY, 240 + i * 30, 180, 25, 18,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Beacons
    _drawBeacon(canvas, scaleX, scaleY, 135, 22, 'C6:2A', pulseRadius);
    _drawBeacon(canvas, scaleX, scaleY, 351, 85, 'E5:65', pulseRadius);
    _drawBeacon(canvas, scaleX, scaleY, 50, 20, 'C8:93', pulseRadius);

    // Route path
    _drawRoutePath(canvas, scaleX, scaleY, step);

    // User dot
    _drawUserDot(canvas, scaleX, scaleY, step, pulseRadius);
  }

  void _drawRoomBlock(Canvas canvas, double sx, double sy,
      double x, double y, double w, double h, Color fill, String label) {
    final paint = Paint()..color = fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawRoom(Canvas canvas, double sx, double sy,
      double x, double y, double w, double h,
      Color fill, Color stroke, String label) {
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final rect = Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 7 * sx.clamp(0.8, 1.2),
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: w * sx);
    textPainter.paint(
      canvas,
      Offset(
        x * sx + (w * sx - textPainter.width) / 2,
        y * sy + (h * sy - textPainter.height) / 2,
      ),
    );
  }

  void _drawCorridor(Canvas canvas, double sx, double sy,
      double x, double y, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE0F2F1).withOpacity(0.5),
    );
  }

  void _drawBeacon(Canvas canvas, double sx, double sy,
      double x, double y, String label, double pulseR) {
    // Pulse ring
    canvas.drawCircle(
      Offset(x * sx, y * sy),
      pulseR * sx,
      Paint()..color = AppColors.primary.withOpacity(0.2),
    );
    // Core
    canvas.drawCircle(
      Offset(x * sx, y * sy),
      3 * sx,
      Paint()..color = AppColors.primary,
    );
    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 5 * sx.clamp(0.8, 1.2), color: AppColors.primary),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x * sx - tp.width / 2, (y - 8) * sy));
  }

  void _drawRoutePath(Canvas canvas, double sx, double sy, int step) {
    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 2 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(135 * sx, 50 * sy);
    path.lineTo(135 * sx, 118 * sy);
    path.lineTo(351 * sx, 118 * sy);
    path.lineTo(351 * sx, 145 * sy);
    path.lineTo(340 * sx, 165 * sy);
    path.lineTo(270 * sx, 172 * sy);
    path.lineTo(300 * sx, 190 * sy);

    canvas.drawPath(path, routePaint);
  }

  void _drawUserDot(Canvas canvas, double sx, double sy, int step, double pulseR) {
    final positions = [
      Offset(135 * sx, 50 * sy),
      Offset(351 * sx, 118 * sy),
      Offset(270 * sx, 172 * sy),
      Offset(300 * sx, 190 * sy),
    ];
    final pos = step < positions.length ? positions[step] : positions.last;
    final isArrived = step >= positions.length - 1;

    // Pulse ring
    canvas.drawCircle(pos, pulseR * sx * 0.8,
        Paint()..color = AppColors.accent.withOpacity(0.2));
    // White ring
    canvas.drawCircle(pos, 7 * sx, Paint()..color = Colors.white);
    // Core
    canvas.drawCircle(
      pos,
      5 * sx,
      Paint()..color = isArrived ? AppColors.success : AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(Floor4Painter oldDelegate) =>
      oldDelegate.step != step ||
      oldDelegate.destinationRoom != destinationRoom ||
      oldDelegate.pulseRadius != pulseRadius;
}

// ============================================
// FLOOR 5 PAINTER (simplified)
// ============================================
class Floor5Painter extends CustomPainter {
  final int step;
  final String destinationRoom;
  final double pulseRadius;

  Floor5Painter({
    required this.step,
    required this.destinationRoom,
    required this.pulseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / 380;
    final double sy = size.height / 280;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      Paint()..color = const Color(0xFFF7FAFA),
    );

    // Left corridor rooms 526-529
    for (int i = 0; i < 4; i++) {
      final room = (526 + i).toString();
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, sx, sy, 10, 40 + i * 30, 70, 25,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Elevator junction
    _drawRoom(canvas, sx, sy, 110, 30, 50, 40,
        const Color(0xFFE8F5E9), AppColors.forest, '🛗 F5');

    // Rooms 523-525
    for (int i = 0; i < 3; i++) {
      final room = (523 + i).toString();
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, sx, sy, 100 + i * 20, 78, 18, 22,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Main corridor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(100 * sx, 110 * sy, 270 * sx, 16 * sy),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE0F2F1).withOpacity(0.5),
    );

    // Rooms along corridor
    final corridorRooms = ['501', '502', '503', '520'];
    for (int i = 0; i < 4; i++) {
      final room = corridorRooms[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, sx, sy, 175 + i * 45, 78, 40, 28,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Room 511 junction
    _drawRoom(canvas, sx, sy, 330, 95, 42, 46,
        const Color(0xFFE8F5E9), AppColors.primary, '511\nJct');

    // Post-511 rooms
    final post511 = ['512', '516', '507', '504'];
    for (int i = 0; i < 4; i++) {
      final room = post511[i];
      final isDestination = room == destinationRoom;
      _drawRoom(canvas, sx, sy, 225 + i * 28, 150, 25, 18,
          isDestination ? AppColors.accent.withOpacity(0.3) : Colors.white,
          isDestination ? AppColors.accent : AppColors.primary, room);
    }

    // Beacons
    _drawBeacon(canvas, sx, sy, 135, 22, 'FC:17', pulseRadius);
    _drawBeacon(canvas, sx, sy, 50, 20, 'F3:55', pulseRadius);
    _drawBeacon(canvas, sx, sy, 351, 85, 'C7:A4', pulseRadius);

    // Route
    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 2 * sx
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(135 * sx, 50 * sy);
    path.lineTo(351 * sx, 50 * sy);
    path.lineTo(351 * sx, 118 * sy);
    canvas.drawPath(path, routePaint);

    // User dot
    _drawUserDot(canvas, sx, sy, step, pulseRadius);
  }

  void _drawRoom(Canvas canvas, double sx, double sy, double x, double y,
      double w, double h, Color fill, Color stroke, String label) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), const Radius.circular(3)),
      Paint()..color = fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), const Radius.circular(3)),
      Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontSize: 7 * sx.clamp(0.8, 1.2), color: AppColors.foreground)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: w * sx);
    tp.paint(canvas, Offset(x * sx + (w * sx - tp.width) / 2, y * sy + (h * sy - tp.height) / 2));
  }

  void _drawBeacon(Canvas canvas, double sx, double sy, double x, double y, String label, double pulseR) {
    canvas.drawCircle(Offset(x * sx, y * sy), pulseR * sx, Paint()..color = AppColors.primary.withOpacity(0.2));
    canvas.drawCircle(Offset(x * sx, y * sy), 3 * sx, Paint()..color = AppColors.primary);
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontSize: 5 * sx.clamp(0.8, 1.2), color: AppColors.primary)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x * sx - tp.width / 2, (y - 8) * sy));
  }

  void _drawUserDot(Canvas canvas, double sx, double sy, int step, double pulseR) {
    final pos = step == 0 ? Offset(135 * sx, 50 * sy) : Offset(351 * sx, 118 * sy);
    canvas.drawCircle(pos, pulseR * sx * 0.8, Paint()..color = AppColors.accent.withOpacity(0.2));
    canvas.drawCircle(pos, 7 * sx, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 5 * sx, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(Floor5Painter old) =>
      old.step != step || old.destinationRoom != destinationRoom || old.pulseRadius != pulseRadius;
}
