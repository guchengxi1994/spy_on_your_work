import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/app_record.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/rust/api/spy_api.dart' as api;

class ApplicationNotifier extends Notifier<ApplicationState> {
  DateTime? _currentSessionStart;
  final IsarDatabase database = IsarDatabase();
  bool _isInitialized = false;

  @override
  ApplicationState build() {
    // 初始化状态，稍后从数据库加载当天数据
    _initializeFromDatabase();

    // 监听应用信息流
    api.applicationInfoStream().listen((event) async {
      logger.info(
        "running app: ${event.name}, title: ${event.title}, path: ${event.path}",
      );
      await _handleAppSwitch(event);
    });

    return ApplicationState(isSpyOn: api.getSpyStatus());
  }

  /// 从数据库初始化当天的应用使用情况
  Future<void> _initializeFromDatabase() async {
    if (_isInitialized) return;

    try {
      await database.initialDatabase();

      // 获取当天的使用时长和会话次数
      final durations = await database.getTodayAppUsageDurations();
      final sessionCounts = await database.getTodayAppSessionCounts();

      final Map<String, ApplicationUsage> applicationUsages = {};

      // 遍历所有有使用记录的应用
      for (final appId in {...durations.keys, ...sessionCounts.keys}) {
        final appInfo = await database.getApplicationById(appId);
        if (appInfo != null) {
          // 获取最新的使用记录作为 title 和 lastUsed
          final records = await database.isar!.appRecords
              .filter()
              .appIdEqualTo(appId)
              .and()
              .yearEqualTo(DateTime.now().year)
              .and()
              .monthEqualTo(DateTime.now().month)
              .and()
              .dayEqualTo(DateTime.now().day)
              .sortByHourDesc()
              .thenByMinuteDesc()
              .findAll();

          if (records.isNotEmpty) {
            final latestRecord = records.first;
            final lastUsed = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              latestRecord.hour,
              latestRecord.minute,
            );

            applicationUsages[appInfo.name] = ApplicationUsage(
              name: appInfo.name,
              title: latestRecord.title,
              path: appInfo.path,
              icon: appInfo.icon,
              totalUsage: durations[appId] ?? Duration.zero,
              lastUsed: lastUsed,
              sessionCount: sessionCounts[appId] ?? 0,
            );
          }
        }
      }

      // 更新状态
      state = state.copyWith(applicationUsages: applicationUsages);
      _isInitialized = true;

      logger.info("已从数据库加载当天的应用使用情况: ${applicationUsages.length} 个应用");
    } catch (e) {
      logger.severe("初始化数据库失败: $e");
      _isInitialized = true; // 即使失败也设置为已初始化，避免重复尝试
    }
  }

  Future<void> _handleAppSwitch(dynamic app) async {
    final now = DateTime.now();

    // 如果当前有正在跑的应用，先结束它的会话
    if (state.currentApp != null && _currentSessionStart != null) {
      _endCurrentSession();
    }

    // 获取或创建应用信息
    final appInfo = await database.getOrCreateApplication(
      app.name,
      app.path,
      app.icon,
    );

    // 添加使用记录
    await database.addAppRecord(appInfo.id, app.title);

    // 开始新的会话
    _currentSessionStart = now;
    state = state.copyWith(currentApp: app.name, sessionStartTime: now);

    // 更新或创建应用使用记录
    final currentUsages = Map<String, ApplicationUsage>.from(
      state.applicationUsages,
    );
    final existingUsage = currentUsages[app.name];

    if (existingUsage != null) {
      // 更新现有记录
      currentUsages[app.name] = existingUsage.copyWith(
        title: app.title,
        lastUsed: now,
        sessionCount: existingUsage.sessionCount + 1,
      );
    } else {
      // 创建新记录
      currentUsages[app.name] = ApplicationUsage(
        name: app.name,
        title: app.title,
        path: app.path,
        icon: app.icon,
        totalUsage: Duration.zero,
        lastUsed: now,
        sessionCount: 1,
      );
    }

    state = state.copyWith(applicationUsages: currentUsages);
  }

  void _endCurrentSession() {
    if (state.currentApp == null || _currentSessionStart == null) return;

    final sessionDuration = DateTime.now().difference(_currentSessionStart!);
    final currentUsages = Map<String, ApplicationUsage>.from(
      state.applicationUsages,
    );
    final usage = currentUsages[state.currentApp!];

    if (usage != null) {
      currentUsages[state.currentApp!] = usage.copyWith(
        totalUsage: usage.totalUsage + sessionDuration,
      );
      state = state.copyWith(applicationUsages: currentUsages);
    }
  }

  void startSpy() {
    if (!state.isSpyOn) {
      api.startSpy();
      state = state.copyWith(isSpyOn: true);
      logger.info("开始监控应用使用情况");
    }
  }

  void stopSpy() {
    if (state.isSpyOn) {
      _endCurrentSession();
      state = state.copyWith(
        isSpyOn: false,
        currentApp: null,
        sessionStartTime: null,
      );
      logger.info("停止监控应用使用情况");
    }
  }

  void clearStatistics() {
    // 结束当前会话
    _endCurrentSession();

    // 清除内存中的统计数据
    state = state.copyWith(
      applicationUsages: {},
      currentApp: null,
      sessionStartTime: null,
    );
    logger.info("清除所有统计数据");
  }

  /// 清除当天的数据库记录（可选）
  Future<void> clearTodayDatabaseRecords() async {
    try {
      await database.initialDatabase();
      final now = DateTime.now();

      await database.isar!.writeTxn(() async {
        await database.isar!.appRecords
            .filter()
            .yearEqualTo(now.year)
            .and()
            .monthEqualTo(now.month)
            .and()
            .dayEqualTo(now.day)
            .deleteAll();
      });

      logger.info("已清除当天的数据库记录");
    } catch (e) {
      logger.severe("清除数据库记录失败: $e");
    }
  }

  /// 重新加载当天数据
  Future<void> reloadTodayData() async {
    _isInitialized = false;
    await _initializeFromDatabase();
  }
}

final applicationNotifierProvider =
    NotifierProvider<ApplicationNotifier, ApplicationState>(
      () => ApplicationNotifier(),
    );
