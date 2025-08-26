import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spy_on_your_work/src/app/app_detail/app_detail_notifier.dart';
import 'package:spy_on_your_work/src/app/app_detail/app_detail_state.dart';
import 'package:spy_on_your_work/src/app/app_detail/components/screenshot_gallery.dart';
import 'package:spy_on_your_work/src/app/app_detail/components/analysis_results_list.dart';
import 'package:spy_on_your_work/src/app/app_detail/components/app_config_section.dart';
import 'package:spy_on_your_work/src/app/application/components/cached_app_icon.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

class AppDetailScreen extends ConsumerStatefulWidget {
  final String appName;

  const AppDetailScreen({super.key, required this.appName});

  @override
  ConsumerState<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends ConsumerState<AppDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appDetailAsyncValue = ref.watch(
      appDetailNotifierProvider(widget.appName),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: widget.appName,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' · 应用详细配置',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () => context.go("/"),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       ref
        //           .read(appDetailNotifierProvider(widget.appName).notifier)
        //           .refresh();
        //     },
        //     icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
        //   ),
        // ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF1F2937),
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(text: '基本配置', icon: Icon(Icons.settings)),
            Tab(text: '截图记录', icon: Icon(Icons.photo_library)),
            Tab(text: '分析结果', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: appDetailAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
        data: (state) => _buildContent(state),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(appDetailNotifierProvider(widget.appName).notifier)
                  .refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppDetailState state) {
    if (state.application == null) {
      return const Center(child: Text('应用信息不存在'));
    }

    return Column(
      children: [
        // 应用基本信息卡片
        _buildAppInfoCard(state.application!),

        // Tab页面内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 基本配置页面
              AppConfigSection(
                application: state.application!,
                onConfigChanged: (screenshotEnabled, analysisEnabled) {
                  ref
                      .read(appDetailNotifierProvider(widget.appName).notifier)
                      .updateApplicationConfig(
                        screenshotWhenUsing: screenshotEnabled,
                        analyseWhenUsing: analysisEnabled,
                      );
                },
              ),

              // 截图记录页面
              ScreenshotGallery(
                screenshots: state.screenshots,
                onClearAll: () {
                  _showClearConfirmDialog(
                    '清除所有截图',
                    '确定要清除所有截图记录吗？此操作不可恢复。',
                    () {
                      ref
                          .read(
                            appDetailNotifierProvider(widget.appName).notifier,
                          )
                          .clearScreenshots();
                    },
                  );
                },
              ),

              // 分析结果页面
              AnalysisResultsList(
                results: state.analysisResults,
                onClearAll: () {
                  _showClearConfirmDialog(
                    '清除所有分析结果',
                    '确定要清除所有内容分析结果吗？此操作不可恢复。',
                    () {
                      ref
                          .read(
                            appDetailNotifierProvider(widget.appName).notifier,
                          )
                          .clearAnalysisResults();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard(IApplication application) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 应用图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: application.icon != null
                ? CachedAppIcon(iconData: application.icon, size: 30)
                : const Icon(Icons.apps, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          // 应用信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.name,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '分类: ${_getCategoryDisplayName(application.type)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '路径: ${application.path}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 状态指示器
          Column(
            children: [
              _buildStatusIndicator(
                '截图',
                application.screenshotWhenUsing,
                Icons.camera_alt,
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(
                '分析',
                application.analyseWhenUsing,
                Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool enabled, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xFF10B981) : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: enabled ? const Color(0xFF10B981) : Colors.grey[400],
            fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getCategoryDisplayName(IAppTypes type) {
    switch (type) {
      case IAppTypes.work:
        return '工作';
      case IAppTypes.study:
        return '学习';
      case IAppTypes.joy:
        return '娱乐';
      case IAppTypes.others:
        return '其他';
      case IAppTypes.unknown:
        return '未分类';
    }
  }

  void _showClearConfirmDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
