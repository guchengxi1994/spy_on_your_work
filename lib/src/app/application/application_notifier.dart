import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/app_record.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/rust/api/spy_api.dart' as api;

class ApplicationNotifier extends Notifier<ApplicationState> {
  DateTime? _currentSessionStart;
  final IsarDatabase database = IsarDatabase();

  @override
  ApplicationState build() {
    // TODO: 根据数据库获取今天已经使用过的App情况

    // 监听应用信息流
    api.applicationInfoStream().listen((event) async {
      logger.info(
        "running app: ${event.name}, title: ${event.title}, path: ${event.path}",
      );
      _handleAppSwitch(event);
      // 查询应用信息，如果没有存储到数据库，则存储
      var appinfo = await database.isar!.iApplications
          .filter()
          .nameEqualTo(event.name)
          .pathEqualTo(event.path)
          .findFirst();
      if (appinfo == null) {
        appinfo = IApplication()
          ..name = event.name
          ..path = event.path
          ..icon = event.icon;
        await database.isar!.writeTxn(() async {
          int appid = await database.isar!.iApplications.put(appinfo!);
          appinfo.id = appid;
        });
      }
      // 将数据存储到 AppRecord 数据库中
      await database.isar!.writeTxn(() async {
        final now = DateTime.now();
        await database.isar!.appRecords.put(
          AppRecord()
            ..title = event.title
            ..appId = appinfo!.id
            ..day = now.day
            ..hour = now.hour
            ..minute = now.minute
            ..year = now.year
            ..month = now.month,
        );
      });
    });

    return ApplicationState(isSpyOn: api.getSpyStatus());
  }

  void _handleAppSwitch(dynamic app) {
    final now = DateTime.now();

    // 如果当前有正在跑的应用，先结束它的会话
    if (state.currentApp != null && _currentSessionStart != null) {
      _endCurrentSession();
    }

    // 开始新的会话
    _currentSessionStart = now;
    state = state.copyWith(currentApp: app.name, sessionStartTime: now);

    // 更新或创建应用使用记录
    final currentUsages = Map<String, ApplicationUsage>.from(
      state.applicationUsages,
    );
    final existingUsage = currentUsages[app.name];

    if (existingUsage != null) {
      currentUsages[app.name] = existingUsage.copyWith(
        title: app.title,
        lastUsed: now,
        sessionCount: existingUsage.sessionCount + 1,
      );
    } else {
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
    state = state.copyWith(
      applicationUsages: {},
      currentApp: null,
      sessionStartTime: null,
    );
    logger.info("清除所有统计数据");
  }
}

final applicationNotifierProvider =
    NotifierProvider<ApplicationNotifier, ApplicationState>(
      () => ApplicationNotifier(),
    );
