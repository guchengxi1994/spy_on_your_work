import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/app_record.dart';
import 'package:spy_on_your_work/src/isar/app_screenshot_record.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';
import 'package:spy_on_your_work/src/rust/api/spy_api.dart' show initSavePath;

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
    final screenDir = "${dir.path}/screen";
    Directory(screenDir).createSync(recursive: true);
    initSavePath(path: screenDir);
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
}
