import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spy_on_your_work/src/app/application/application_notifier.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/app/app_catalog/app_catalog_notifier_simple.dart';
import 'package:spy_on_your_work/src/app/app_catalog/components/category_card.dart';
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
        title: const Text(
          '应用分类',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
    return CustomScrollView(
      slivers: [
        // 页面标题和统计
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '应用分类管理',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '拖拽应用到不同分类中进行管理',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 16),
                // 统计信息
                Row(
                  children: [
                    _buildStatCard(
                      '已分类',
                      '${catalogState.totalCategorizedCount}',
                      Icons.category_outlined,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '未分类',
                      '${catalogState.uncategorizedApps.length}',
                      Icons.inbox_outlined,
                      const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '总计',
                      '${applicationState.applicationUsages.length}',
                      Icons.apps_outlined,
                      const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 未分类应用区域
        if (catalogState.uncategorizedApps.isNotEmpty)
          SliverToBoxAdapter(
            child: UncategorizedAppsArea(apps: catalogState.uncategorizedApps),
          ),
        // 分类卡片网格
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final type = IAppTypes.values[index];
              final apps = catalogState.categorizedApps[type] ?? [];
              return CategoryCard(
                type: type,
                apps: apps,
                onAppMoved: (app, targetType) {
                  ref
                      .read(appCatalogNotifierProvider.notifier)
                      .moveAppToCategory(app, targetType);
                  // 更新未分类应用列表
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _updateUncategorizedApps();
                  });
                },
              );
            }, childCount: IAppTypes.values.length),
          ),
        ),
        // 底部间距
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
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
              color: Colors.black.withOpacity(0.05),
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
