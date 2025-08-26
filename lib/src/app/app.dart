import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spy_on_your_work/src/app/app_catalog/app_catalog_screen.dart';
import 'package:spy_on_your_work/src/app/application/application_screen.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const ApplicationScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'catalog',
          builder: (BuildContext context, GoRouterState state) {
            return const AppCatalogScreen();
          },
        ),
      ],
    ),
  ],
);
