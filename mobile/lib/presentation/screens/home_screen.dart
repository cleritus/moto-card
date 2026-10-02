import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/error_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Redirect to vehicles list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/vehicles');
    });

    return const Scaffold(body: LoadingView(label: 'OTWIERAM GARAŻ'));
  }
}