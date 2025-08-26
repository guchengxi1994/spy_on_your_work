import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/common/logger.dart';

/// 应用分类状态
class AppCatalogState {
  final Map<IAppTypes, List<ApplicationUsage>> categorizedApps;
  final List<ApplicationUsage> uncategorizedApps;
  final bool isLoading;
  final String? error;

  const AppCatalogState({
    this.categorizedApps = const {},
    this.uncategorizedApps = const [],
    this.isLoading = false,
    this.error,
  });

  AppCatalogState copyWith({
    Map<IAppTypes, List<ApplicationUsage>>? categorizedApps,
    List<ApplicationUsage>? uncategorizedApps,
    bool? isLoading,
    String? error,
  }) {
    return AppCatalogState(
      categorizedApps: categorizedApps ?? this.categorizedApps,
      uncategorizedApps: uncategorizedApps ?? this.uncategorizedApps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 获取指定分类的应用数量
  int getCategoryCount(IAppTypes type) {
    return categorizedApps[type]?.length ?? 0;
  }

  /// 获取所有已分类的应用总数
  int get totalCategorizedCount {
    return categorizedApps.values.fold(0, (sum, apps) => sum + apps.length);
  }
}

/// 应用分类 Notifier
class AppCatalogNotifier extends StateNotifier<AppCatalogState> {
  final IsarDatabase _database;
  bool _isInitialized = false;

  AppCatalogNotifier(this._database) : super(const AppCatalogState()) {
    _initialize();
  }

  /// 初始化数据
  Future<void> _initialize() async {
    if (_isInitialized) return;

    state = state.copyWith(isLoading: true);

    try {
      await _loadCategorizedApps();
      _isInitialized = true;
    } catch (e) {
      logger.severe('Failed to initialize app catalog: $e');
      state = state.copyWith(isLoading: false, error: '初始化失败: $e');
    }
  }

  /// 加载已分类的应用
  Future<void> _loadCategorizedApps() async {
    try {
      // 获取所有已分类的应用
      final allIApps = await _database.isar!.iApplications.where().findAll();

      // 按分类分组
      final Map<IAppTypes, List<ApplicationUsage>> categorizedApps = {};
      for (final type in IAppTypes.values) {
        categorizedApps[type] = [];
      }

      // 将 IApplication 转换为 ApplicationUsage 并分类
      for (final iApp in allIApps) {
        // 这里需要根据实际情况构造 ApplicationUsage
        // 暂时创建一个基础的 ApplicationUsage 对象
        final appUsage = ApplicationUsage(
          name: iApp.name,
          title: iApp.name,
          path: iApp.path,
          icon: iApp.icon,
          totalUsage: Duration.zero, // 可以后续从使用记录中计算
          sessionCount: 0, // 可以后续从使用记录中计算
          lastUsed: DateTime.fromMillisecondsSinceEpoch(iApp.createAt),
        );

        categorizedApps[iApp.type]?.add(appUsage);
      }

      state = state.copyWith(
        categorizedApps: categorizedApps,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      logger.severe('Failed to load categorized apps: $e');
      state = state.copyWith(isLoading: false, error: '加载分类失败: $e');
    }
  }

  /// 将应用移动到指定分类
  Future<void> moveAppToCategory(
    ApplicationUsage app,
    IAppTypes newType,
  ) async {
    try {
      // 查找或创建应用记录
      final existingApp = await _database.isar!.iApplications
          .filter()
          .nameEqualTo(app.name)
          .findFirst();

      if (existingApp != null) {
        // 更新现有应用的分类
        await _database.isar!.writeTxn(() async {
          existingApp.type = newType;
          await _database.isar!.iApplications.put(existingApp);
        });
      } else {
        // 创建新的应用记录
        final newIApp = IApplication()
          ..name = app.name
          ..path = app.path
          ..icon = app.icon
          ..type = newType;

        await _database.isar!.writeTxn(() async {
          await _database.isar!.iApplications.put(newIApp);
        });
      }

      // 重新加载数据
      await _loadCategorizedApps();

      logger.info('Moved app ${app.name} to category ${newType.name}');
    } catch (e) {
      logger.severe('Failed to move app to category: $e');
      state = state.copyWith(error: '移动应用失败: $e');
    }
  }

  /// 从分类中移除应用
  Future<void> removeAppFromCategory(ApplicationUsage app) async {
    try {
      final existingApp = await _database.isar!.iApplications
          .filter()
          .nameEqualTo(app.name)
          .findFirst();

      if (existingApp != null) {
        await _database.isar!.writeTxn(() async {
          await _database.isar!.iApplications.delete(existingApp.id);
        });

        // 重新加载数据
        await _loadCategorizedApps();

        logger.info('Removed app ${app.name} from category');
      }
    } catch (e) {
      logger.severe('Failed to remove app from category: $e');
      state = state.copyWith(error: '移除应用失败: $e');
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadCategorizedApps();
  }

  /// 根据当前应用使用情况更新未分类应用列表
  void updateUncategorizedApps(List<ApplicationUsage> allApps) {
    final categorizedAppNames = <String>{};
    for (final apps in state.categorizedApps.values) {
      categorizedAppNames.addAll(apps.map((app) => app.name));
    }

    final uncategorized = allApps
        .where((app) => !categorizedAppNames.contains(app.name))
        .toList();

    state = state.copyWith(uncategorizedApps: uncategorized);
  }
}

/// 应用分类 Provider
final appCatalogNotifierProvider =
    StateNotifierProvider<AppCatalogNotifier, AppCatalogState>((ref) {
      return AppCatalogNotifier(IsarDatabase());
    });

/// 分类显示名称映射
const Map<IAppTypes, String> categoryDisplayNames = {
  IAppTypes.work: '工作',
  IAppTypes.study: '学习',
  IAppTypes.joy: '娱乐',
  IAppTypes.others: '其他',
};

/// 分类图标映射
final Map<IAppTypes, IconData> categoryIcons = {
  IAppTypes.work: Icons.work_outline,
  IAppTypes.study: Icons.school_outlined,
  IAppTypes.joy: Icons.sports_esports_outlined,
  IAppTypes.others: Icons.apps_outlined,
};

/// 分类颜色映射
final Map<IAppTypes, Color> categoryColors = {
  IAppTypes.work: const Color(0xFF3B82F6), // 蓝色
  IAppTypes.study: const Color(0xFF10B981), // 绿色
  IAppTypes.joy: const Color(0xFFF59E0B), // 橙色
  IAppTypes.others: const Color(0xFF6B7280), // 灰色
};
