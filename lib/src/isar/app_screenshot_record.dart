import 'package:isar_community/isar.dart';

part 'app_screenshot_record.g.dart';

@collection
class AppScreenshotRecord {
  Id id = Isar.autoIncrement;

  late int appId;
  late String path;
  int createAt = DateTime.now().millisecondsSinceEpoch;
}
