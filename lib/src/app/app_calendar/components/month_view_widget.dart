import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/app_calendar/app_calendar_state.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/app/app_calendar/models/app_usage_event.dart';

/// 月视图组件 - 显示每天的统计概览
class MonthViewWidget extends StatelessWidget {
  final AppCalendarState state;
  final Function(DateTime) onDateTap;
  final Function(DateTime) onMonthChange;

  const MonthViewWidget({
    super.key,
    required this.state,
    required this.onDateTap,
    required this.onMonthChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 月份头部
        _buildMonthHeader(context),
        // 星期头部
        _buildWeekHeader(context),
        // 日历网格
        Expanded(child: _buildCalendarGrid(context)),
      ],
    );
  }

  /// 构建月份头部
  Widget _buildMonthHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final previousMonth = DateTime(
                state.currentMonth.year,
                state.currentMonth.month - 1,
                1,
              );
              onMonthChange(previousMonth);
            },
          ),
          Text(
            '${state.currentMonth.year}年${state.currentMonth.month}月',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextMonth = DateTime(
                state.currentMonth.year,
                state.currentMonth.month + 1,
                1,
              );
              onMonthChange(nextMonth);
            },
          ),
        ],
      ),
    );
  }

  /// 构建星期头部
  Widget _buildWeekHeader(BuildContext context) {
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建日历网格
  Widget _buildCalendarGrid(BuildContext context) {
    final firstDayOfMonth = state.currentMonth;
    final lastDayOfMonth = DateTime(
      firstDayOfMonth.year,
      firstDayOfMonth.month + 1,
      0,
    );

    // 计算第一周的开始日期（周日开始）
    final firstWeekStart = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );

    // 计算总共需要多少天来填满网格
    final weeksNeeded =
        ((lastDayOfMonth.day + firstDayOfMonth.weekday % 7 + 6) / 7).ceil();
    final totalDays = weeksNeeded * 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: totalDays,
      itemBuilder: (context, index) {
        final date = firstWeekStart.add(Duration(days: index));
        final isInCurrentMonth = date.month == firstDayOfMonth.month;
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, state.selectedDate);

        return _buildDayCell(
          context,
          date,
          isInCurrentMonth,
          isToday,
          isSelected,
        );
      },
    );
  }

  /// 构建日期单元格
  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    bool isInCurrentMonth,
    bool isToday,
    bool isSelected,
  ) {
    final usage = state.getUsageForDate(date);
    final totalDuration = usage.values.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
    final hasData = totalDuration.inMinutes > 0;

    return GestureDetector(
      onTap: () => onDateTap(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getCellBackgroundColor(
            context,
            isSelected,
            isToday,
            isInCurrentMonth,
          ),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // 日期数字
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isInCurrentMonth
                      ? (isSelected ? Colors.white : null)
                      : Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ),
            // 使用统计
            if (hasData && isInCurrentMonth) ...[
              Expanded(
                child: Column(
                  children: [
                    // 总时长
                    Text(
                      _formatDuration(totalDuration),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 分类指示器
                    Expanded(
                      child: _buildCategoryIndicators(
                        context,
                        usage,
                        isSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isInCurrentMonth) ...[
              Expanded(
                child: Center(
                  child: Text(
                    '无记录',
                    style: TextStyle(
                      fontSize: 8,
                      color: isSelected ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建分类指示器
  Widget _buildCategoryIndicators(
    BuildContext context,
    Map<IAppTypes, Duration> usage,
    bool isSelected,
  ) {
    final nonZeroUsage =
        usage.entries.where((e) => e.value.inMinutes > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (nonZeroUsage.isEmpty) return const SizedBox.shrink();

    // 只显示前3个最多使用的分类
    final topCategories = nonZeroUsage.take(3).toList();

    return Column(
      children: topCategories.map((entry) {
        final color = AppUsageEvent.getCategoryColor(entry.key);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          height: 8,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _formatDuration(entry.value),
                  style: TextStyle(
                    fontSize: 7,
                    color: isSelected ? Colors.black54 : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 获取单元格背景色
  Color _getCellBackgroundColor(
    BuildContext context,
    bool isSelected,
    bool isToday,
    bool isInCurrentMonth,
  ) {
    if (isSelected) {
      return Theme.of(context).primaryColor;
    }

    if (isToday) {
      return Theme.of(context).primaryColor.withOpacity(0.3);
    }

    if (!isInCurrentMonth) {
      return Colors.grey[50]!;
    }

    return Colors.white;
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h${minutes > 0 ? '${minutes}m' : ''}';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '';
    }
  }

  /// 判断是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
