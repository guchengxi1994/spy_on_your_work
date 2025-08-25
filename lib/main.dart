import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:spy_on_your_work/src/app/app.dart';
import 'package:spy_on_your_work/src/isar/database.dart';
import 'package:spy_on_your_work/src/rust/frb_generated.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  await RustLib.init();
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });
  IsarDatabase database = IsarDatabase();
  await database.initialDatabase();
  runApp(
    ToastificationWrapper(
      child: ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 128, 180, 217),
              brightness: Brightness.light,
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: MyApp(),
        ),
      ),
    ),
  );
}
