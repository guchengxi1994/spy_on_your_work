import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spy_on_your_work/src/app/app_calendar/app_calendar_notifier.dart';
import 'package:spy_on_your_work/src/app/app_calendar/app_calendar_state.dart';
import 'package:spy_on_your_work/src/app/app_calendar/components/month_view_widget.dart';
import 'package:spy_on_your_work/src/app/app_calendar/components/day_view_widget.dart';

/// 应用使用统计日历视图页面
class AppCalendarScreen extends ConsumerStatefulWidget {
  const AppCalendarScreen({super.key});

  @override
  ConsumerState<AppCalendarScreen> createState() => _AppCalendarScreenState();
}

class _AppCalendarScreenState extends ConsumerState<AppCalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(appCalendarNotifierProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: calendarState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(context, error),
        data: (state) => _buildCalendarContent(context, state),
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final calendarState = ref.watch(appCalendarNotifierProvider);
    final state = calendarState.valueOrNull;

    return AppBar(
      title: Text(state?.viewMode == CalendarViewMode.day ? '日视图' : '应用使用日历'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: IconButton(
        onPressed: () => context.go("/"),
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
      ),
      actions: [
        // 视图切换按钮
        if (state != null) ..._buildViewModeActions(context, state),
        // 刷新按钮
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await ref.read(appCalendarNotifierProvider.notifier).refreshData();
          },
        ),
      ],
    );
  }

  /// 构建视图模式操作按钮
  List<Widget> _buildViewModeActions(
    BuildContext context,
    AppCalendarState state,
  ) {
    if (state.viewMode == CalendarViewMode.day) {
      return [
        IconButton(
          icon: const Icon(Icons.calendar_view_month),
          tooltip: '返回月视图',
          onPressed: () async {
            await ref
                .read(appCalendarNotifierProvider.notifier)
                .goToMonthView();
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.today),
          tooltip: '查看今日详情',
          onPressed: () async {
            await ref
                .read(appCalendarNotifierProvider.notifier)
                .goToDayView(DateTime.now());
          },
        ),
      ];
    }
  }

  /// 构建错误组件
  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(appCalendarNotifierProvider.notifier)
                  .refreshData();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建日历内容
  Widget _buildCalendarContent(BuildContext context, AppCalendarState state) {
    switch (state.viewMode) {
      case CalendarViewMode.month:
        return _buildMonthView(context, state);
      case CalendarViewMode.day:
        return _buildDayView(context, state);
    }
  }

  /// 构建月视图
  Widget _buildMonthView(BuildContext context, AppCalendarState state) {
    return MonthViewWidget(
      state: state,
      onDateTap: (date) async {
        // 点击日期跳转到日视图
        await ref.read(appCalendarNotifierProvider.notifier).goToDayView(date);
      },
      onMonthChange: (month) async {
        await ref.read(appCalendarNotifierProvider.notifier).changeMonth(month);
      },
    );
  }

  /// 构建日视图
  Widget _buildDayView(BuildContext context, AppCalendarState state) {
    return DayViewWidget(
      selectedDate: state.selectedDate,
      timeSlots: state.selectedDateTimeSlots,
      onBackToMonth: () async {
        await ref.read(appCalendarNotifierProvider.notifier).goToMonthView();
      },
    );
  }
}
