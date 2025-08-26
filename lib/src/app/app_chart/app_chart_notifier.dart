import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_on_your_work/src/app/app_chart/app_chart_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/isar/database.dart';

/// 应用图表状态管理器Provider
final appChartNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AppChartNotifier, AppChartState>(
      () => AppChartNotifier(),
    );

/// 应用图表状态管理器
class AppChartNotifier extends AutoDisposeAsyncNotifier<AppChartState> {
  final IsarDatabase database = IsarDatabase();

  @override
  Future<AppChartState> build() async {
    try {
      logger.info('Initializing AppChartNotifier');
      await database.initialDatabase();

      // 初始加载当天数据
      final categoryUsage = await database.getTodayUsageByCategory();

      return AppChartState(
        categoryUsage: categoryUsage,
        selectedDimension: TimeDimension.today,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logger.severe('Failed to initialize chart data', e, stackTrace);
      rethrow;
    }
  }

  /// 切换时间维度
  Future<void> setTimeDimension(TimeDimension dimension) async {
    final currentState = await future;
    if (currentState.selectedDimension == dimension) return;

    state = AsyncValue.data(
      currentState.copyWith(
        selectedDimension: dimension,
        isLoading: true,
        error: null,
      ),
    );

    try {
      Map<IAppTypes, Duration> categoryUsage;

      switch (dimension) {
        case TimeDimension.today:
          categoryUsage = await database.getTodayUsageByCategory();
          break;
        case TimeDimension.allTime:
          categoryUsage = await database.getAllTimeUsageByCategory();
          break;
      }

      state = AsyncValue.data(
        currentState.copyWith(
          categoryUsage: categoryUsage,
          selectedDimension: dimension,
          isLoading: false,
          error: null,
        ),
      );

      logger.info(
        'Chart data loaded for ${dimension.displayName}: '
        '${categoryUsage.length} categories',
      );
    } catch (e, stackTrace) {
      logger.severe('Failed to change time dimension', e, stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: '切换时间维度失败: $e'),
      );
    }
  }

  /// 刷新图表数据
  Future<void> refreshData() async {
    final currentState = await future;

    state = AsyncValue.data(
      currentState.copyWith(isLoading: true, error: null),
    );

    try {
      Map<IAppTypes, Duration> categoryUsage;

      switch (currentState.selectedDimension) {
        case TimeDimension.today:
          categoryUsage = await database.getTodayUsageByCategory();
          break;
        case TimeDimension.allTime:
          categoryUsage = await database.getAllTimeUsageByCategory();
          break;
      }

      state = AsyncValue.data(
        currentState.copyWith(
          categoryUsage: categoryUsage,
          isLoading: false,
          error: null,
        ),
      );

      logger.info('Chart data refreshed');
    } catch (e, stackTrace) {
      logger.severe('Failed to refresh chart data', e, stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: '刷新数据失败: $e'),
      );
    }
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
      return '< 1m';
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
        return '#FF6B6B'; // 红色
      case IAppTypes.study:
        return '#4ECDC4'; // 青色
      case IAppTypes.joy:
        return '#45B7D1'; // 蓝色
      case IAppTypes.others:
        return '#96CEB4'; // 绿色
      case IAppTypes.unknown:
        return '#FECA57'; // 黄色
    }
  }
}
