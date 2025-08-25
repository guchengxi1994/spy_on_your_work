import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_on_your_work/src/app/application/application_state.dart';
import 'package:spy_on_your_work/src/common/logger.dart';
import 'package:spy_on_your_work/src/rust/api/spy_api.dart' as api;

class ApplicationNotifier extends Notifier<ApplicationState> {
  final appStream = api.applicationInfoStream();

  @override
  ApplicationState build() {
    appStream.listen((event) {
      logger.info(
        "running app: ${event.name}, on ${event.path}, title ${event.title}",
      );
    });

    return ApplicationState(isSpyOn: api.getSpyStatus());
  }

  void startSpy() {
    if (!state.isSpyOn) {
      api.startSpy();
      state = state.copyWith(isSpyOn: true);
    }
  }
}

final applicationNotifierProvider =
    NotifierProvider<ApplicationNotifier, ApplicationState>(
      () => ApplicationNotifier(),
    );
