import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spy_on_your_work/src/app/app_catalog/app_catalog_screen.dart';
import 'package:spy_on_your_work/src/app/app_chart/app_chart_screen.dart';
import 'package:spy_on_your_work/src/app/app_detail/app_detail_screen.dart';
import 'package:spy_on_your_work/src/app/application/application_screen.dart';
import 'package:spy_on_your_work/src/app/application/components/stats_panel.dart';
import 'package:spy_on_your_work/src/app/application/components/stats_toggle_button.dart';
import 'package:spy_on_your_work/src/app/application/components/cached_app_icon.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return GlobalAppWrapper(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const ApplicationScreen();
          },
        ),
        GoRoute(
          path: '/catalog',
          builder: (BuildContext context, GoRouterState state) {
            return const AppCatalogScreen();
          },
        ),
        GoRoute(
          path: '/chart',
          builder: (BuildContext context, GoRouterState state) {
            return const AppChartScreen();
          },
        ),
        GoRoute(
          path: '/app-detail/:appName',
          builder: (BuildContext context, GoRouterState state) {
            final appName = state.pathParameters['appName']!;
            return AppDetailScreen(appName: appName);
          },
        ),
      ],
    ),
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: router,
      title: "FocusTrack",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 128, 180, 217),
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 全局应用包装器，提供统计面板功能
class GlobalAppWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalAppWrapper({super.key, required this.child});

  @override
  ConsumerState<GlobalAppWrapper> createState() => _GlobalAppWrapperState();
}

class _GlobalAppWrapperState extends ConsumerState<GlobalAppWrapper>
    with TickerProviderStateMixin {
  // 功能面板状态
  bool _isStatsExpanded = false;
  late AnimationController _statsAnimationController;
  late Animation<double> _statsSlideAnimation;
  late Animation<double> _statsOpacityAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化统计面板动画
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statsSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statsAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _statsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statsAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _statsAnimationController.dispose();
    // 清理图标缓存，防止内存泄漏
    if (IconCacheManager.cacheSize > 100) {
      IconCacheManager.clearCache();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;

    return Stack(
      children: [
        // 主要内容（路由页面）
        widget.child,
        // 统计面板
        StatsPanel(
          isNarrowScreen: isNarrowScreen,
          isExpanded: _isStatsExpanded,
          slideAnimation: _statsSlideAnimation,
          opacityAnimation: _statsOpacityAnimation,
          onToggle: _toggleStatsPanel,
          formatDuration: _formatDuration,
        ),
        // 统计按钮
        StatsToggleButton(
          isNarrowScreen: isNarrowScreen,
          isExpanded: _isStatsExpanded,
          slideAnimation: _statsSlideAnimation,
          onToggle: _toggleStatsPanel,
        ),
      ],
    );
  }

  /// 切换统计面板显示状态
  void _toggleStatsPanel() {
    setState(() {
      _isStatsExpanded = !_isStatsExpanded;
    });

    if (_isStatsExpanded) {
      _statsAnimationController.forward();
    } else {
      _statsAnimationController.reverse();
    }
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
}
