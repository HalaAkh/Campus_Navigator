import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../data/rooms.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<String> onRoomSelected;
  final VoidCallback onBack;

  const SearchScreen({super.key, required this.onRoomSelected, required this.onBack});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _floorFilter = 'all';

  static const _recentSearches = ['408', '511', '522'];

  List<RoomModel> get _filteredRooms {
    List<RoomModel> rooms;
    if (_floorFilter == '4') {
      rooms = floor4Rooms;
    } else if (_floorFilter == '5') {
      rooms = floor5Rooms;
    } else {
      rooms = allRooms;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      rooms = rooms.where((r) =>
          r.number.contains(q) ||
          r.name.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q)).toList();
    }
    return rooms;
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _filteredRooms;
    final f4 = rooms.where((r) => r.floor == 4).toList();
    final f5 = rooms.where((r) => r.floor == 5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.card,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: AppDecorations.pillInputDecoration(
                          hint: 'Where to?',
                          prefixIcon: const Icon(Icons.search, size: 16,
                              color: AppColors.mutedForeground),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Floor filter pills
                Row(
                  children: ['all', '4', '5'].map((f) {
                    final isActive = _floorFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _floorFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accent : AppColors.muted,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          f == 'all' ? 'All' : 'Floor $f',
                          style: AppTextStyles.bodySemiBold(12,
                              color: isActive ? Colors.white : AppColors.mutedForeground),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: rooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore_outlined, size: 48,
                            color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text('No rooms found', style: AppTextStyles.headingBold(16)),
                        Text('Try a different search',
                            style: AppTextStyles.bodyRegular(14,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Recent chips
                      if (_query.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Recent',
                              style: AppTextStyles.bodyMedium(12,
                                  color: AppColors.mutedForeground)),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _recentSearches.map((r) {
                            return GestureDetector(
                              onTap: () => widget.onRoomSelected(r),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text('🕐 Room $r',
                                    style: AppTextStyles.bodySemiBold(12, color: AppColors.accent)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Floor 4 rooms
                      if ((_floorFilter == 'all' || _floorFilter == '4') && f4.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('FLOOR 4',
                              style: AppTextStyles.bodyMedium(11,
                                  color: AppColors.mutedForeground)
                                  .copyWith(letterSpacing: 1.2)),
                        ),
                        ...f4.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RoomListTile(
                            number: r.number,
                            name: r.name,
                            category: r.category,
                            onTap: () => widget.onRoomSelected(r.number),
                          ),
                        )),
                      ],

                      // Floor 5 rooms
                      if ((_floorFilter == 'all' || _floorFilter == '5') && f5.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('FLOOR 5',
                              style: AppTextStyles.bodyMedium(11,
                                  color: AppColors.mutedForeground)
                                  .copyWith(letterSpacing: 1.2)),
                        ),
                        ...f5.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RoomListTile(
                            number: r.number,
                            name: r.name,
                            category: r.category,
                            onTap: () => widget.onRoomSelected(r.number),
                          ),
                        )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
