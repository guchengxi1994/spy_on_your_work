import 'package:flutter/material.dart';

/// 统计切换按钮组件
class StatsToggleButton extends StatelessWidget {
  final bool isNarrowScreen;
  final bool isExpanded;
  final Animation<double> slideAnimation;
  final VoidCallback onToggle;

  const StatsToggleButton({
    super.key,
    required this.isNarrowScreen,
    required this.isExpanded,
    required this.slideAnimation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, child) {
        return Positioned(
          // 窄屏时：跟随面板动画从顶部向下移动
          top: isNarrowScreen
              ? (10 + (200 - 34) * slideAnimation.value) // 从顶部跟随面板向下移动
              : (MediaQuery.of(context).size.height - 300) / 2 + 126,
          bottom: null,
          // 宽屏时：跟随面板动画从右侧向左移动
          left: !isNarrowScreen
              ? (MediaQuery.of(context).size.width -
                    320 * slideAnimation.value -
                    24) // 跟随面板滑动
              : null,
          right: isNarrowScreen ? 10 : null,
          child: GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // 根据弹出方向调整圆角
                borderRadius: isExpanded && !isNarrowScreen
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isExpanded
                    ? Icons.close
                    : (isNarrowScreen ? Icons.expand_more : Icons.chevron_left),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
