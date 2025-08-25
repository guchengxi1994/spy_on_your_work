import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/app/application/components/cached_app_icon.dart';
import 'package:spy_on_your_work/src/app/application/components/info_chip.dart';

/// 应用列表项组件，减少重建
class ApplicationListItem extends StatelessWidget {
  final ApplicationUsage app;
  final int index;
  final bool isCurrentApp;
  final double percentage;
  final VoidCallback onTap;

  const ApplicationListItem({
    super.key,
    required this.app,
    required this.index,
    required this.isCurrentApp,
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 排名显示
    String rankIcon = '';
    Color rankColor = Colors.grey;
    if (index == 0) {
      rankIcon = '🥇';
      rankColor = const Color(0xFFFFD700);
    } else if (index == 1) {
      rankIcon = '🥈';
      rankColor = const Color(0xFFC0C0C0);
    } else if (index == 2) {
      rankIcon = '🥉';
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankIcon = '${index + 1}';
      rankColor = Colors.grey[600]!;
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentApp
                ? const Color(0xFF6366F1).withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading - 应用图标和排名
              Stack(
                children: [
                  CachedAppIcon(iconData: app.icon, isCurrentApp: isCurrentApp),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: rankColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        rankIcon,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content - 应用信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row - 应用名称和当前标识
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.name,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentApp)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '当前',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Subtitle - 应用标题
                    Text(
                      app.title,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Progress bar - 进度条
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: percentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Info chips - 信息标签
                    Wrap(
                      spacing: 8,
                      children: [
                        InfoChip(
                          icon: Icons.access_time,
                          text: _formatDuration(app.totalUsage),
                          color: Colors.blue,
                        ),
                        InfoChip(
                          icon: Icons.launch,
                          text: '${app.sessionCount} 次',
                          color: Colors.green,
                        ),
                        InfoChip(
                          icon: Icons.schedule,
                          text: _formatLastUsed(app.lastUsed),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  static String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}
