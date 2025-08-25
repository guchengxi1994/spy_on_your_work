import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';

/// 统计面板组件
class StatsPanel extends StatelessWidget {
  final ApplicationState appState;
  final bool isNarrowScreen;
  final bool isExpanded;
  final Animation<double> slideAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onToggle;
  final String Function(Duration) formatDuration;

  const StatsPanel({
    super.key,
    required this.appState,
    required this.isNarrowScreen,
    required this.isExpanded,
    required this.slideAnimation,
    required this.opacityAnimation,
    required this.onToggle,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: opacityAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // 背景模糊效果
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5.0 * opacityAnimation.value,
                  sigmaY: 5.0 * opacityAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.2 * opacityAnimation.value),
                ),
              ),
              // 点击空白区域关闭面板
              GestureDetector(
                onTap: onToggle,
                child: Container(color: Colors.transparent),
              ),
              // 统计面板
              AnimatedBuilder(
                animation: slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: isNarrowScreen
                        ? -200 + (200 * slideAnimation.value)
                        : (MediaQuery.of(context).size.height - 300) / 2,
                    right: isNarrowScreen
                        ? 0
                        : -320 + (320 * slideAnimation.value),
                    left: isNarrowScreen ? 0 : null,
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击事件传递
                      child: Container(
                        width: isNarrowScreen ? null : 320,
                        height: isNarrowScreen ? 200 : 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: _getBorderRadius(isNarrowScreen),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: isNarrowScreen
                                  ? const Offset(0, 4)
                                  : const Offset(-4, 0),
                            ),
                          ],
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// 获取统计面板的圆角设置
  BorderRadius _getBorderRadius(bool isNarrowScreen) {
    // 如果面板未展开，不需要圆角
    if (!isExpanded) {
      return BorderRadius.zero;
    }

    // 窄屏（<600px）：面板从顶部弹出，只有底部圆角
    if (isNarrowScreen) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    }

    // 宽屏（≥600px）：面板从右侧弹出，只有左侧圆角
    return const BorderRadius.only(
      topLeft: Radius.circular(24),
      bottomLeft: Radius.circular(24),
    );
  }

  /// 构建统计内容
  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '应用统计',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggle,
                icon: const Icon(Icons.close, color: Colors.grey),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsItem(
                    '工作应用',
                    '3 个',
                    '2.5h',
                    const Color(0xFF3B82F6),
                    Icons.work_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildStatsItem(
                    '娱乐应用',
                    '2 个',
                    '1.2h',
                    const Color(0xFF10B981),
                    Icons.games_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildStatsItem(
                    '学习应用',
                    '1 个',
                    '0.8h',
                    const Color(0xFF8B5CF6),
                    Icons.school_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildStatsItem(
                    '其他应用',
                    '${appState.applicationUsages.length} 个',
                    formatDuration(appState.totalUsageTime),
                    const Color(0xFF6B7280),
                    Icons.apps,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatsItem(
    String title,
    String count,
    String duration,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count · $duration',
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
