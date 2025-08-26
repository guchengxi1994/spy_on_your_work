import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_on_your_work/src/app/app_detail/app_detail_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/app_screenshot_record.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/isar/database.dart';

/// 应用详细配置状态管理器Provider
final appDetailNotifierProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      AppDetailNotifier,
      AppDetailState,
      String
    >(() => AppDetailNotifier());

/// 应用详细配置状态管理器
class AppDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<AppDetailState, String> {
  final IsarDatabase database = IsarDatabase();

  // 流订阅管理
  StreamSubscription<void>? _screenshotSubscription;

  // 当前应用ID，用于过滤相关截图更新
  int? _currentAppId;

  @override
  Future<AppDetailState> build(String appName) async {
    try {
      logger.info('初始化应用详细配置: $appName');
      await database.initialDatabase();

      // 获取应用信息
      final application = await _getApplicationByName(appName);

      if (application == null) {
        throw Exception('未找到应用: $appName');
      }

      // 设置当前应用ID
      _currentAppId = application.id;

      // 初始化监听器
      _setupScreenshotListener();

      // 加载截图和分析结果
      final screenshots = await _loadScreenshots(application.id);
      final analysisResults = await _loadAnalysisResults(application.id);

      return AppDetailState(
        application: application,
        screenshots: screenshots,
        analysisResults: analysisResults,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logger.severe('初始化应用详细配置失败', e, stackTrace);
      rethrow;
    }
  }

  /// 根据应用名称获取应用信息
  Future<IApplication?> _getApplicationByName(String appName) async {
    final allApps = await database.getAllApplications();
    for (final app in allApps) {
      if (app.name == appName) {
        return app;
      }
    }
    return null;
  }

  /// 更新应用配置
  Future<void> updateApplicationConfig({
    bool? screenshotWhenUsing,
    bool? analyseWhenUsing,
  }) async {
    final currentState = state.requireValue;
    final application = currentState.application;

    if (application == null) return;

    try {
      await database.isar!.writeTxn(() async {
        if (screenshotWhenUsing != null) {
          application.screenshotWhenUsing = screenshotWhenUsing;
        }
        if (analyseWhenUsing != null) {
          application.analyseWhenUsing = analyseWhenUsing;
        }
        await database.isar!.iApplications.put(application);
      });

      // 更新状态
      ref.invalidateSelf();

      logger.info('更新应用配置成功: ${application.name}');
    } catch (e, stackTrace) {
      logger.severe('更新应用配置失败', e, stackTrace);
      rethrow;
    }
  }

  /// 加载应用截图
  Future<List<String>> _loadScreenshots(int appId) async {
    try {
      // 从数据库查询截图记录
      final screenshotRecords = await database.getScreenshotsByAppId(appId);

      // 过滤出存在的文件路径
      final List<String> validPaths = [];
      for (final record in screenshotRecords) {
        final file = File(record.path);
        if (await file.exists()) {
          validPaths.add(record.path);
        } else {
          // 文件不存在，从数据库中删除记录
          logger.warning('截图文件不存在，删除数据库记录: ${record.path}');
          await database.deleteScreenshot(record.id);
        }
      }

      logger.info('加载应用ID $appId 的截图数量: ${validPaths.length}');
      return validPaths;
    } catch (e, stackTrace) {
      logger.severe('加载截图失败: $e', e, stackTrace);
      return [];
    }
  }

  /// 加载内容分析结果
  Future<List<AnalysisResult>> _loadAnalysisResults(int appId) async {
    try {
      // 这里应该从数据库或文件系统中加载分析结果
      // 暂时返回模拟数据，您可以根据实际存储方式修改
      return [
        AnalysisResult(
          id: 'analysis_1',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          content: '用户在浏览工作相关文档',
          category: '工作内容',
          confidence: 0.85,
          metadata: {
            'keywords': ['文档', '工作', '项目'],
          },
        ),
        AnalysisResult(
          id: 'analysis_2',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          content: '用户在编写代码',
          category: '开发工作',
          confidence: 0.92,
          metadata: {
            'language': 'Dart',
            'keywords': ['代码', '开发'],
          },
        ),
      ];
    } catch (e) {
      logger.warning('加载分析结果失败: $e');
      return [];
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// 清除截图数据
  Future<void> clearScreenshots() async {
    final currentState = state.requireValue;
    final application = currentState.application;

    if (application == null) return;

    try {
      // 获取所有截图记录
      final screenshotRecords = await database.getScreenshotsByAppId(
        application.id,
      );

      // 删除截图文件
      for (final record in screenshotRecords) {
        final file = File(record.path);
        if (await file.exists()) {
          await file.delete();
          logger.info('已删除截图文件: ${record.path}');
        }
      }

      // 从数据库中删除所有记录
      await database.deleteScreenshotsByAppId(application.id);

      // 刷新状态
      ref.invalidateSelf();

      logger.info(
        '清除截图数据成功: ${application.name}，删除数量: ${screenshotRecords.length}',
      );
    } catch (e, stackTrace) {
      logger.severe('清除截图数据失败', e, stackTrace);
      rethrow;
    }
  }

  /// 清除分析数据
  Future<void> clearAnalysisResults() async {
    try {
      // 这里应该清除实际的分析数据存储
      // 暂时只更新状态

      // 刷新状态
      ref.invalidateSelf();

      logger.info('清除分析数据成功');
    } catch (e, stackTrace) {
      logger.severe('清除分析数据失败', e, stackTrace);
      rethrow;
    }
  }

  /// 设置截图数据库监听器
  void _setupScreenshotListener() {
    // 取消之前的订阅
    _screenshotSubscription?.cancel();

    if (database.isar == null) {
      logger.warning('数据库未初始化，无法设置监听器');
      return;
    }

    // 监听截图记录集合的变化
    _screenshotSubscription = database.isar!.appScreenshotRecords
        .watchLazy()
        .listen(
          (_) {
            _onScreenshotRecordChanged();
          },
          onError: (error, stackTrace) {
            logger.severe('截图记录监听器错误: $error', error, stackTrace);
          },
        );

    // 在Provider销毁时清理订阅
    ref.onDispose(() {
      _screenshotSubscription?.cancel();
      _screenshotSubscription = null;
    });

    logger.info('截图数据库监听器已启动');
  }

  /// 处理截图记录变化事件
  Future<void> _onScreenshotRecordChanged() async {
    if (_currentAppId == null) {
      logger.warning('当前应用ID为空，跳过截图更新');
      return;
    }

    try {
      // 获取最新的截图记录
      final latestRecord = await _getLatestScreenshotRecord();

      // 检查最新记录是否属于当前应用
      if (latestRecord != null && latestRecord.appId == _currentAppId) {
        logger.info('检测到当前应用的新截图，刷新状态');

        // 刷新当前状态以加载新的截图列表
        await _refreshScreenshots();
      }
    } catch (e, stackTrace) {
      logger.severe('处理截图记录变化时出错: $e', e, stackTrace);
    }
  }

  /// 获取最新的截图记录
  Future<AppScreenshotRecord?> _getLatestScreenshotRecord() async {
    if (database.isar == null) return null;

    try {
      // 使用数据库中现有的查询方法，先获取任一应用的截图再过滤
      // 这里直接使用原生查询来获取所有记录
      final allScreenshotRecords = <AppScreenshotRecord>[];

      // 获取所有应用的截图记录（通过遍历所有应用）
      final allApps = await database.getAllApplications();
      for (final app in allApps) {
        final appScreenshots = await database.getScreenshotsByAppId(app.id);
        allScreenshotRecords.addAll(appScreenshots);
      }

      if (allScreenshotRecords.isEmpty) return null;

      // 按创建时间降序排列
      allScreenshotRecords.sort((a, b) => b.createAt.compareTo(a.createAt));

      return allScreenshotRecords.first;
    } catch (e, stackTrace) {
      logger.severe('获取最新截图记录失败: $e', e, stackTrace);
      return null;
    }
  }

  /// 刷新截图列表
  Future<void> _refreshScreenshots() async {
    if (_currentAppId == null) return;

    final currentState = state.value;
    if (currentState == null) return;

    try {
      // 重新加载截图列表
      final newScreenshots = await _loadScreenshots(_currentAppId!);

      // 更新状态
      final newState = currentState.copyWith(screenshots: newScreenshots);

      state = AsyncData(newState);
      logger.info('截图列表已更新，当前数量: ${newScreenshots.length}');
    } catch (e, stackTrace) {
      logger.severe('刷新截图列表失败: $e', e, stackTrace);
    }
  }
}
