import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/app/application/components/cached_app_icon.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/app/app_catalog/app_catalog_notifier_simple.dart';

/// 分类卡片组件
class CategoryCard extends StatefulWidget {
  final IAppTypes type;
  final List<ApplicationUsage> apps;
  final Function(ApplicationUsage app, IAppTypes targetType) onAppMoved;

  const CategoryCard({
    super.key,
    required this.type,
    required this.apps,
    required this.onAppMoved,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final displayName = categoryDisplayNames[widget.type] ?? '未知';
    final icon = categoryIcons[widget.type] ?? Icons.apps;
    final color = categoryColors[widget.type] ?? Colors.grey;

    return DragTarget<ApplicationUsage>(
      onWillAccept: (data) => data != null,
      onAccept: (app) {
        widget.onAppMoved(app, widget.type);
        setState(() {
          _isDragOver = false;
        });
      },
      onMove: (details) {
        if (!_isDragOver) {
          setState(() {
            _isDragOver = true;
          });
        }
      },
      onLeave: (data) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDragOver ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragOver ? color : const Color(0xFFE5E7EB),
              width: _isDragOver ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDragOver ? 0.1 : 0.05),
                blurRadius: _isDragOver ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分类标题
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.apps.length} 个应用',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 应用列表
              if (widget.apps.isEmpty)
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '拖拽应用到此处',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.apps
                      .map((app) => _buildAppItem(app))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppItem(ApplicationUsage app) {
    return Draggable<ApplicationUsage>(
      data: app,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CachedAppIcon(iconData: app.icon, size: 40),
        ),
      ),
      childWhenDragging: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(Icons.apps, color: Colors.grey[400], size: 24),
      ),
      child: GestureDetector(
        onLongPress: () {
          // 长按提示用户可以拖拽
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('长按拖拽 ${app.name} 到其他分类'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CachedAppIcon(iconData: app.icon, size: 32),
        ),
      ),
    );
  }
}

/// 未分类应用区域
class UncategorizedAppsArea extends StatelessWidget {
  final List<ApplicationUsage> apps;

  const UncategorizedAppsArea({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '未分类应用',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${apps.length} 个应用',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: apps.map((app) => _buildDraggableApp(app)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableApp(ApplicationUsage app) {
    return Draggable<ApplicationUsage>(
      data: app,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CachedAppIcon(iconData: app.icon, size: 40),
        ),
      ),
      childWhenDragging: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(Icons.apps, color: Colors.grey[400], size: 24),
      ),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: CachedAppIcon(iconData: app.icon, size: 32),
      ),
    );
  }
}
