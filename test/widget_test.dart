import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix/main.dart';

void main() {
  testWidgets('StreamFlix loads branding on desktop viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const StreamFlixApp());
    await tester.pumpAndSettle();

    expect(find.text('STREAMFLIX'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('My List'), findsOneWidget);
  });

  testWidgets('StreamFlix renders cleanly on mobile viewport without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const StreamFlixApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
