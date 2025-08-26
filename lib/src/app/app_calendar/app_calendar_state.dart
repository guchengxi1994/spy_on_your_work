import 'package:calendar_view/calendar_view.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/app/app_calendar/models/app_usage_event.dart';

/// 日历视图模式
enum CalendarViewMode {
  month, // 月视图
  day, // 日视图
}

/// 日历视图状态数据结构
class AppCalendarState {
  /// 当前视图模式
  final CalendarViewMode viewMode;

  /// 选中的日期
  final DateTime selectedDate;

  /// 当前显示月份的第一天
  final DateTime currentMonth;

  /// 每日使用统计数据 - 按日期和应用类型聚合
  final Map<DateTime, Map<IAppTypes, Duration>> dailyUsageData;

  /// 每日应用使用详情数据
  final Map<DateTime, List<AppUsageDetail>> dailyAppDetails;

  /// 每日应用使用时间段数据
  final Map<DateTime, List<AppUsageTimeSlot>> dailyTimeSlots;

  /// 日历事件控制器
  final EventController<AppUsageTimeSlot> eventController;

  /// 是否正在加载数据
  final bool isLoading;

  /// 是否正在加载应用详情
  final bool isLoadingDetails;

  /// 错误信息
  final String? error;

  /// 选中日期的详细数据
  final Map<IAppTypes, Duration> selectedDateUsage;

  /// 选中日期的应用详情
  final List<AppUsageDetail> selectedDateAppDetails;

  /// 选中日期的时间段
  final List<AppUsageTimeSlot> selectedDateTimeSlots;

  /// 总使用时长（选中日期）
  final Duration totalUsage;

  const AppCalendarState({
    required this.viewMode,
    required this.selectedDate,
    required this.currentMonth,
    required this.dailyUsageData,
    required this.dailyAppDetails,
    required this.dailyTimeSlots,
    required this.eventController,
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.error,
    required this.selectedDateUsage,
    required this.selectedDateAppDetails,
    required this.selectedDateTimeSlots,
    required this.totalUsage,
  });

  /// 创建初始状态
  factory AppCalendarState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    return AppCalendarState(
      viewMode: CalendarViewMode.month,
      selectedDate: today,
      currentMonth: firstDayOfMonth,
      dailyUsageData: {},
      dailyAppDetails: {},
      dailyTimeSlots: {},
      eventController: EventController<AppUsageTimeSlot>(),
      isLoading: true,
      isLoadingDetails: false,
      selectedDateUsage: _getEmptyCategoryUsage(),
      selectedDateAppDetails: [],
      selectedDateTimeSlots: [],
      totalUsage: Duration.zero,
    );
  }

  /// 复制状态
  AppCalendarState copyWith({
    CalendarViewMode? viewMode,
    DateTime? selectedDate,
    DateTime? currentMonth,
    Map<DateTime, Map<IAppTypes, Duration>>? dailyUsageData,
    Map<DateTime, List<AppUsageDetail>>? dailyAppDetails,
    Map<DateTime, List<AppUsageTimeSlot>>? dailyTimeSlots,
    EventController<AppUsageTimeSlot>? eventController,
    bool? isLoading,
    bool? isLoadingDetails,
    String? error,
    Map<IAppTypes, Duration>? selectedDateUsage,
    List<AppUsageDetail>? selectedDateAppDetails,
    List<AppUsageTimeSlot>? selectedDateTimeSlots,
    Duration? totalUsage,
  }) {
    return AppCalendarState(
      viewMode: viewMode ?? this.viewMode,
      selectedDate: selectedDate ?? this.selectedDate,
      currentMonth: currentMonth ?? this.currentMonth,
      dailyUsageData: dailyUsageData ?? this.dailyUsageData,
      dailyAppDetails: dailyAppDetails ?? this.dailyAppDetails,
      dailyTimeSlots: dailyTimeSlots ?? this.dailyTimeSlots,
      eventController: eventController ?? this.eventController,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      error: error,
      selectedDateUsage: selectedDateUsage ?? this.selectedDateUsage,
      selectedDateAppDetails:
          selectedDateAppDetails ?? this.selectedDateAppDetails,
      selectedDateTimeSlots:
          selectedDateTimeSlots ?? this.selectedDateTimeSlots,
      totalUsage: totalUsage ?? this.totalUsage,
    );
  }

  /// 获取空的分类使用统计
  static Map<IAppTypes, Duration> _getEmptyCategoryUsage() {
    return {for (final category in IAppTypes.values) category: Duration.zero};
  }

  /// 获取指定日期的使用统计
  Map<IAppTypes, Duration> getUsageForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyUsageData[normalizedDate] ?? _getEmptyCategoryUsage();
  }

  /// 获取指定日期的总使用时长
  Duration getTotalUsageForDate(DateTime date) {
    final usage = getUsageForDate(date);
    return usage.values.fold(Duration.zero, (sum, duration) => sum + duration);
  }

  /// 获取指定日期是否有使用数据
  bool hasDataForDate(DateTime date) {
    final usage = getUsageForDate(date);
    return usage.values.any((duration) => duration.inMinutes > 0);
  }

  /// 获取指定日期的主要使用类别（使用时间最长的类别）
  IAppTypes? getPrimaryCategory(DateTime date) {
    final usage = getUsageForDate(date);
    var maxDuration = Duration.zero;
    IAppTypes? primaryCategory;

    for (final entry in usage.entries) {
      if (entry.value > maxDuration) {
        maxDuration = entry.value;
        primaryCategory = entry.key;
      }
    }

    return maxDuration.inMinutes > 0 ? primaryCategory : null;
  }

  /// 获取指定日期的应用使用详情
  List<AppUsageDetail> getAppDetailsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyAppDetails[normalizedDate] ?? [];
  }

  /// 获取指定日期是否有应用详情数据
  bool hasAppDetailsForDate(DateTime date) {
    final details = getAppDetailsForDate(date);
    return details.isNotEmpty;
  }

  /// 获取指定日期使用最多的应用
  AppUsageDetail? getTopAppForDate(DateTime date) {
    final details = getAppDetailsForDate(date);
    if (details.isEmpty) return null;
    return details.first; // 已经按使用时长排序
  }

  /// 获取指定日期的应用使用时间段
  List<AppUsageTimeSlot> getTimeSlotsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyTimeSlots[normalizedDate] ?? [];
  }

  /// 获取指定日期是否有时间段数据
  bool hasTimeSlotsForDate(DateTime date) {
    final timeSlots = getTimeSlotsForDate(date);
    return timeSlots.isNotEmpty;
  }

  /// 获取指定日期的所有应用使用事件
  List<CalendarEventData<AppUsageTimeSlot>> getEventsForDate(DateTime date) {
    final timeSlots = getTimeSlotsForDate(date);
    return AppUsageEvent.fromTimeSlots(timeSlots);
  }

  /// 格式化时长显示
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  /// 获取分类的显示名称
  String getCategoryDisplayName(IAppTypes category) {
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

  /// 获取分类的颜色
  String getCategoryColor(IAppTypes category) {
    switch (category) {
      case IAppTypes.work:
        return '#4285F4'; // 蓝色
      case IAppTypes.study:
        return '#34A853'; // 绿色
      case IAppTypes.joy:
        return '#FBBC04'; // 黄色
      case IAppTypes.others:
        return '#EA4335'; // 红色
      case IAppTypes.unknown:
        return '#9AA0A6'; // 灰色
    }
  }
}
