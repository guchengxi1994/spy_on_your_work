import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/app/application/components/cached_app_icon.dart';

/// 应用详情对话框组件
class AppDetailDialog extends StatelessWidget {
  final ApplicationUsage app;
  final double percentage;

  const AppDetailDialog({
    super.key,
    required this.app,
    required this.percentage,
  });

  /// 显示应用详情对话框
  static void show(
    BuildContext context,
    ApplicationUsage app,
    double percentage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AppDetailDialog(app: app, percentage: percentage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CachedAppIcon(iconData: app.icon, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  app.title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailRow('使用时间', _formatDuration(app.totalUsage)),
          _buildDetailRow('使用次数', '${app.sessionCount} 次'),
          _buildDetailRow('最后使用', _formatLastUsed(app.lastUsed)),
          _buildDetailRow('使用占比', '${(percentage * 100).toStringAsFixed(1)}%'),
          _buildDetailRow('文件路径', app.path),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
