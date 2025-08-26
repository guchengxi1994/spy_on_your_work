import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // ignore: unused_field
  final IsarDatabase _database;

  // 内存中的分类存储（临时解决方案）
  final Map<String, IAppTypes> _appCategories = {};

  AppCatalogNotifier(this._database) : super(const AppCatalogState()) {
    _initialize();
  }

  /// 初始化数据
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      await _loadCategorizedApps();
    } catch (e) {
      logger.severe('Failed to initialize app catalog: $e');
      state = state.copyWith(isLoading: false, error: '初始化失败: $e');
    }
  }

  /// 加载已分类的应用
  Future<void> _loadCategorizedApps() async {
    try {
      // 临时实现：初始化空的分类
      final Map<IAppTypes, List<ApplicationUsage>> categorizedApps = {};
      for (final type in IAppTypes.values) {
        categorizedApps[type] = [];
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
      // 在内存中记录分类
      _appCategories[app.name] = newType;

      // 更新状态
      final Map<IAppTypes, List<ApplicationUsage>> newCategorizedApps =
          Map.from(state.categorizedApps);

      // 从所有分类中移除该应用
      for (final type in IAppTypes.values) {
        newCategorizedApps[type] = newCategorizedApps[type]!
            .where((a) => a.name != app.name)
            .toList();
      }

      // 添加到新分类
      newCategorizedApps[newType] = [...newCategorizedApps[newType]!, app];

      state = state.copyWith(categorizedApps: newCategorizedApps);

      logger.info('Moved app ${app.name} to category ${newType.name}');
    } catch (e) {
      logger.severe('Failed to move app to category: $e');
      state = state.copyWith(error: '移动应用失败: $e');
    }
  }

  /// 从分类中移除应用
  Future<void> removeAppFromCategory(ApplicationUsage app) async {
    try {
      // 从内存中移除分类记录
      _appCategories.remove(app.name);

      // 更新状态
      final Map<IAppTypes, List<ApplicationUsage>> newCategorizedApps =
          Map.from(state.categorizedApps);

      // 从所有分类中移除该应用
      for (final type in IAppTypes.values) {
        newCategorizedApps[type] = newCategorizedApps[type]!
            .where((a) => a.name != app.name)
            .toList();
      }

      state = state.copyWith(categorizedApps: newCategorizedApps);

      logger.info('Removed app ${app.name} from category');
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
    // 不包括 unknown 分类，因为这是默认的未分类
    for (final entry in state.categorizedApps.entries) {
      if (entry.key != IAppTypes.unknown) {
        categorizedAppNames.addAll(entry.value.map((app) => app.name));
      }
    }

    // 所有未分类的应用都放入 unknown 分类
    final uncategorized = allApps
        .where((app) => !categorizedAppNames.contains(app.name))
        .toList();

    // 更新 unknown 分类
    final Map<IAppTypes, List<ApplicationUsage>> newCategorizedApps = Map.from(
      state.categorizedApps,
    );
    newCategorizedApps[IAppTypes.unknown] = uncategorized;

    state = state.copyWith(
      categorizedApps: newCategorizedApps,
      uncategorizedApps: [], // 不再需要单独的未分类列表
    );
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
  IAppTypes.unknown: '未分类',
};

/// 分类图标映射
final Map<IAppTypes, IconData> categoryIcons = {
  IAppTypes.work: Icons.work_outline,
  IAppTypes.study: Icons.school_outlined,
  IAppTypes.joy: Icons.sports_esports_outlined,
  IAppTypes.others: Icons.apps_outlined,
  IAppTypes.unknown: Icons.help_outline,
};

/// 分类颜色映射
final Map<IAppTypes, Color> categoryColors = {
  IAppTypes.work: const Color(0xFF3B82F6), // 蓝色
  IAppTypes.study: const Color(0xFF10B981), // 绿色
  IAppTypes.joy: const Color(0xFFF59E0B), // 橙色
  IAppTypes.others: const Color(0xFF6B7280), // 灰色
  IAppTypes.unknown: const Color(0xFF9CA3AF), // 浅灰色
};
