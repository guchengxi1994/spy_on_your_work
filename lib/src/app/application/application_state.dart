class ApplicationUsage {
  final String name;
  final String title;
  final String path;
  final String? icon;
  final Duration totalUsage;
  final DateTime lastUsed;
  final int sessionCount;

  ApplicationUsage({
    required this.name,
    required this.title,
    required this.path,
    this.icon,
    required this.totalUsage,
    required this.lastUsed,
    required this.sessionCount,
  });

  ApplicationUsage copyWith({
    String? name,
    String? title,
    String? path,
    String? icon,
    Duration? totalUsage,
    DateTime? lastUsed,
    int? sessionCount,
  }) {
    return ApplicationUsage(
      name: name ?? this.name,
      title: title ?? this.title,
      path: path ?? this.path,
      icon: icon ?? this.icon,
      totalUsage: totalUsage ?? this.totalUsage,
      lastUsed: lastUsed ?? this.lastUsed,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

class ApplicationState {
  final bool isSpyOn;
  final Map<String, ApplicationUsage> applicationUsages;
  final String? currentApp;
  final DateTime? sessionStartTime;

  ApplicationState({
    required this.isSpyOn,
    this.applicationUsages = const {},
    this.currentApp,
    this.sessionStartTime,
  });

  ApplicationState copyWith({
    bool? isSpyOn,
    Map<String, ApplicationUsage>? applicationUsages,
    String? currentApp,
    DateTime? sessionStartTime,
  }) {
    return ApplicationState(
      isSpyOn: isSpyOn ?? this.isSpyOn,
      applicationUsages: applicationUsages ?? this.applicationUsages,
      currentApp: currentApp ?? this.currentApp,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    );
  }

  // 获取总使用时间
  Duration get totalUsageTime {
    return applicationUsages.values.fold(
      Duration.zero,
      (sum, app) => sum + app.totalUsage,
    );
  }

  // 获取使用时间排序的应用列表
  List<ApplicationUsage> get sortedApplications {
    final apps = applicationUsages.values.toList();
    apps.sort((a, b) => b.totalUsage.compareTo(a.totalUsage));
    return apps;
  }

  // 获取今日使用的应用数量
  int get todayAppsCount {
    final today = DateTime.now();
    return applicationUsages.values
        .where(
          (app) =>
              app.lastUsed.year == today.year &&
              app.lastUsed.month == today.month &&
              app.lastUsed.day == today.day,
        )
        .length;
  }
}
