import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiggly_loaders/wiggly_loaders.dart';
import 'package:wiggly_loaders/src/internal/wiggly_arc_painter.dart';

void main() {
  group('WigglyLoader', () {
    test('asserts when progress is outside 0.0..1.0', () {
      expect(
        () => WigglyLoader(progress: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyLoader(progress: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('renders determinate without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: WigglyLoader(progress: 0.5))),
        ),
      );
      expect(find.byType(WigglyLoader), findsOneWidget);
    });

    testWidgets('renders indeterminate without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: WigglyLoader.indeterminate())),
        ),
      );
      expect(find.byType(WigglyLoader), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                progress: 0.5,
                child: Text('50%'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('supports switching from indeterminate to determinate',
        (tester) async {
      const key = ValueKey('loader');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader.indeterminate(key: key),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 0.4,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WigglyLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts willAnimate false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                progress: 0.5,
                willAnimate: false,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<WigglyLoader>(find.byType(WigglyLoader));
      expect(widget.willAnimate, isFalse);
    });

    testWidgets('applies theme extension colors for default values',
        (tester) async {
      const themedColor = Color(0xFFE11D48);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              WigglyLoadersThemeData(loaderProgressColor: themedColor),
            ],
          ),
          home: const Scaffold(
            body: Center(
              child: WigglyLoader(progress: 0.5),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyLoader),
          matching: find.byType(CustomPaint),
        ),
      );

      final painter = customPaint.painter! as WigglyArcPainter;
      expect(painter.progressColor, themedColor);
    });

    testWidgets('sets default semantics for determinate loader',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(progress: 0.42),
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(WigglyLoader),
          matching: find.byType(Semantics),
        ),
      );
      expect(semantics.properties.label, 'Loading progress');
      expect(semantics.properties.value, '42 percent');
    });
  });

  group('WigglyLinearLoader', () {
    test('asserts when progress is outside 0.0..1.0', () {
      expect(
        () => WigglyLinearLoader(progress: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyLinearLoader(progress: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('renders determinate without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: WigglyLinearLoader(progress: 0.75)),
          ),
        ),
      );
      expect(find.byType(WigglyLinearLoader), findsOneWidget);
    });

    testWidgets('renders indeterminate without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: WigglyLinearLoader.indeterminate()),
          ),
        ),
      );
      expect(find.byType(WigglyLinearLoader), findsOneWidget);
    });

    testWidgets('supports indeterminate rebuild updates', (tester) async {
      const key = ValueKey('linear-loader');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader.indeterminate(
                key: key,
                segmentFraction: 0.3,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader.indeterminate(
                key: key,
                segmentFraction: 0.6,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WigglyLinearLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts willAnimate false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader(
                progress: 0.75,
                willAnimate: false,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<WigglyLinearLoader>(
        find.byType(WigglyLinearLoader),
      );
      expect(widget.willAnimate, isFalse);
    });
  });

  group('WigglyRefreshIndicator', () {
    testWidgets('renders child and wraps scrollable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WigglyRefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                children: const [Text('Item 1'), Text('Item 2')],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.byType(WigglyRefreshIndicator), findsOneWidget);
    });

    testWidgets('accepts trigger/max drag and notification predicate',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WigglyRefreshIndicator(
              onRefresh: () async {},
              triggerDistance: 92,
              maxDragDistance: 140,
              notificationPredicate: (_) => true,
              child: ListView(
                children: const [Text('Item 1')],
              ),
            ),
          ),
        ),
      );

      final indicator = tester.widget<WigglyRefreshIndicator>(
        find.byType(WigglyRefreshIndicator),
      );
      expect(indicator.triggerDistance, 92);
      expect(indicator.maxDragDistance, 140);
      expect(indicator.notificationPredicate, isNotNull);
    });
  });
}
