import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_on_your_work/src/app/application/application_notifier.dart';

class ApplicationScreen extends ConsumerStatefulWidget {
  const ApplicationScreen({super.key});

  @override
  ConsumerState<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends ConsumerState<ApplicationScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(applicationNotifierProvider);
    return Container(
      child: IconButton(
        onPressed: () {
          ref.read(applicationNotifierProvider.notifier).startSpy();
        },
        icon: Icon(Icons.start),
      ),
    );
  }
}
