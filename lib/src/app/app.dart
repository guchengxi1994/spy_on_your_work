import 'package:flutter/material.dart';
import 'package:spy_on_your_work/src/app/application/application_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ApplicationScreen());
  }
}
