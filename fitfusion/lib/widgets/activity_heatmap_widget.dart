import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ActivityHeatmapWidget extends StatefulWidget {
  final Map<String, int> heatmapData; // yyyy-MM-dd -> intensity 0..4
  final int year;
  final Function(DateTime date)? onDayTap;

  const ActivityHeatmapWidget({
    super.key,
    required this.heatmapData,
    required this.year,
    this.onDayTap,
  });

  @override
  State<ActivityHeatmapWidget> createState() => _ActivityHeatmapWidgetState();
}

class _ActivityHeatmapWidgetState extends State<ActivityHeatmapWidget> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedDateKey;
  int? _selectedIntensity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-scroll near current week of current year
      if (_scrollController.hasClients) {
        final now = DateTime.now();
        if (now.year == widget.year) {
          final weekOfYear = ((now.difference(DateTime(widget.year, 1, 1)).inDays) / 7).floor();
          final offset = (weekOfYear * 16.0) - 80;
          if (offset > 0) {
            _scrollController.animateTo(
              offset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getIntensityColor(int intensity, bool isDark) {
    switch (intensity) {
      case 4:
        return const Color(0xFFF59E0B); // Amber / Gold High Energy
      case 3:
        return const Color(0xFF059669); // Rich Deep Emerald
      case 2:
        return const Color(0xFF10B981); // Vibrant Emerald
      case 1:
        return const Color(0xFF6EE7B7); // Soft Mint
      case 0:
      default:
        return isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build 53 columns (weeks), each with 7 rows (Mon-Sun)
    final firstDayOfYear = DateTime(widget.year, 1, 1);
    final daysInYear = DateTime(widget.year, 12, 31).difference(firstDayOfYear).inDays + 1;

    // Calculate total active days & total contributions
    int totalActiveDays = 0;
    widget.heatmapData.forEach((_, intensity) {
      if (intensity > 0) totalActiveDays++;
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Activity Heatmap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Year ${widget.year} • $totalActiveDays active days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              // Current inspection pill if selected
              if (_selectedDateKey != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(_selectedIntensity ?? 0, isDark).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getIntensityColor(_selectedIntensity ?? 0, isDark),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$_selectedDateKey • Level ${_selectedIntensity ?? 0}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Contribution Heatmap Grid
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day-of-week labels (Mon, Wed, Fri)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 14), // month label spacer
                    _buildDayLabel('M', isDark),
                    _buildDayLabel('', isDark),
                    _buildDayLabel('W', isDark),
                    _buildDayLabel('', isDark),
                    _buildDayLabel('F', isDark),
                    _buildDayLabel('', isDark),
                    _buildDayLabel('S', isDark),
                  ],
                ),
                const SizedBox(width: 8),

                // Heatmap Weeks Columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(53, (weekIndex) {
                    final weekStartDate = firstDayOfYear.add(Duration(days: weekIndex * 7));
                    final showMonthLabel = weekStartDate.day <= 7;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month label header (e.g. Jan, Feb, Mar)
                        SizedBox(
                          height: 14,
                          child: showMonthLabel
                              ? Text(
                                  DateFormat('MMM').format(weekStartDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        // 7 Days column
                        Column(
                          children: List.generate(7, (dayIndex) {
                            final dayOffset = (weekIndex * 7) + dayIndex;
                            if (dayOffset >= daysInYear) {
                              return const SizedBox(width: 13, height: 13);
                            }

                            final date = firstDayOfYear.add(Duration(days: dayOffset));
                            final dateKey = DateFormat('yyyy-MM-dd').format(date);
                            final intensity = widget.heatmapData[dateKey] ?? 0;
                            final isSelected = _selectedDateKey == dateKey;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDateKey = dateKey;
                                  _selectedIntensity = intensity;
                                });
                                if (widget.onDayTap != null) {
                                  widget.onDayTap!(date);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: _getIntensityColor(intensity, isDark),
                                  borderRadius: BorderRadius.circular(3),
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 1.5)
                                      : null,
                                  boxShadow: intensity >= 3
                                      ? [
                                          BoxShadow(
                                            color: _getIntensityColor(intensity, isDark).withOpacity(0.4),
                                            blurRadius: 3,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Legend at bottom: Less [][][][][] More
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (level) {
                return Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(level, isDark),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String label, bool isDark) {
    return Container(
      height: 12,
      margin: const EdgeInsets.all(1.5),
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }
}
