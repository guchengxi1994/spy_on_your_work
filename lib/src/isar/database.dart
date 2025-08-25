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
}
