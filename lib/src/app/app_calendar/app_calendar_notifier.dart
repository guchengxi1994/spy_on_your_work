import 'package:calendar_view/calendar_view.dart';
import 'package:riverpod/riverpod.dart';
import 'package:spy_on_your_work/src/app/app_calendar/app_calendar_state.dart';
import 'package:spy_on_your_work/src/app/app_calendar/models/app_usage_event.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/common/logger.dart';

/// 日历视图状态管理器
class AppCalendarNotifier extends AutoDisposeAsyncNotifier<AppCalendarState> {
  late IsarDatabase database;

  @override
  Future<AppCalendarState> build() async {
    database = IsarDatabase();
    await database.initialDatabase();

    final initialState = AppCalendarState.initial();

    try {
      // 加载当前月份的数据
      final updatedState = await _loadMonthData(initialState.currentMonth);

      // 更新选中日期的详细数据
      final selectedDateUsage = updatedState.getUsageForDate(
        initialState.selectedDate,
      );
      final selectedDateAppDetails = await database.getDayAppUsageDetails(
        initialState.selectedDate,
      );
      final selectedDateTimeSlots = await database.getDayAppUsageTimeSlots(
        initialState.selectedDate,
      );
      final totalUsage = selectedDateUsage.values.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );

      // 更新事件控制器
      final eventController = updatedState.eventController;
      _updateEventController(eventController, selectedDateTimeSlots);

      return updatedState.copyWith(
        selectedDateUsage: selectedDateUsage,
        selectedDateAppDetails: selectedDateAppDetails,
        selectedDateTimeSlots: selectedDateTimeSlots,
        totalUsage: totalUsage,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logger.severe('加载日历数据失败', e, stackTrace);
      return initialState.copyWith(isLoading: false, error: '加载数据失败: $e');
    }
  }

  /// 选择日期
  Future<void> selectDate(DateTime date) async {
    final currentState = state.value;
    if (currentState == null) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      // 如果选择的日期不在当前加载的数据中，需要加载新的数据
      AppCalendarState updatedState = currentState;
      if (!currentState.dailyUsageData.containsKey(normalizedDate)) {
        // 检查是否需要加载新月份的数据
        final selectedMonth = DateTime(date.year, date.month, 1);
        if (selectedMonth != currentState.currentMonth) {
          updatedState = await _loadMonthData(selectedMonth);
        } else {
          // 加载单日数据
          final dayUsage = await database.getDayUsageByCategory(normalizedDate);
          final newDailyData = Map<DateTime, Map<IAppTypes, Duration>>.from(
            currentState.dailyUsageData,
          );
          newDailyData[normalizedDate] = dayUsage;
          updatedState = currentState.copyWith(dailyUsageData: newDailyData);
        }
      }

      // 更新选中日期的详细数据
      final selectedDateUsage = updatedState.getUsageForDate(normalizedDate);
      final selectedDateAppDetails = await database.getDayAppUsageDetails(
        normalizedDate,
      );
      final totalUsage = selectedDateUsage.values.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );

      state = AsyncValue.data(
        updatedState.copyWith(
          selectedDate: normalizedDate,
          selectedDateUsage: selectedDateUsage,
          selectedDateAppDetails: selectedDateAppDetails,
          totalUsage: totalUsage,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e, stackTrace) {
      logger.severe('选择日期失败', e, stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: '选择日期失败: $e'),
      );
    }
  }

  /// 切换月份
  Future<void> changeMonth(DateTime month) async {
    final currentState = state.value;
    if (currentState == null) return;

    final firstDayOfMonth = DateTime(month.year, month.month, 1);

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final updatedState = await _loadMonthData(firstDayOfMonth);

      state = AsyncValue.data(
        updatedState.copyWith(isLoading: false, error: null),
      );
    } catch (e, stackTrace) {
      logger.severe('切换月份失败', e, stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: '切换月份失败: $e'),
      );
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final updatedState = await _loadMonthData(currentState.currentMonth);

      // 更新选中日期的详细数据
      final selectedDateUsage = updatedState.getUsageForDate(
        currentState.selectedDate,
      );
      final selectedDateAppDetails = await database.getDayAppUsageDetails(
        currentState.selectedDate,
      );
      final totalUsage = selectedDateUsage.values.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );

      state = AsyncValue.data(
        updatedState.copyWith(
          selectedDate: currentState.selectedDate,
          selectedDateUsage: selectedDateUsage,
          selectedDateAppDetails: selectedDateAppDetails,
          totalUsage: totalUsage,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e, stackTrace) {
      logger.severe('刷新数据失败', e, stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: '刷新数据失败: $e'),
      );
    }
  }

  late EventController<AppUsageTimeSlot> eventController = EventController();

  /// 加载指定月份的数据
  Future<AppCalendarState> _loadMonthData(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0); // 获取月份的最后一天

    logger.info('加载月份数据: ${month.year}-${month.month}');

    final dailyUsageData = await database.getDailyUsageByCategory(
      firstDay,
      lastDay,
    );

    return AppCalendarState(
      viewMode: state.value?.viewMode ?? CalendarViewMode.month,
      selectedDate: state.value?.selectedDate ?? DateTime.now(),
      currentMonth: firstDay,
      dailyUsageData: dailyUsageData,
      dailyAppDetails: {},
      isLoading: false,
      isLoadingDetails: false,
      selectedDateUsage:
          state.value?.selectedDateUsage ?? _getEmptyCategoryUsage(),
      selectedDateAppDetails: state.value?.selectedDateAppDetails ?? [],
      totalUsage: state.value?.totalUsage ?? Duration.zero,
      dailyTimeSlots: {},
      eventController: eventController,
      selectedDateTimeSlots: [],
    );
  }

  /// 更新事件控制器
  void _updateEventController(
    EventController<AppUsageTimeSlot> controller,
    List<AppUsageTimeSlot> timeSlots,
  ) {
    // 清除旧事件
    controller.removeWhere((event) => true);

    // 添加新事件
    final events = AppUsageEvent.fromTimeSlots(timeSlots);
    controller.addAll(events);
  }

  Map<IAppTypes, Duration> _getEmptyCategoryUsage() {
    return {for (final category in IAppTypes.values) category: Duration.zero};
  }

  /// 加载指定日期的应用详情
  Future<void> loadAppDetailsForDate(DateTime date) async {
    final currentState = state.value;
    if (currentState == null) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 如果已经有该日期的详情，则不重复加载
    if (currentState.dailyAppDetails.containsKey(normalizedDate)) {
      return;
    }

    try {
      state = AsyncValue.data(currentState.copyWith(isLoadingDetails: true));

      final appDetails = await database.getDayAppUsageDetails(normalizedDate);
      final newDailyAppDetails = Map<DateTime, List<AppUsageDetail>>.from(
        currentState.dailyAppDetails,
      );
      newDailyAppDetails[normalizedDate] = appDetails;

      state = AsyncValue.data(
        currentState.copyWith(
          dailyAppDetails: newDailyAppDetails,
          isLoadingDetails: false,
        ),
      );
    } catch (e, stackTrace) {
      logger.severe('加载应用详情失败', e, stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(isLoadingDetails: false, error: '加载应用详情失败: $e'),
      );
    }
  }

  /// 获取应用使用趋势
  Future<Map<String, List<Duration>>> getAppUsageTrend(
    DateTime startDate,
    DateTime endDate,
    List<int> appIds,
  ) async {
    try {
      return await database.getAppUsageTrend(startDate, endDate, appIds);
    } catch (e, stackTrace) {
      logger.severe('获取应用使用趋势失败', e, stackTrace);
      return {};
    }
  }

  /// 切换视图模式
  Future<void> switchViewMode(CalendarViewMode newMode) async {
    final currentState = state.value;
    if (currentState == null || currentState.viewMode == newMode) return;

    try {
      state = AsyncValue.data(
        currentState.copyWith(viewMode: newMode, isLoading: false),
      );
    } catch (e, stackTrace) {
      logger.severe('切换视图模式失败', e, stackTrace);
    }
  }

  /// 跳转到日视图
  Future<void> goToDayView(DateTime date) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // 首先切换到日视图模式
      await switchViewMode(CalendarViewMode.day);

      // 然后选中日期，确保加载时间段数据
      await selectDate(date);

      // 加载日视图所需的时间段数据
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final timeSlots = await database.getDayAppUsageTimeSlots(normalizedDate);
      final updatedState = state.value!;

      state = AsyncValue.data(
        updatedState.copyWith(selectedDateTimeSlots: timeSlots),
      );
    } catch (e, stackTrace) {
      logger.severe('跳转到日视图失败', e, stackTrace);
    }
  }

  /// 返回月视图
  Future<void> goToMonthView() async {
    await switchViewMode(CalendarViewMode.month);
  }
}

/// 日历视图状态管理器提供器
final appCalendarNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AppCalendarNotifier, AppCalendarState>(
      () => AppCalendarNotifier(),
    );
