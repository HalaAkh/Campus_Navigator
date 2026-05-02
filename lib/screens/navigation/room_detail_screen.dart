// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../utils/app_state.dart';
// import '../../data/rooms.dart';
// import '/services/rooms_service.dart';
//
// const _teal = Color(0xFF1ABC9C);
// const _tealDk = Color(0xFF16A085);
// const _pinRed = Color(0xFFE74C3C);
// const _routeBlue = Color(0xFF4A90D9);
// const _textDk = Color(0xFF2C3E50);
// const _textMd = Color(0xFF6B7B7A);
// const _textLt = Color(0xFFBDC3C7);
//
// class RoomDetailScreen extends StatefulWidget {
//   final String roomNumber;
//   final VoidCallback onNavigate;
//   final VoidCallback onBack;
//   const RoomDetailScreen({super.key, required this.roomNumber, required this.onNavigate, required this.onBack});
//   @override
//   State<RoomDetailScreen> createState() => _RoomDetailScreenState();
// }
//
// class _RoomDetailScreenState extends State<RoomDetailScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _routeCtrl;
//   late Animation<double> _routeAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _routeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
//     _routeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _routeCtrl, curve: Curves.easeInOut));
//     _routeCtrl.forward();
//   }
//
//   @override
//   void dispose() { _routeCtrl.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) {
//     final room = RoomsService().getRoomByNumber(widget.roomNumber);
//     final state = context.watch<AppState>();
//     final size = MediaQuery.of(context).size;
//     final isSaved = state.isRoomSaved(widget.roomNumber);
//     final floorNum = room?.floor ?? (widget.roomNumber.startsWith('5') ? 5 : 4);
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(children: [
//         // ── MAP (top 52%) ───────────────────────────────
//         SizedBox(height: size.height * 0.52,
//             child: Stack(children: [
//               Positioned.fill(child: Image.asset('assets/images/map.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDF2F7)))),
//               Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.08))),
//
//               // Route line
//               Positioned.fill(child: AnimatedBuilder(animation: _routeAnim,
//                   builder: (_, __) => CustomPaint(painter: _PreviewRoutePainter(progress: _routeAnim.value)))),
//
//               // Origin dot
//               Positioned(left: size.width * 0.32 - 10, top: size.height * 0.52 * 0.40,
//                   child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _teal, width: 2.5), boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.3), blurRadius: 8)]),
//                       child: Center(child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: _teal))))),
//
//               // Destination pin with room number
//               Positioned(left: size.width * 0.68 - 16, top: size.height * 0.52 * 0.55 - 36,
//                   child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.bounceOut,
//                       builder: (_, v, __) => Transform.scale(scale: v, alignment: Alignment.bottomCenter,
//                           child: Column(mainAxisSize: MainAxisSize.min, children: [
//                             Container(width: 32, height: 32,
//                                 decoration: BoxDecoration(color: _pinRed, shape: BoxShape.circle,
//                                     boxShadow: [BoxShadow(color: _pinRed.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4))]),
//                                 child: Center(child: Text(widget.roomNumber, style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)))),
//                             Container(width: 2, height: 10, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_pinRed, _pinRed.withValues(alpha: 0.2)]))),
//                             Container(width: 8, height: 3, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9999))),
//                           ])))),
//
//               // Top bar
//               Positioned(top: 0, left: 0, right: 0,
//                   child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
//                       child: Row(children: [
//                         _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: widget.onBack),
//                         const SizedBox(width: 10),
//                         Expanded(child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
//                                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)]),
//                             child: Row(children: [
//                               const Icon(Icons.my_location_rounded, color: _teal, size: 14), const SizedBox(width: 6),
//                               Expanded(child: Text(state.currentLocationLabel.isNotEmpty ? state.currentLocationLabel : 'My current location',
//                                   style: GoogleFonts.poppins(fontSize: 11, color: _textDk, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
//                             ]))),
//                         const SizedBox(width: 8),
//                         _CircleBtn(icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, onTap: () {
//                           if (room != null) { isSaved ? state.removeRoom(widget.roomNumber) : state.saveRoom(room); }
//                         }, color: isSaved ? _teal : null),
//                       ])))),
//
//               // Bottom chips
//               Positioned(bottom: 14, left: 0, right: 0,
//                   child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                     _Chip(icon: Icons.straighten_rounded, label: '~30m'),
//                     const SizedBox(width: 8),
//                     _Chip(icon: Icons.access_time_rounded, label: '~2 min'),
//                     const SizedBox(width: 8),
//                     _Chip(icon: Icons.stairs_rounded, label: 'Floor $floorNum'),
//                   ])),
//             ])),
//
//         // ── ROOM INFO (bottom 48%) ──────────────────────
//         Expanded(child: Container(color: Colors.white,
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               // Room header
//               Row(children: [
//                 Container(width: 50, height: 50,
//                     decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
//                     child: Center(child: Text(widget.roomNumber, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _teal)))),
//                 const SizedBox(width: 14),
//                 Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   Text(room?.name ?? 'Room ${widget.roomNumber}', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: _textDk)),
//                   const SizedBox(height: 2),
//                   Text('Floor $floorNum · Nicol Hall · ${room?.category ?? 'Office'}', style: GoogleFonts.poppins(fontSize: 11, color: _textMd)),
//                 ])),
//               ]),
//
//               const SizedBox(height: 18),
//               Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
//               const SizedBox(height: 14),
//
//               // Route info rows
//               _DetailRow(icon: Icons.straighten_rounded, label: 'Distance', value: '~30 meters'),
//               const SizedBox(height: 10),
//               _DetailRow(icon: Icons.access_time_rounded, label: 'Walking time', value: '~2 minutes'),
//               const SizedBox(height: 10),
//               _DetailRow(icon: Icons.bluetooth_rounded, label: 'Navigation', value: 'BLE Beacon Guided'),
//
//               const SizedBox(height: 18),
//
//               // Navigation option card
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                     color: _teal.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: _teal.withValues(alpha: 0.15))),
//                 child: Row(children: [
//                   Container(width: 42, height: 42,
//                       decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
//                       child: const Icon(Icons.navigation_rounded, color: _teal, size: 22)),
//                   const SizedBox(width: 12),
//                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                     Text('Indoor Navigation', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _textDk)),
//                     Text('Turn-by-turn beacon guidance', style: GoogleFonts.poppins(fontSize: 11, color: _textMd)),
//                   ])),
//                   Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                       decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(9999)),
//                       child: Text('Free', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
//                 ]),
//               ),
//
//               const Spacer(),
//
//               // Navigate button
//               GestureDetector(onTap: widget.onNavigate,
//                   child: Container(width: double.infinity, height: 52,
//                       decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(14),
//                           boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))]),
//                       child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                         const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
//                         const SizedBox(width: 8),
//                         Text('Start', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
//                       ]))),
//               const SizedBox(height: 16),
//             ]))),
//       ]),
//     );
//   }
// }
//
// class _DetailRow extends StatelessWidget {
//   final IconData icon; final String label; final String value;
//   const _DetailRow({required this.icon, required this.label, required this.value});
//   @override
//   Widget build(BuildContext context) => Row(children: [
//     Icon(icon, size: 16, color: _teal),
//     const SizedBox(width: 10),
//     Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _textMd)),
//     const Spacer(),
//     Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _textDk)),
//   ]);
// }
//
// class _CircleBtn extends StatelessWidget {
//   final IconData icon; final VoidCallback onTap; final Color? color;
//   const _CircleBtn({required this.icon, required this.onTap, this.color});
//   @override
//   Widget build(BuildContext context) => GestureDetector(onTap: onTap,
//       child: Container(width: 40, height: 40,
//           decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
//               boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 8)]),
//           child: Icon(icon, size: 18, color: color ?? _textDk)));
// }
//
// class _Chip extends StatelessWidget {
//   final IconData icon; final String label;
//   const _Chip({required this.icon, required this.label});
//   @override
//   Widget build(BuildContext context) => Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9999),
//           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 13, color: _teal), const SizedBox(width: 4),
//         Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _textDk)),
//       ]));
// }
//
// class _PreviewRoutePainter extends CustomPainter {
//   final double progress;
//   const _PreviewRoutePainter({required this.progress});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final shadowPaint = Paint()..color = _routeBlue.withValues(alpha: 0.12)..strokeWidth = 10..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
//     final paint = Paint()..color = _routeBlue..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
//
//     final sx = size.width * 0.32; final sy = size.height * 0.42;
//     final ex = size.width * 0.68; final ey = size.height * 0.57;
//
//     final path = Path()..moveTo(sx, sy)..cubicTo(sx, sy + (ey - sy) * 0.6, ex - 40, ey, ex, ey);
//     final metrics = path.computeMetrics().toList();
//     if (metrics.isEmpty) return;
//     final extracted = metrics.first.extractPath(0, metrics.first.length * progress);
//
//     canvas.drawPath(extracted, shadowPaint);
//     canvas.drawPath(extracted, paint);
//
//     // Route dots
//     for (double t = 0.15; t < progress; t += 0.18) {
//       final pos = metrics.first.getTangentForOffset(metrics.first.length * t);
//       if (pos != null) { canvas.drawCircle(pos.position, 3, Paint()..color = Colors.white); canvas.drawCircle(pos.position, 1.8, Paint()..color = _routeBlue); }
//     }
//   }
//
//   @override
//   bool shouldRepaint(_PreviewRoutePainter old) => old.progress != progress;
// }