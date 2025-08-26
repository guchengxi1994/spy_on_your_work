import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/isar/database.dart';

/// 应用使用事件 - 适配calendar_view的CalendarEventData
class AppUsageEvent extends CalendarEventData<AppUsageTimeSlot> {
  /// 应用信息
  final AppUsageTimeSlot timeSlot;

  AppUsageEvent({required this.timeSlot})
    : super(
        title: _buildEventTitle(timeSlot),
        date: timeSlot.startTime,
        startTime: timeSlot.startTime,
        endTime: timeSlot.endTime,
        description: timeSlot.title,
        event: timeSlot,
        color: getCategoryColor(timeSlot.category),
      );

  /// 构建事件标题
  static String _buildEventTitle(AppUsageTimeSlot timeSlot) {
    final duration = timeSlot.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    String durationText;
    if (hours > 0) {
      durationText = '${hours}h${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      durationText = '${minutes}m';
    }

    return '${timeSlot.appName} ($durationText)';
  }

  /// 获取分类颜色
  static Color getCategoryColor(IAppTypes category) {
    switch (category) {
      case IAppTypes.work:
        return const Color(0xFF4285F4); // 蓝色
      case IAppTypes.study:
        return const Color(0xFF34A853); // 绿色
      case IAppTypes.joy:
        return const Color(0xFFFBBC04); // 黄色
      case IAppTypes.others:
        return const Color(0xFFEA4335); // 红色
      case IAppTypes.unknown:
        return const Color(0xFF9AA0A6); // 灰色
    }
  }

  /// 获取分类显示名称
  static String getCategoryDisplayName(IAppTypes category) {
    switch (category) {
      case IAppTypes.work:
        return '工作';
      case IAppTypes.study:
        return '学习';
      case IAppTypes.joy:
        return '娱乐';
      case IAppTypes.others:
        return '其他';
      case IAppTypes.unknown:
        return '未分类';
    }
  }

  /// 从AppUsageTimeSlot列表创建CalendarEventData列表
  static List<CalendarEventData<AppUsageTimeSlot>> fromTimeSlots(
    List<AppUsageTimeSlot> timeSlots,
  ) {
    return timeSlots
        .map((timeSlot) => AppUsageEvent(timeSlot: timeSlot))
        .toList();
  }

  /// 获取简化的应用名称（用于在小空间中显示）
  String get shortAppName {
    if (timeSlot.appName.length <= 8) {
      return timeSlot.appName;
    }
    return '${timeSlot.appName.substring(0, 6)}..';
  }

  /// 获取时间段显示文本
  String get timeRangeText {
    return timeSlot.timeSlotDisplay;
  }

  /// 格式化持续时间
  String get durationText {
    final duration = timeSlot.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      return '${minutes}m';
    }
  }

  /// 检查是否是长时间使用（超过30分钟）
  bool get isLongUsage {
    return timeSlot.duration.inMinutes >= 30;
  }

  /// 检查是否是短时间使用（少于5分钟）
  bool get isShortUsage {
    return timeSlot.duration.inMinutes < 5;
  }
}
