import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/app/app_calendar/models/app_usage_event.dart';

/// 日视图组件 - 显示具体的应用使用时间段事件
class DayViewWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<AppUsageTimeSlot> timeSlots;
  final VoidCallback? onBackToMonth;

  const DayViewWidget({
    super.key,
    required this.selectedDate,
    required this.timeSlots,
    this.onBackToMonth,
  });

  @override
  Widget build(BuildContext context) {
    // 创建事件控制器并添加事件
    final eventController = EventController<AppUsageTimeSlot>();
    final events = AppUsageEvent.fromTimeSlots(timeSlots);
    eventController.addAll(events);

    return Column(
      children: [
        // 日期头部和返回按钮
        _buildDayHeader(context),
        // 日视图
        Expanded(
          child: CalendarControllerProvider(
            controller: eventController,
            child: DayView<AppUsageTimeSlot>(
              controller: eventController,
              showVerticalLine: true,
              showLiveTimeLineInAllDays: true,
              minDay: selectedDate,
              maxDay: selectedDate,
              initialDay: selectedDate,
              heightPerMinute: 1.0,
              eventArranger: const SideEventArranger(),
              onEventTap: (events, date) {
                if (events.isNotEmpty) {
                  _showEventDetails(context, events.first);
                }
              },
              eventTileBuilder:
                  (date, events, boundary, startDuration, endDuration) {
                    if (events.isEmpty) return const SizedBox.shrink();

                    final event = events.first as AppUsageEvent;
                    return _buildEventTile(event, boundary.height);
                  },
              dayTitleBuilder: (date) => _buildDayTitle(date),
              hourIndicatorSettings: const HourIndicatorSettings(
                height: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建日期头部
  Widget _buildDayHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          if (onBackToMonth != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackToMonth,
              tooltip: '返回月视图',
            ),
          // 日期标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateHeader(selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildDaySummary(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // 统计信息
          _buildStatistics(context),
        ],
      ),
    );
  }

  /// 构建日标题
  Widget _buildDayTitle(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        _formatDateHeader(date),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 构建事件瓦片
  Widget _buildEventTile(AppUsageEvent event, double height) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: event.color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: event.color.withOpacity(0.8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 应用名称
          Text(
            event.timeSlot.appName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // 时间段
          Text(
            event.timeRangeText,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          // 持续时间（如果空间足够）
          if (height > 60) ...[
            const SizedBox(height: 2),
            Text(
              event.durationText,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
          // 窗口标题（如果空间足够且有标题）
          if (height > 80 && event.timeSlot.title.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              event.timeSlot.title,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatistics(BuildContext context) {
    final totalDuration = timeSlots.fold<Duration>(
      Duration.zero,
      (sum, slot) => sum + slot.duration,
    );

    // 按分类统计
    final Map<IAppTypes, Duration> categoryStats = {};
    for (final slot in timeSlots) {
      categoryStats[slot.category] =
          (categoryStats[slot.category] ?? Duration.zero) + slot.duration;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 总时长
        Text(
          '总计: ${_formatDuration(totalDuration)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // 分类统计
        ...categoryStats.entries.where((e) => e.value.inMinutes > 0).map((
          entry,
        ) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppUsageEvent.getCategoryColor(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${AppUsageEvent.getCategoryDisplayName(entry.key)}: ${_formatDuration(entry.value)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 构建日摘要
  String _buildDaySummary() {
    if (timeSlots.isEmpty) {
      return '暂无使用记录';
    }

    final appCount = timeSlots.map((e) => e.appId).toSet().length;
    final sessionCount = timeSlots.length;

    return '$appCount个应用，$sessionCount个时间段';
  }

  /// 格式化日期头部
  String _formatDateHeader(DateTime date) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[date.weekday % 7];

    return '${date.year}年${date.month}月${date.day}日 $weekday';
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      return '${minutes}m';
    }
  }

  /// 显示事件详情
  void _showEventDetails(
    BuildContext context,
    CalendarEventData<AppUsageTimeSlot> event,
  ) {
    final appEvent = event as AppUsageEvent;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppUsageEvent.getCategoryColor(
                  appEvent.timeSlot.category,
                ),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(appEvent.timeSlot.appName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.schedule, '时间段', appEvent.timeRangeText),
            _buildDetailRow(Icons.timer, '持续时长', appEvent.durationText),
            _buildDetailRow(
              Icons.category,
              '分类',
              AppUsageEvent.getCategoryDisplayName(appEvent.timeSlot.category),
            ),
            if (appEvent.timeSlot.title.isNotEmpty)
              _buildDetailRow(Icons.title, '窗口标题', appEvent.timeSlot.title),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
