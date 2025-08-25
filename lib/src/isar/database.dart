import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/isar/app_record.dart';
import 'package:spy_on_your_work/src/isar/apps.dart';

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
      // 不存在则创建
      appInfo = IApplication()
        ..name = name
        ..path = path
        ..icon = icon;

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
}
