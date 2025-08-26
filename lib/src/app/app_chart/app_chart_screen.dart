import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spy_on_your_work/src/app/app_chart/app_chart_notifier.dart';
import 'package:spy_on_your_work/src/app/app_chart/app_chart_state.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

class AppChartScreen extends ConsumerStatefulWidget {
  const AppChartScreen({super.key});

  @override
  ConsumerState<AppChartScreen> createState() => _AppChartScreenState();
}

class _AppChartScreenState extends ConsumerState<AppChartScreen> {
  @override
  Widget build(BuildContext context) {
    final chartAsyncValue = ref.watch(appChartNotifierProvider);
    final chartNotifier = ref.read(appChartNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '使用统计',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' · 应用分类使用时间分析',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () => context.go("/"),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF6366F1)),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: chartNotifier.refreshData,
        //     icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
        //   ),
        // ],
      ),
      body: chartAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorWidget(error.toString(), chartNotifier.refreshData),
        data: (chartState) => _buildContent(chartState, chartNotifier),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
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
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildContent(AppChartState state, AppChartNotifier notifier) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间维度选择器
          _buildTimeDimensionSelector(state, notifier),
          const SizedBox(height: 24),

          // 统计概览
          _buildStatsOverview(state, notifier),
          const SizedBox(height: 24),

          // 图表区域
          if (state.nonZeroCategories.isNotEmpty) ...[
            isNarrowScreen
                ? _buildNarrowScreenLayout(state, notifier)
                : _buildWideScreenLayout(state, notifier),
          ] else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildTimeDimensionSelector(
    AppChartState state,
    AppChartNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimeDimension.values.map((dimension) {
          final isSelected = state.selectedDimension == dimension;
          return Expanded(
            child: GestureDetector(
              onTap: () => notifier.setTimeDimension(dimension),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dimension.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsOverview(AppChartState state, AppChartNotifier notifier) {
    return Container(
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
          // 总时间统计
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '总使用时长',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notifier.formatDuration(state.totalUsage),
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 50, color: const Color(0xFFE5E7EB)),

          // 分类数量
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '活跃分类',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.nonZeroCategories.length} / ${IAppTypes.values.length}',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowScreenLayout(
    AppChartState state,
    AppChartNotifier notifier,
  ) {
    return Column(
      children: [
        _buildBarChart(state, notifier),
        const SizedBox(height: 24),
        _buildCategoryList(state, notifier),
      ],
    );
  }

  Widget _buildWideScreenLayout(
    AppChartState state,
    AppChartNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildBarChart(state, notifier)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildCategoryList(state, notifier)),
      ],
    );
  }

  Widget _buildBarChart(AppChartState state, AppChartNotifier notifier) {
    return Container(
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
          const Text(
            '分类使用时长',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(state),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        Colors.blueGrey.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = state.nonZeroCategories.keys.elementAt(
                        groupIndex,
                      );
                      final duration = state.nonZeroCategories[category]!;
                      return BarTooltipItem(
                        '${notifier.getCategoryDisplayName(category)}\n${notifier.formatDuration(duration)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < state.nonZeroCategories.length) {
                          final category = state.nonZeroCategories.keys
                              .elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              notifier.getCategoryDisplayName(category),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY(state) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(state, notifier),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    AppChartState state,
    AppChartNotifier notifier,
  ) {
    return state.nonZeroCategories.entries.map((entry) {
      final index = state.nonZeroCategories.keys.toList().indexOf(entry.key);
      final category = entry.key;
      final duration = entry.value;
      final colorHex = notifier.getCategoryColor(category);
      final color = Color(
        int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
      );

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: duration.inMinutes.toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY(AppChartState state) {
    if (state.nonZeroCategories.isEmpty) return 10;
    final maxMinutes = state.nonZeroCategories.values
        .map((duration) => duration.inMinutes)
        .reduce((a, b) => a > b ? a : b);
    return (maxMinutes * 1.2).roundToDouble();
  }

  Widget _buildCategoryList(AppChartState state, AppChartNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类详情',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...state.nonZeroCategories.entries.map((entry) {
          final category = entry.key;
          final duration = entry.value;
          final percentage = state.getCategoryPercentage(category);
          final colorHex = notifier.getCategoryColor(category);
          final color = Color(
            int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
          );

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
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notifier.getCategoryDisplayName(category),
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  notifier.formatDuration(duration),
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无使用数据',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始使用应用后将显示统计数据',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
