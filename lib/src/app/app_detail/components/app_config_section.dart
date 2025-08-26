import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

class AppConfigSection extends StatelessWidget {
  final IApplication application;
  final Function(bool screenshotEnabled, bool analysisEnabled) onConfigChanged;

  const AppConfigSection({
    super.key,
    required this.application,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 功能配置区域
          _buildSectionCard(
            title: '功能配置',
            icon: Icons.settings,
            children: [
              _buildConfigItem(
                title: '使用时截图',
                subtitle: '启用后会在使用此应用时自动截图',
                value: application.screenshotWhenUsing,
                onChanged: (value) {
                  onConfigChanged(value, application.analyseWhenUsing);
                },
                icon: Icons.camera_alt,
              ),
              const Divider(height: 32),
              _buildConfigItem(
                title: '内容分析',
                subtitle: '启用后会对应用内容进行智能分析',
                value: application.analyseWhenUsing,
                onChanged: (value) {
                  onConfigChanged(application.screenshotWhenUsing, value);
                },
                icon: Icons.analytics,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 应用详细信息
          _buildSectionCard(
            title: '应用信息',
            icon: Icons.info,
            children: [
              _buildInfoItem('应用名称', application.name),
              _buildInfoItem('文件路径', application.path),
              _buildInfoItem('分类类型', _getCategoryDisplayName(application.type)),
              _buildInfoItem(
                '创建时间',
                _formatDateTime(
                  DateTime.fromMillisecondsSinceEpoch(application.createAt),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 配置说明
          _buildSectionCard(
            title: '配置说明',
            icon: Icons.help_outline,
            children: [
              _buildHelpItem(
                '截图功能',
                '启用后，系统会在您使用该应用时定期自动截图，用于记录使用情况。'
                    '截图会保存在本地，不会上传到任何服务器。',
                Icons.camera_alt,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '内容分析',
                '启用后，系统会对应用的窗口内容进行智能分析，识别您正在进行的活动类型。'
                    '分析结果仅用于统计和分类，不会记录具体的私人信息。',
                Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildConfigItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
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
          const SizedBox(width: 16),
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

  Widget _buildHelpItem(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF6B7280), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
