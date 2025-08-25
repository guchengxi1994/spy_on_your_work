import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
