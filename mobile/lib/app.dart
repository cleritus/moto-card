import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'core/router/app_router.dart';

class MotoApp extends ConsumerWidget {
  const MotoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Moto Service Card',
      debugShowCheckedModeBanner: false,
      // DIRTY GARAGE is a single dark theme by design (§1) — there is no
      // light variant, so both slots carry it and the mode is pinned.
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}