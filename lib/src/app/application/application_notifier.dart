import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/rust/api/spy_api.dart' as api;

class ApplicationNotifier extends Notifier<ApplicationState> {
  Timer? _sessionTimer;
  DateTime? _currentSessionStart;

  @override
  ApplicationState build() {
    // 监听应用信息流
    api.applicationInfoStream().listen((event) {
      logger.info(
        "running app: ${event.name}, title: ${event.title}, path: ${event.path}",
      );
      _handleAppSwitch(event);
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
      _sessionTimer?.cancel();
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

  @override
  void dispose() {
    _sessionTimer?.cancel();
    // Notifier 不需要调用 super.dispose()
  }
}

final applicationNotifierProvider =
    NotifierProvider<ApplicationNotifier, ApplicationState>(
      () => ApplicationNotifier(),
    );
