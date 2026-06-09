import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_service_card/app.dart';

void main() {
  testWidgets('MotoApp builds correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MotoApp(),
      ),
    );

    // Verify the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}