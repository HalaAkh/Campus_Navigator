import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../data/rooms.dart';
import '../../utils/app_state.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomNumber;
  final VoidCallback onNavigate;
  final VoidCallback onBack;

  const RoomDetailScreen({
    super.key,
    required this.roomNumber,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final room = getRoomByNumber(roomNumber);
    final state = context.watch<AppState>();

    if (room == null) {
      return Scaffold(
        body: Center(child: Text('Room not found', style: AppTextStyles.bodyRegular(16))),
      );
    }

    final details = [
      _DetailRow(icon: Icons.business_outlined, label: 'Building', value: 'Nicol Hall'),
      _DetailRow(icon: Icons.layers_outlined, label: 'Floor', value: '${room.floor}'),
      _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: 'Main Corridor — Room ${room.number} Area'),
      _DetailRow(icon: Icons.sensors_outlined, label: 'Nearest Beacon', value: room.beaconMac),
      _DetailRow(icon: Icons.people_outline, label: 'Category', value: room.category),
    ];

    final isSaved = state.isRoomSaved(room.number);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero
                  Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        Text(room.number, style: AppTextStyles.headingBold(64, color: Colors.white)),
                        Text(room.name,
                            style: AppTextStyles.bodyMedium(18,
                                color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text('Floor ${room.floor}',
                                  style: AppTextStyles.bodyBold(12, color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text('Nicol Hall',
                                  style: AppTextStyles.bodySemiBold(12,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      children: [
                        ...details.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(d.icon, size: 18, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.label,
                                        style: AppTextStyles.bodyRegular(11,
                                            color: AppColors.mutedForeground)),
                                    Text(d.value, style: AppTextStyles.bodySemiBold(13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),

                        // Beacon indicator
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  const Icon(Icons.sensors_outlined,
                                      size: 20, color: AppColors.primary),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Beacon ${room.beacon} detected',
                                      style: AppTextStyles.bodySemiBold(13)),
                                  Text('Signal: Strong',
                                      style: AppTextStyles.bodyRegular(11,
                                          color: AppColors.mutedForeground)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Save button
                        OutlinedPillButton(
                          label: isSaved ? '❤️ Saved' : '♡ Save Room',
                          onPressed: () {
                            if (isSaved) {
                              state.removeRoom(room.number);
                            } else {
                              state.saveRoom(room);
                            }
                          },
                          borderColor: AppColors.accent,
                          textColor: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Fixed bottom CTA
      bottomSheet: Container(
        color: AppColors.card,
        padding: EdgeInsets.fromLTRB(20, 16, 20,
            MediaQuery.of(context).padding.bottom + 16),
        child: GradientButton(
          label: 'Navigate Here →',
          onPressed: onNavigate,
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});
}
