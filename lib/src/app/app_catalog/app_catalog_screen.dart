import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:spy_on_your_work/src/app/application/application_notifier.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/app/app_catalog/app_catalog_notifier_simple.dart';
import 'package:spy_on_your_work/src/app/app_catalog/components/optimized_category_card.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

class AppCatalogScreen extends ConsumerStatefulWidget {
  const AppCatalogScreen({super.key});

  @override
  ConsumerState<AppCatalogScreen> createState() => _AppCatalogScreenState();
}

class _AppCatalogScreenState extends ConsumerState<AppCatalogScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时更新未分类应用列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUncategorizedApps();
    });
  }

  void _updateUncategorizedApps() {
    final applicationState = ref.read(applicationNotifierProvider);
    final catalogNotifier = ref.read(appCatalogNotifierProvider.notifier);
    // 将 Map 转换为 List
    final appsList = applicationState.applicationUsages.values.toList();
    catalogNotifier.updateUncategorizedApps(appsList);
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(appCatalogNotifierProvider);
    final applicationState = ref.watch(applicationNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '应用分类',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '  ·  拖拽应用进行分类管理',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1F2937)),
            onPressed: () {
              ref.read(appCatalogNotifierProvider.notifier).refresh();
              _updateUncategorizedApps();
            },
          ),
        ],
      ),
      body: catalogState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : catalogState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    catalogState.error!,
                    style: TextStyle(color: Colors.red[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(appCatalogNotifierProvider.notifier).refresh();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : _buildCatalogContent(catalogState, applicationState),
    );
  }

  Widget _buildCatalogContent(
    AppCatalogState catalogState,
    ApplicationState applicationState,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800; // 宽屏判断
    final isCompactMode = screenWidth < 600; // 紧凑模式判断
    final isMediumScreen = screenWidth >= 600 && screenWidth <= 800; // 中等屏幕

    if (isWideScreen) {
      // 宽屏：左右布局
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：统计和未分类应用
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 统计信息
                    _buildStatsSection(catalogState, applicationState),
                    const SizedBox(height: 24),
                    // 未分类应用区域（unknown分类的应用）
                    if (catalogState
                            .categorizedApps[IAppTypes.unknown]
                            ?.isNotEmpty ==
                        true)
                      DragSourceArea(
                        apps: catalogState.categorizedApps[IAppTypes.unknown]!,
                        title: '待分类应用',
                        icon: Icons.inbox_outlined,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 右侧：分类卡片
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: _buildCategoryGrid(
                catalogState,
                isCompactMode,
                isMediumScreen,
              ),
            ),
          ),
        ],
      );
    } else {
      // 窄屏：垂直布局
      return CustomScrollView(
        slivers: [
          // 统计信息
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _buildStatsSection(catalogState, applicationState),
            ),
          ),
          // 未分类应用区域
          if (catalogState.categorizedApps[IAppTypes.unknown]?.isNotEmpty ==
              true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DragSourceArea(
                  apps: catalogState.categorizedApps[IAppTypes.unknown]!,
                  title: '待分类应用',
                  icon: Icons.inbox_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          // 分类卡片网格
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: _buildCategoryGridSliver(
              catalogState,
              isCompactMode,
              isMediumScreen,
            ),
          ),
          // 底部间距
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      );
    }
  }

  Widget _buildStatsSection(
    AppCatalogState catalogState,
    ApplicationState applicationState,
  ) {
    // 不包括 unknown 分类的已分类应用数量
    final categorizedCount = catalogState.categorizedApps.entries
        .where((entry) => entry.key != IAppTypes.unknown)
        .fold(0, (sum, entry) => sum + entry.value.length);

    final unknownCount =
        catalogState.categorizedApps[IAppTypes.unknown]?.length ?? 0;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              '已分类',
              '$categorizedCount',
              Icons.category_outlined,
              const Color(0xFF10B981),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              '待分类',
              '$unknownCount',
              Icons.inbox_outlined,
              const Color(0xFF6B7280),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              '总计',
              '${applicationState.applicationUsages.length}',
              Icons.apps_outlined,
              const Color(0xFF6366F1),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              '分类数',
              '${IAppTypes.values.where((t) => t != IAppTypes.unknown).length}',
              Icons.widgets_outlined,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(
    AppCatalogState catalogState,
    bool isCompactMode,
    bool isMediumScreen,
  ) {
    // 排除 unknown 分类
    final categories = IAppTypes.values
        .where((type) => type != IAppTypes.unknown)
        .toList();

    // 根据屏幕尺寸确定列数
    int columnCount;
    if (isCompactMode) {
      columnCount = 1; // 窄屏：单列
    } else if (isMediumScreen) {
      columnCount = 1; // 中屏：单列，避免挤压
    } else {
      columnCount = 2; // 宽屏：双列
    }

    // 计算行数
    final rowCount = (categories.length / columnCount).ceil();

    return LayoutGrid(
      columnSizes: List.generate(
        columnCount,
        (index) => 1.fr, // 等宽列
      ),
      rowSizes: List.generate(
        rowCount,
        (index) => isCompactMode
            ? const FixedTrackSize(80) // 紧凑模式：固定80px高度
            : isMediumScreen
            ? const FixedTrackSize(100) // 中等屏幕：固定100px高度
            : IntrinsicContentTrackSize(), // 宽屏：自适应内容高度
      ),
      columnGap: 8,
      rowGap: 8,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final apps = catalogState.categorizedApps[type] ?? [];

        // 计算网格位置
        final column = index % columnCount;
        final row = index ~/ columnCount;

        return OptimizedCategoryCard(
          type: type,
          apps: apps,
          isCompactMode: isCompactMode || isMediumScreen,
          onAppMoved: (app, targetType) {
            ref
                .read(appCatalogNotifierProvider.notifier)
                .moveAppToCategory(app, targetType);
            // 更新未分类应用列表
            Future.delayed(const Duration(milliseconds: 500), () {
              _updateUncategorizedApps();
            });
          },
        ).withGridPlacement(columnStart: column, rowStart: row);
      }).toList(),
    );
  }

  Widget _buildCategoryGridSliver(
    AppCatalogState catalogState,
    bool isCompactMode,
    bool isMediumScreen,
  ) {
    // 直接使用LayoutGrid并用SliverToBoxAdapter包装
    return SliverToBoxAdapter(
      child: _buildCategoryGrid(catalogState, isCompactMode, isMediumScreen),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
