import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:spy_on_your_work/src/app_info.dart';
import 'dart:io';

import 'package:spy_on_your_work/src/isar/app_screenshot_record.dart';

class ScreenshotGallery extends StatefulWidget {
  final List<AppScreenshotRecord> screenshots;
  final VoidCallback onClearAll;

  const ScreenshotGallery({
    super.key,
    required this.screenshots,
    required this.onClearAll,
  });

  @override
  State<ScreenshotGallery> createState() => _ScreenshotGalleryState();
}

class _ScreenshotGalleryState extends State<ScreenshotGallery> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        if (widget.screenshots.isNotEmpty) _buildToolbar(),

        // 截图网格
        Expanded(
          child: widget.screenshots.isEmpty
              ? _buildEmptyState()
              : _buildScreenshotGrid(),
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
          Icon(Icons.photo_library, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '共 ${widget.screenshots.length} 张截图',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              OpenFile.open(AppInfo.screenshotPath);
            },
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('打开截图位置'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[600],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onClearAll,
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

  Widget _buildScreenshotGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10, // 截图通常是横向的
      ),
      itemCount: widget.screenshots.length,
      itemBuilder: (context, index) {
        return _buildScreenshotItem(widget.screenshots[index].path, index);
      },
    );
  }

  Widget _buildScreenshotItem(String screenshotPath, int index) {
    return GestureDetector(
      onTap: () {
        _showScreenshotPreview(screenshotPath, index);
      },
      child: Container(
        decoration: BoxDecoration(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 截图图片
              File(screenshotPath).existsSync()
                  ? Image.file(
                      File(screenshotPath),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorPlaceholder();
                      },
                    )
                  : _buildErrorPlaceholder(),

              // 渐变遮罩
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // 时间戳标签
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    widget.screenshots[index].createAt,
                  ).toLocal().toString().split(".").first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 预览指示器
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF3F4F6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            '图片加载失败',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
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
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无截图记录',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '启用截图功能后，系统会自动保存应用使用时的截图',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 显示截图预览弹窗
  void _showScreenshotPreview(String screenshotPath, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => ScreenshotPreviewDialog(
        screenshots: widget.screenshots,
        initialIndex: initialIndex,
      ),
    );
  }
}

/// 截图预览弹窗
class ScreenshotPreviewDialog extends StatefulWidget {
  final List<AppScreenshotRecord> screenshots;
  final int initialIndex;

  const ScreenshotPreviewDialog({
    super.key,
    required this.screenshots,
    required this.initialIndex,
  });

  @override
  State<ScreenshotPreviewDialog> createState() =>
      _ScreenshotPreviewDialogState();
}

class _ScreenshotPreviewDialogState extends State<ScreenshotPreviewDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // 主内容区域
          PageView.builder(
            controller: _pageController,
            itemCount: widget.screenshots.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildScreenshotPage(widget.screenshots[index].path);
            },
          ),

          // 顶部工具栏
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // 底部信息栏
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),

          // 左右导航按钮
          if (widget.screenshots.length > 1) ..._buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildScreenshotPage(String screenshotPath) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: File(screenshotPath).existsSync()
            ? Image.file(
                File(screenshotPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorWidget();
                },
              )
            : _buildErrorWidget(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.screenshots.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final currentScreenshot = widget.screenshots[_currentIndex];
    final timeString = DateTime.fromMillisecondsSinceEpoch(
      widget.screenshots[_currentIndex].createAt,
    ).toLocal().toString().split(".").first;
    final fileName = currentScreenshot.path.split('/').last;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                timeString,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavigationButtons() {
    return [
      // 左侧按钮
      if (_currentIndex > 0)
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              onPressed: _previousImage,
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ),

      // 右侧按钮
      if (_currentIndex < widget.screenshots.length - 1)
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              onPressed: _nextImage,
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            '图片加载失败',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.screenshots.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
