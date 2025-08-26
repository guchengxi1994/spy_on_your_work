import 'package:spy_on_your_work/src/isar/apps.dart';

/// 时间维度枚举
enum TimeDimension {
  today('今天'),
  allTime('全部');

  const TimeDimension(this.displayName);
  final String displayName;
}

/// 应用图表状态
class AppChartState {
  final Map<IAppTypes, Duration> categoryUsage;
  final TimeDimension selectedDimension;
  final bool isLoading;
  final String? error;

  const AppChartState({
    this.categoryUsage = const {},
    this.selectedDimension = TimeDimension.today,
    this.isLoading = false,
    this.error,
  });

  AppChartState copyWith({
    Map<IAppTypes, Duration>? categoryUsage,
    TimeDimension? selectedDimension,
    bool? isLoading,
    String? error,
  }) {
    return AppChartState(
      categoryUsage: categoryUsage ?? this.categoryUsage,
      selectedDimension: selectedDimension ?? this.selectedDimension,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// 获取总使用时长
  Duration get totalUsage {
    return categoryUsage.values.fold(
      Duration.zero,
      (total, duration) => total + duration,
    );
  }

  /// 获取有使用记录的分类
  Map<IAppTypes, Duration> get nonZeroCategories {
    return Map.fromEntries(
      categoryUsage.entries.where((entry) => entry.value > Duration.zero),
    );
  }

  /// 获取分类的使用百分比
  double getCategoryPercentage(IAppTypes category) {
    if (totalUsage == Duration.zero) return 0.0;
    final categoryDuration = categoryUsage[category] ?? Duration.zero;
    return categoryDuration.inMinutes / totalUsage.inMinutes;
  }
}
