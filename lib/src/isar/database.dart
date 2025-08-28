import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/app_record.dart';
import 'package:spy_on_your_work/src/isar/app_screenshot_record.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

/// 应用使用时间段数据结构
class AppUsageTimeSlot {
  final int appId;
  final String appName;
  final String? appIcon;
  final IAppTypes category;
  final DateTime startTime;
  final DateTime endTime;
  final String title; // 窗口标题

  AppUsageTimeSlot({
    required this.appId,
    required this.appName,
    this.appIcon,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.title,
  });

  /// 获取使用时长
  Duration get duration => endTime.difference(startTime);

  /// 格式化时间段显示
  String get timeSlotDisplay {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start-$end';
  }
}

/// 应用使用详情数据结构
class AppUsageDetail {
  final int appId;
  final String appName;
  final String? appIcon;
  final IAppTypes category;
  final Duration usageDuration;
  final int sessionCount;
  final List<int> usageHours; // 使用的小时分布

  AppUsageDetail({
    required this.appId,
    required this.appName,
    this.appIcon,
    required this.category,
    required this.usageDuration,
    required this.sessionCount,
    required this.usageHours,
  });
}

class IsarDatabase {
  // ignore: avoid_init_to_null
  late Isar? isar = null;
  static final _instance = IsarDatabase._init();

  factory IsarDatabase() => _instance;

  IsarDatabase._init();

  Future initialDatabase() async {
    if (isar != null && isar!.isOpen) {
      return;
    }
    final dir = await getApplicationSupportDirectory();
    logger.info("database save to ${dir.path}");

    isar = await Isar.open(schemas, name: "soyw", directory: dir.path);
  }

  late List<CollectionSchema<Object>> schemas = [
    IApplicationSchema,
    AppRecordSchema,
    AppScreenshotRecordSchema,
  ];

  /// 获取当天的应用使用记录
  Future<List<AppRecord>> getTodayAppRecords() async {
    if (isar == null) await initialDatabase();

    final now = DateTime.now();
    return await isar!.appRecords
        .filter()
        .yearEqualTo(now.year)
        .and()
        .monthEqualTo(now.month)
        .and()
        .dayEqualTo(now.day)
        .findAll();
  }

  /// 根据应用ID获取应用信息
  Future<IApplication?> getApplicationById(int appId) async {
    if (isar == null) await initialDatabase();

    return await isar!.iApplications.filter().idEqualTo(appId).findFirst();
  }

  Future<List<IApplication>> getScreenShotApplication() async {
    if (isar == null) await initialDatabase();
    return await isar!.iApplications
        .filter()
        .screenshotWhenUsingEqualTo(true)
        .findAll();
  }

  /// 获取或创建应用信息
  Future<IApplication> getOrCreateApplication(
    String name,
    String path,
    String? icon,
  ) async {
    if (isar == null) await initialDatabase();

    // 先查询是否存在
    var appInfo = await isar!.iApplications
        .filter()
        .nameEqualTo(name)
        .and()
        .pathEqualTo(path)
        .findFirst();

    if (appInfo == null) {
      // 不存在则创建，默认设置为unknown类型
      appInfo = IApplication()
        ..name = name
        ..path = path
        ..icon = icon
        ..type = IAppTypes.unknown; // 确保设置默认类型

      await isar!.writeTxn(() async {
        appInfo!.id = await isar!.iApplications.put(appInfo);
      });
    } else if (appInfo.icon != icon && icon != null) {
      // 更新图标（如果有变化）
      appInfo.icon = icon;
      await isar!.writeTxn(() async {
        await isar!.iApplications.put(appInfo!);
      });
    }

    return appInfo;
  }

  /// 添加应用使用记录
  Future<void> addAppRecord(int appId, String title) async {
    if (isar == null) await initialDatabase();

    final now = DateTime.now();
    await isar!.writeTxn(() async {
      await isar!.appRecords.put(
        AppRecord()
          ..appId = appId
          ..title = title
          ..year = now.year
          ..month = now.month
          ..day = now.day
          ..hour = now.hour
          ..minute = now.minute,
      );
    });
  }

  /// 计算当天应用的使用时长（基于记录的分钟数统计）
  Future<Map<int, Duration>> getTodayAppUsageDurations() async {
    final records = await getTodayAppRecords();
    final Map<int, Set<int>> appMinutes = {};

    // 按应用ID分组，统计每个应用在不同分钟的使用情况
    for (final record in records) {
      appMinutes.putIfAbsent(record.appId, () => <int>{});
      // 使用小时*60+分钟作为唯一标识符
      appMinutes[record.appId]!.add(record.hour * 60 + record.minute);
    }

    // 转换为时长
    final Map<int, Duration> durations = {};
    appMinutes.forEach((appId, minutes) {
      durations[appId] = Duration(minutes: minutes.length);
    });

    return durations;
  }

  /// 获取当天应用的使用次数（会话次数）
  Future<Map<int, int>> getTodayAppSessionCounts() async {
    final records = await getTodayAppRecords();
    final Map<int, Set<String>> appSessions = {};

    // 按应用ID分组，统计会话次数（相同小时内的连续使用算作一次会话）
    for (final record in records) {
      appSessions.putIfAbsent(record.appId, () => <String>{});
      // 使用小时作为会话标识（同一小时内算作一次会话）
      appSessions[record.appId]!.add('${record.hour}');
    }

    // 转换为次数
    final Map<int, int> counts = {};
    appSessions.forEach((appId, sessions) {
      counts[appId] = sessions.length;
    });

    return counts;
  }

  /// 获取所有应用使用记录
  Future<List<AppRecord>> getAllAppRecords() async {
    if (isar == null) await initialDatabase();

    return await isar!.appRecords.where().findAll();
  }

  /// 获取所有应用信息
  Future<List<IApplication>> getAllApplications() async {
    if (isar == null) await initialDatabase();

    return await isar!.iApplications.where().findAll();
  }

  /// 按应用类型统计当天使用时长
  Future<Map<IAppTypes, Duration>> getTodayUsageByCategory() async {
    final allApps = await getAllApplications();
    // ignore: unused_local_variable
    final todayRecords = await getTodayAppRecords();
    final todayDurations = await getTodayAppUsageDurations();

    final Map<IAppTypes, Duration> categoryUsage = {};

    // 初始化所有分类
    for (final category in IAppTypes.values) {
      categoryUsage[category] = Duration.zero;
    }

    // 按应用ID查找对应的分类并累加使用时长
    for (final entry in todayDurations.entries) {
      final appId = entry.key;
      final duration = entry.value;

      final app = allApps.firstWhere(
        (app) => app.id == appId,
        orElse: () => IApplication()..type = IAppTypes.unknown,
      );

      categoryUsage[app.type] = categoryUsage[app.type]! + duration;
    }

    return categoryUsage;
  }

  /// 按应用类型统计全部使用时长
  Future<Map<IAppTypes, Duration>> getAllTimeUsageByCategory() async {
    final allApps = await getAllApplications();
    final allRecords = await getAllAppRecords();

    // 计算所有记录的使用时长
    final Map<int, Set<int>> appMinutes = {};

    for (final record in allRecords) {
      appMinutes.putIfAbsent(record.appId, () => <int>{});
      // 使用日期+小时+分钟作为唯一标识符
      final uniqueMinute =
          record.year * 100000000 +
          record.month * 1000000 +
          record.day * 10000 +
          record.hour * 100 +
          record.minute;
      appMinutes[record.appId]!.add(uniqueMinute);
    }

    // 转换为时长
    final Map<int, Duration> allDurations = {};
    appMinutes.forEach((appId, minutes) {
      allDurations[appId] = Duration(minutes: minutes.length);
    });

    final Map<IAppTypes, Duration> categoryUsage = {};

    // 初始化所有分类
    for (final category in IAppTypes.values) {
      categoryUsage[category] = Duration.zero;
    }

    // 按应用ID查找对应的分类并累加使用时长
    for (final entry in allDurations.entries) {
      final appId = entry.key;
      final duration = entry.value;

      final app = allApps.firstWhere(
        (app) => app.id == appId,
        orElse: () => IApplication()..type = IAppTypes.unknown,
      );

      categoryUsage[app.type] = categoryUsage[app.type]! + duration;
    }

    return categoryUsage;
  }

  Future insertScreenshot(AppScreenshotRecord record) async {
    if (isar == null) await initialDatabase();
    await isar!.writeTxn(() async {
      await isar!.appScreenshotRecords.put(record);
    });
  }

  /// 为指定应用添加截图记录
  Future<void> addScreenshotRecord(int appId, String screenshotPath) async {
    final record = AppScreenshotRecord()
      ..appId = appId
      ..path = screenshotPath
      ..createAt = DateTime.now().millisecondsSinceEpoch;

    await insertScreenshot(record);
    logger.info('添加截图记录: appId=$appId, path=$screenshotPath');
  }

  /// 根据应用ID获取截图记录
  Future<List<AppScreenshotRecord>> getScreenshotsByAppId(int appId) async {
    if (isar == null) await initialDatabase();

    return await isar!.appScreenshotRecords
        .filter()
        .appIdEqualTo(appId)
        .sortByCreateAtDesc()
        .findAll();
  }

  /// 删除指定应用的所有截图记录
  Future<void> deleteScreenshotsByAppId(int appId) async {
    if (isar == null) await initialDatabase();

    await isar!.writeTxn(() async {
      await isar!.appScreenshotRecords.filter().appIdEqualTo(appId).deleteAll();
    });
  }

  /// 删除指定的截图记录
  Future<void> deleteScreenshot(int screenshotId) async {
    if (isar == null) await initialDatabase();

    await isar!.writeTxn(() async {
      await isar!.appScreenshotRecords.delete(screenshotId);
    });
  }

  /// 获取指定日期范围内每天按类别聚合的使用统计
  Future<Map<DateTime, Map<IAppTypes, Duration>>> getDailyUsageByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (isar == null) await initialDatabase();

    final allApps = await getAllApplications();
    final result = <DateTime, Map<IAppTypes, Duration>>{};

    // 遍历日期范围
    for (
      var date = startDate;
      date.isBefore(endDate.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      // 获取指定日期的记录
      final records = await isar!.appRecords
          .filter()
          .yearEqualTo(date.year)
          .and()
          .monthEqualTo(date.month)
          .and()
          .dayEqualTo(date.day)
          .findAll();

      // 计算该日期的应用使用时长
      final Map<int, Set<int>> appMinutes = {};
      for (final record in records) {
        appMinutes.putIfAbsent(record.appId, () => <int>{});
        appMinutes[record.appId]!.add(record.hour * 60 + record.minute);
      }

      // 转换为按类别聚合的时长
      final Map<IAppTypes, Duration> categoryUsage = {};
      for (final category in IAppTypes.values) {
        categoryUsage[category] = Duration.zero;
      }

      for (final entry in appMinutes.entries) {
        final appId = entry.key;
        final minutes = entry.value;
        final duration = Duration(minutes: minutes.length);

        final app = allApps.firstWhere(
          (app) => app.id == appId,
          orElse: () => IApplication()..type = IAppTypes.unknown,
        );

        categoryUsage[app.type] = categoryUsage[app.type]! + duration;
      }

      result[DateTime(date.year, date.month, date.day)] = categoryUsage;
    }

    return result;
  }

  /// 获取指定日期按类别聚合的使用统计
  Future<Map<IAppTypes, Duration>> getDayUsageByCategory(DateTime date) async {
    if (isar == null) await initialDatabase();

    final allApps = await getAllApplications();
    final records = await isar!.appRecords
        .filter()
        .yearEqualTo(date.year)
        .and()
        .monthEqualTo(date.month)
        .and()
        .dayEqualTo(date.day)
        .findAll();

    // 计算该日期的应用使用时长
    final Map<int, Set<int>> appMinutes = {};
    for (final record in records) {
      appMinutes.putIfAbsent(record.appId, () => <int>{});
      appMinutes[record.appId]!.add(record.hour * 60 + record.minute);
    }

    // 转换为按类别聚合的时长
    final Map<IAppTypes, Duration> categoryUsage = {};
    for (final category in IAppTypes.values) {
      categoryUsage[category] = Duration.zero;
    }

    for (final entry in appMinutes.entries) {
      final appId = entry.key;
      final minutes = entry.value;
      final duration = Duration(minutes: minutes.length);

      final app = allApps.firstWhere(
        (app) => app.id == appId,
        orElse: () => IApplication()..type = IAppTypes.unknown,
      );

      categoryUsage[app.type] = categoryUsage[app.type]! + duration;
    }

    return categoryUsage;
  }

  /// 获取指定日期的应用使用时间段
  Future<List<AppUsageTimeSlot>> getDayAppUsageTimeSlots(DateTime date) async {
    if (isar == null) await initialDatabase();

    final allApps = await getAllApplications();
    final records = await isar!.appRecords
        .filter()
        .yearEqualTo(date.year)
        .and()
        .monthEqualTo(date.month)
        .and()
        .dayEqualTo(date.day)
        .sortByHour()
        .thenByMinute()
        .findAll();

    if (records.isEmpty) return [];

    final List<AppUsageTimeSlot> timeSlots = [];
    final Map<int, List<AppRecord>> appRecordsMap = {};

    // 按应用ID分组记录
    for (final record in records) {
      appRecordsMap.putIfAbsent(record.appId, () => []);
      appRecordsMap[record.appId]!.add(record);
    }

    // 为每个应用生成连续的时间段
    for (final entry in appRecordsMap.entries) {
      final appId = entry.key;
      final appRecords = entry.value;

      final app = allApps.firstWhere(
        (app) => app.id == appId,
        orElse: () => IApplication()
          ..id = appId
          ..name = '未知应用'
          ..type = IAppTypes.unknown,
      );

      final appTimeSlots = _generateTimeSlots(appRecords, app, date);
      timeSlots.addAll(appTimeSlots);
    }

    // 按开始时间排序
    timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return timeSlots;
  }

  /// 生成连续的时间段
  List<AppUsageTimeSlot> _generateTimeSlots(
    List<AppRecord> records,
    IApplication app,
    DateTime date,
  ) {
    if (records.isEmpty) return [];

    final List<AppUsageTimeSlot> timeSlots = [];
    final sortedRecords = List<AppRecord>.from(records)
      ..sort((a, b) {
        final aTime = a.hour * 60 + a.minute;
        final bTime = b.hour * 60 + b.minute;
        return aTime.compareTo(bTime);
      });

    DateTime? slotStart;
    DateTime? slotEnd;
    String? currentTitle;

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final recordTime = DateTime(
        date.year,
        date.month,
        date.day,
        record.hour,
        record.minute,
      );

      if (slotStart == null) {
        // 开始新的时间段
        slotStart = recordTime;
        slotEnd = recordTime.add(const Duration(minutes: 1));
        currentTitle = record.title;
      } else {
        // 检查是否连续（间隔不超过3分钟）
        final gap = recordTime.difference(slotEnd!);
        if (gap.inMinutes <= 3 && record.title == currentTitle) {
          // 连续使用，延长当前时间段
          slotEnd = recordTime.add(const Duration(minutes: 1));
        } else {
          // 不连续，结束当前时间段，开始新的时间段
          if (slotEnd.difference(slotStart).inMinutes >= 1) {
            timeSlots.add(
              AppUsageTimeSlot(
                appId: app.id,
                appName: app.name,
                appIcon: app.icon,
                category: app.type,
                startTime: slotStart,
                endTime: slotEnd,
                title: currentTitle ?? '',
              ),
            );
          }

          slotStart = recordTime;
          slotEnd = recordTime.add(const Duration(minutes: 1));
          currentTitle = record.title;
        }
      }
    }

    // 添加最后一个时间段
    if (slotStart != null && slotEnd != null) {
      if (slotEnd.difference(slotStart).inMinutes >= 1) {
        timeSlots.add(
          AppUsageTimeSlot(
            appId: app.id,
            appName: app.name,
            appIcon: app.icon,
            category: app.type,
            startTime: slotStart,
            endTime: slotEnd,
            title: currentTitle ?? '',
          ),
        );
      }
    }

    return timeSlots;
  }

  Future<List<AppUsageDetail>> getDayAppUsageDetails(DateTime date) async {
    if (isar == null) await initialDatabase();

    final allApps = await getAllApplications();
    final records = await isar!.appRecords
        .filter()
        .yearEqualTo(date.year)
        .and()
        .monthEqualTo(date.month)
        .and()
        .dayEqualTo(date.day)
        .findAll();

    // 按应用ID分组统计
    final Map<int, Set<int>> appMinutes = {};
    final Map<int, Set<int>> appSessions = {};
    final Map<int, Set<int>> appHours = {};

    for (final record in records) {
      // 统计使用分钟数
      appMinutes.putIfAbsent(record.appId, () => <int>{});
      appMinutes[record.appId]!.add(record.hour * 60 + record.minute);

      // 统计会话数（同一小时算一个会话）
      appSessions.putIfAbsent(record.appId, () => <int>{});
      appSessions[record.appId]!.add(record.hour);

      // 统计使用小时分布
      appHours.putIfAbsent(record.appId, () => <int>{});
      appHours[record.appId]!.add(record.hour);
    }

    // 生成应用使用详情列表
    final List<AppUsageDetail> details = [];
    for (final appId in appMinutes.keys) {
      final app = allApps.firstWhere(
        (app) => app.id == appId,
        orElse: () => IApplication()
          ..id = appId
          ..name = '未知应用'
          ..type = IAppTypes.unknown,
      );

      final minutes = appMinutes[appId]?.length ?? 0;
      final sessions = appSessions[appId]?.length ?? 0;
      final hours = appHours[appId]?.toList() ?? [];
      hours.sort();

      if (minutes > 0) {
        details.add(
          AppUsageDetail(
            appId: appId,
            appName: app.name,
            appIcon: app.icon,
            category: app.type,
            usageDuration: Duration(minutes: minutes),
            sessionCount: sessions,
            usageHours: hours,
          ),
        );
      }
    }

    // 按使用时长排序
    details.sort((a, b) => b.usageDuration.compareTo(a.usageDuration));
    return details;
  }

  /// 获取指定日期范围内的应用使用趋势
  Future<Map<String, List<Duration>>> getAppUsageTrend(
    DateTime startDate,
    DateTime endDate,
    List<int> appIds,
  ) async {
    if (isar == null) await initialDatabase();

    final Map<String, List<Duration>> trends = {};
    final allApps = await getAllApplications();

    // 为每个应用初始化趋势数据
    for (final appId in appIds) {
      final app = allApps.firstWhere(
        (app) => app.id == appId,
        orElse: () => IApplication()..name = '未知应用',
      );
      trends[app.name] = [];
    }

    // 遍历日期范围
    for (
      var date = startDate;
      date.isBefore(endDate.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      final records = await isar!.appRecords
          .filter()
          .yearEqualTo(date.year)
          .and()
          .monthEqualTo(date.month)
          .and()
          .dayEqualTo(date.day)
          .findAll();

      // 计算每个应用在当天的使用时长
      final Map<int, Set<int>> dayAppMinutes = {};
      for (final record in records) {
        if (appIds.contains(record.appId)) {
          dayAppMinutes.putIfAbsent(record.appId, () => <int>{});
          dayAppMinutes[record.appId]!.add(record.hour * 60 + record.minute);
        }
      }

      // 为每个应用添加当天的使用时长
      for (final appId in appIds) {
        final app = allApps.firstWhere(
          (app) => app.id == appId,
          orElse: () => IApplication()..name = '未知应用',
        );
        final minutes = dayAppMinutes[appId]?.length ?? 0;
        trends[app.name]!.add(Duration(minutes: minutes));
      }
    }

    return trends;
  }
}
