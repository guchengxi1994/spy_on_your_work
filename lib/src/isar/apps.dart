import 'package:isar_community/isar.dart';

part 'apps.g.dart';

enum IAppTypes { work, study, joy, others, unknown }

/* 为了区分rust传过来的 `Application`
    取名为 `IApplication`， I代表Isar
*/
@collection
class IApplication {
  Id id = Isar.autoIncrement;
  int createAt = DateTime.now().millisecondsSinceEpoch;
  late String name;
  late String path;
  late String? icon;

  @enumerated
  IAppTypes type = IAppTypes.unknown;

  late bool screenshotWhenUsing = false;
  late bool analyseWhenUsing = false;
}
