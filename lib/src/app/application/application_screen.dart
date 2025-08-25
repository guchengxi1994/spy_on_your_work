import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_on_your_work/src/app/application/application_notifier.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';

/// 图标缓存管理器
class IconCacheManager {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? getDecodedIcon(String? base64Data) {
    if (base64Data == null) return null;

    // 如果缓存中存在，直接返回
    if (_cache.containsKey(base64Data)) {
      return _cache[base64Data];
    }

    // 解码并缓存
    try {
      final decoded = base64Decode(base64Data);
      _cache[base64Data] = decoded;
      return decoded;
    } catch (e) {
      logger.warning('Failed to decode icon: $e');
      return null;
    }
  }

  static void clearCache() {
    _cache.clear();
  }

  static int get cacheSize => _cache.length;
}

/// 缓存应用图标组件，避免重复解码
class CachedAppIcon extends StatelessWidget {
  final String? iconData;
  final double size;
  final bool isCurrentApp;

  const CachedAppIcon({
    super.key,
    required this.iconData,
    this.size = 48,
    this.isCurrentApp = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _IconContainer(
        iconData: iconData,
        size: size,
        isCurrentApp: isCurrentApp,
      ),
    );
  }
}

/// 内部图标容器组件
class _IconContainer extends StatefulWidget {
  final String? iconData;
  final double size;
  final bool isCurrentApp;

  const _IconContainer({
    required this.iconData,
    required this.size,
    required this.isCurrentApp,
  });

  @override
  State<_IconContainer> createState() => _IconContainerState();
}

class _IconContainerState extends State<_IconContainer> {
  Uint8List? _cachedImageData;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(_IconContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconData != widget.iconData) {
      _loadIcon();
    }
  }

  void _loadIcon() {
    _cachedImageData = IconCacheManager.getDecodedIcon(widget.iconData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCurrentApp
              ? const Color(0xFF6366F1)
              : Colors.grey[300]!,
          width: widget.isCurrentApp ? 2 : 1,
        ),
      ),
      child: _cachedImageData != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _cachedImageData!,
                fit: BoxFit.cover,
                cacheWidth: widget.size.toInt(),
                cacheHeight: widget.size.toInt(),
                gaplessPlayback: true, // 避免图片闪烁
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.apps, color: Colors.grey[600], size: 24);
                },
              ),
            )
          : Icon(Icons.apps, color: Colors.grey[600], size: 24),
    );
  }
}

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
                        _InfoChip(
                          icon: Icons.access_time,
                          text: _formatDuration(app.totalUsage),
                          color: Colors.blue,
                        ),
                        _InfoChip(
                          icon: Icons.launch,
                          text: '${app.sessionCount} 次',
                          color: Colors.green,
                        ),
                        _InfoChip(
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

/// 信息标签组件
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicationScreen extends ConsumerStatefulWidget {
  const ApplicationScreen({super.key});

  @override
  ConsumerState<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends ConsumerState<ApplicationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 功能面板状态
  bool _isStatsExpanded = false;
  late AnimationController _statsAnimationController;
  late Animation<double> _statsSlideAnimation;
  late Animation<double> _statsOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

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
    _animationController.dispose();
    _statsAnimationController.dispose();
    // 清理图标缓存，防止内存泄漏
    if (IconCacheManager.cacheSize > 100) {
      IconCacheManager.clearCache();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(applicationNotifierProvider);
    final notifier = ref.read(applicationNotifierProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // 主要内容
            _buildMainContent(appState, isNarrowScreen),
            // 统计面板
            _buildStatsPanel(appState, isNarrowScreen),
            // 统计按钮
            _buildStatsToggleButton(isNarrowScreen),
            // 模糊背景和启动按钮（仅在未启动时显示）
            if (!appState.isSpyOn) _buildStartOverlay(appState, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ApplicationState appState, bool isNarrowScreen) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '概览',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatsCards(appState),
          const SizedBox(height: 32),
          const Text(
            '所有应用',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildApplicationsList(appState)),
        ],
      ),
    );
  }

  /// 构建统计面板
  Widget _buildStatsPanel(ApplicationState appState, bool isNarrowScreen) {
    if (!_isStatsExpanded) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _statsOpacityAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // 背景模糊效果
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5.0 * _statsOpacityAnimation.value,
                  sigmaY: 5.0 * _statsOpacityAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(
                    0.2 * _statsOpacityAnimation.value,
                  ),
                ),
              ),
              // 点击空白区域关闭面板
              GestureDetector(
                onTap: _toggleStatsPanel,
                child: Container(color: Colors.transparent),
              ),
              // 统计面板
              AnimatedBuilder(
                animation: _statsSlideAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: isNarrowScreen
                        ? -200 + (200 * _statsSlideAnimation.value)
                        : (MediaQuery.of(context).size.height - 300) /
                              2, // 右侧时垂直居中
                    right: isNarrowScreen
                        ? 0
                        : -320 + (320 * _statsSlideAnimation.value),
                    left: isNarrowScreen ? 0 : null,
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击事件传递
                      child: Container(
                        width: isNarrowScreen ? null : 320,
                        height: isNarrowScreen ? 200 : 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: _getStatsPanelBorderRadius(
                            isNarrowScreen,
                          ),
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
                        child: _buildStatsContent(appState, isNarrowScreen),
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

  /// 构建统计切换按钮
  Widget _buildStatsToggleButton(bool isNarrowScreen) {
    return AnimatedBuilder(
      animation: _statsSlideAnimation,
      builder: (context, child) {
        return Positioned(
          // 窄屏时：跟随面板动画从顶部向下移动
          top: isNarrowScreen
              ? (10 + (200 - 34) * _statsSlideAnimation.value) // 从顶部跟随面板向下移动
              : (MediaQuery.of(context).size.height - 300) / 2 + 126,
          bottom: null,
          // 宽屏时：跟随面板动画从右侧向左移动
          left: !isNarrowScreen
              ? (MediaQuery.of(context).size.width -
                    320 * _statsSlideAnimation.value -
                    24) // 跟随面板滑动
              : null,
          right: isNarrowScreen ? 10 : null,
          child: GestureDetector(
            onTap: _toggleStatsPanel,
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
                borderRadius: _isStatsExpanded && !isNarrowScreen
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isStatsExpanded
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

  /// 构建统计内容
  Widget _buildStatsContent(ApplicationState appState, bool isNarrowScreen) {
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
                onPressed: _toggleStatsPanel,
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
                    _formatDuration(appState.totalUsageTime),
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

  /// 获取统计面板的圆角设置
  BorderRadius _getStatsPanelBorderRadius(bool isNarrowScreen) {
    // 如果面板未展开，不需要圆角
    if (!_isStatsExpanded) {
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

  Widget _buildStartOverlay(
    ApplicationState appState,
    ApplicationNotifier notifier,
  ) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '开始监控',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击开始按钮启动应用使用监控',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: notifier.startSpy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '开始监控',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(ApplicationState appState) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '监控状态',
            appState.isSpyOn ? '运行中' : '已停止',
            appState.isSpyOn
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            appState.isSpyOn ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '应用数量',
            '${appState.applicationUsages.length}',
            Icons.apps,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '总使用时间',
            _formatDuration(appState.totalUsageTime),
            Icons.access_time,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(ApplicationState appState) {
    if (appState.applicationUsages.isEmpty) {
      // TODO: 增加一个没有应用的占位图
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: appState.sortedApplications.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[200], indent: 80),
        itemBuilder: (context, index) {
          final app = appState.sortedApplications[index];
          final isCurrentApp = appState.currentApp == app.name;
          final totalSeconds = appState.totalUsageTime.inSeconds;
          final appSeconds = app.totalUsage.inSeconds;
          final percentage = totalSeconds > 0
              ? (appSeconds / totalSeconds)
              : 0.0;

          return ApplicationListItem(
            key: ValueKey(app.name), // 使用key保持widget稳定性
            app: app,
            index: index,
            isCurrentApp: isCurrentApp,
            percentage: percentage,
            onTap: () => _showAppDetailDialog(context, app, percentage),
          );
        },
      ),
    );
  }

  void _showAppDetailDialog(
    BuildContext context,
    ApplicationUsage app,
    double percentage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            _buildDetailRow(
              '使用占比',
              '${(percentage * 100).toStringAsFixed(1)}%',
            ),
            _buildDetailRow('文件路径', app.path),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
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
