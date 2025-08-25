import 'package:isar_community/isar.dart';

part 'app_record.g.dart';

@collection
class AppRecord {
  Id id = Isar.autoIncrement;

  late int appId;

  late int year;
  late int month;
  late int day;
  late int hour;
  late int minute;

  late String title;
}
