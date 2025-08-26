import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/app_detail/app_detail_state.dart';

class AnalysisResultsList extends StatelessWidget {
  final List<AnalysisResult> results;
  final VoidCallback onClearAll;

  const AnalysisResultsList({
    super.key,
    required this.results,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        if (results.isNotEmpty) _buildToolbar(),

        // 分析结果列表
        Expanded(
          child: results.isEmpty ? _buildEmptyState() : _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '共 ${results.length} 条分析结果',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 统计信息
          _buildStatsChip(),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('清空'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChip() {
    final averageConfidence = results.isEmpty
        ? 0.0
        : results.map((r) => r.confidence).reduce((a, b) => a + b) /
              results.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF0EA5E9), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 12, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 4),
          Text(
            '平均置信度 ${(averageConfidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFF0EA5E9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultItem(results[index], index);
      },
    );
  }

  Widget _buildResultItem(AnalysisResult result, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息
          Row(
            children: [
              // 分类标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    result.category,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.category,
                  style: TextStyle(
                    color: _getCategoryColor(result.category),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // 置信度
              _buildConfidenceIndicator(result.confidence),
            ],
          ),

          const SizedBox(height: 12),

          // 分析内容
          Text(
            result.content,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // 元数据和时间
          Row(
            children: [
              // 关键词标签
              if (result.metadata['keywords'] != null)
                ..._buildKeywordChips(result.metadata['keywords']),
              const Spacer(),
              // 时间戳
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(result.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).round();
    Color color;

    if (confidence >= 0.8) {
      color = const Color(0xFF10B981); // 绿色 - 高置信度
    } else if (confidence >= 0.6) {
      color = const Color(0xFFF59E0B); // 橙色 - 中置信度
    } else {
      color = const Color(0xFFEF4444); // 红色 - 低置信度
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: confidence,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$percentage%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildKeywordChips(dynamic keywords) {
    if (keywords is! List) return [];

    return keywords.take(3).map<Widget>((keyword) {
      return Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          keyword.toString(),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无分析结果',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '启用内容分析功能后，系统会智能分析应用内容并生成报告',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '工作内容':
        return const Color(0xFF3B82F6);
      case '开发工作':
        return const Color(0xFF10B981);
      case '学习资料':
        return const Color(0xFF8B5CF6);
      case '娱乐内容':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
