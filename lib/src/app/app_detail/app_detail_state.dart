import 'package:spy_on_your_work/src/isar/app_screenshot_record.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

/// 应用详细配置状态
class AppDetailState {
  final IApplication? application;
  final List<AppScreenshotRecord> screenshots;
  final List<AnalysisResult> analysisResults;
  final bool isLoading;
  final String? error;

  const AppDetailState({
    this.application,
    this.screenshots = const [],
    this.analysisResults = const [],
    this.isLoading = false,
    this.error,
  });

  AppDetailState copyWith({
    IApplication? application,
    List<AppScreenshotRecord>? screenshots,
    List<AnalysisResult>? analysisResults,
    bool? isLoading,
    String? error,
  }) {
    return AppDetailState(
      application: application ?? this.application,
      screenshots: screenshots ?? this.screenshots,
      analysisResults: analysisResults ?? this.analysisResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 内容分析结果数据结构
class AnalysisResult {
  final String id;
  final DateTime timestamp;
  final String content;
  final String category;
  final double confidence;
  final Map<String, dynamic> metadata;

  const AnalysisResult({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.category,
    required this.confidence,
    this.metadata = const {},
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      content: json['content'],
      category: json['category'],
      confidence: json['confidence'].toDouble(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'content': content,
      'category': category,
      'confidence': confidence,
      'metadata': metadata,
    };
  }
}
