import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spy_on_your_work/src/rust/api/spy_api.dart';

class AppInfo {
  AppInfo._();

  static String version = "";
  static String screenshotPath = "";

  static String description =
      "This app is powered by XiaoShuYui. All rights reserved.";

  static String descriptionShort = "This app is powered by XiaoShuYui.";

  static Future init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    final dir = await getApplicationSupportDirectory();
    screenshotPath = "${dir.path}/screen";
    Directory(screenshotPath).createSync(recursive: true);
    initSavePath(path: screenshotPath);
  }
}
