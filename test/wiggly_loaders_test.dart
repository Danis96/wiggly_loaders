import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiggly_loaders/wiggly_loaders.dart';
import 'package:wiggly_loaders/src/internal/wiggly_arc_canvas.dart';
import 'package:wiggly_loaders/src/internal/wiggly_arc_painter.dart';
import 'package:wiggly_loaders/src/internal/wiggly_dots_painter.dart';
import 'package:wiggly_loaders/src/internal/wiggly_linear_painter.dart';

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

    test('asserts when dimensions or timings are invalid', () {
      expect(
        () => WigglyLoader(progress: 0.5, size: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyLoader(progress: 0.5, strokeWidth: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyLoader.indeterminate(arcSpan: 1.1),
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

    testWidgets('applies shared theme tokens for size, stroke, and color',
        (tester) async {
      const themedColor = Color(0xFF0F766E);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              WigglyLoadersThemeData(
                progressColor: themedColor,
                sizeScale: 1.5,
                strokeWidthScale: 2.0,
              ),
            ],
          ),
          home: const Scaffold(
            body: Center(
              child: WigglyLoader(progress: 0.5),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(WigglyArcCanvas),
          matching: find.byType(SizedBox),
        ),
      );
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyLoader),
          matching: find.byType(CustomPaint),
        ),
      );

      final painter = customPaint.painter! as WigglyArcPainter;
      expect(sizedBox.width, 108.0);
      expect(painter.strokeWidth, 9.0);
      expect(painter.progressColor, themedColor);
    });

    testWidgets('passes progressEndColor through to the painter',
        (tester) async {
      const endColor = Color(0xFF22C55E);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                progress: 0.5,
                progressEndColor: endColor,
              ),
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
      expect(painter.progressEndColor, endColor);
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

    testWidgets('calls onComplete when progress reaches 1.0', (tester) async {
      var callCount = 0;
      const key = ValueKey('loader-complete');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 0.8,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 1.0,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(callCount, 1);
    });

    testWidgets('does not call onComplete on intermediate progress updates',
        (tester) async {
      var callCount = 0;
      const key = ValueKey('loader-no-complete');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 0.3,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 0.7,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(callCount, 0);
    });

    testWidgets('burst raises wiggle amplitude during completion animation',
        (tester) async {
      const key = ValueKey('loader-burst');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 0.9,
                willAnimate: false,
                completeDuration: Duration(milliseconds: 400),
              ),
            ),
          ),
        ),
      );

      double amplitudeAtRest() {
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(WigglyLoader),
            matching: find.byType(CustomPaint),
          ),
        );
        return (customPaint.painter! as WigglyArcPainter).wiggleAmplitude;
      }

      final beforeBurst = amplitudeAtRest();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader(
                key: key,
                progress: 1.0,
                willAnimate: false,
                completeDuration: Duration(milliseconds: 400),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      final duringBurst = amplitudeAtRest();
      expect(duringBurst, greaterThan(beforeBurst));

      await tester.pump(const Duration(milliseconds: 300));
      final afterBurst = amplitudeAtRest();
      expect(afterBurst, closeTo(beforeBurst, 0.01));
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

    test('asserts when geometry is invalid', () {
      expect(
        () => WigglyLinearLoader(progress: 0.5, height: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyLinearLoader.indeterminate(segmentFraction: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyLinearLoader.indeterminate(borderRadius: -1),
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

    testWidgets('calls onComplete when progress reaches 1.0', (tester) async {
      var callCount = 0;
      const key = ValueKey('linear-complete');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader(
                key: key,
                progress: 0.5,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader(
                key: key,
                progress: 1.0,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(callCount, 1);
    });

    testWidgets('theme ease changes indeterminate slide curve', (tester) async {
      Future<double> pumpAndReadSlideOffset({
        WigglyLoadersThemeData? theme,
      }) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: theme == null ? const [] : [theme],
            ),
            home: const Scaffold(
              body: Center(
                child: WigglyLinearLoader.indeterminate(willAnimate: false),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 350));

        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(WigglyLinearLoader),
            matching: find.byType(CustomPaint),
          ),
        );

        return (customPaint.painter! as WigglyLinearPainter).slideOffset;
      }

      final defaultOffset = await pumpAndReadSlideOffset();
      final linearOffset = await pumpAndReadSlideOffset(
        theme: const WigglyLoadersThemeData(ease: Curves.linear),
      );

      expect(linearOffset, greaterThan(defaultOffset));
    });

    testWidgets('passes progressEndColor through to the painter',
        (tester) async {
      const endColor = Color(0xFF8B5CF6);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader(
                progress: 0.75,
                progressEndColor: endColor,
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyLinearLoader),
          matching: find.byType(CustomPaint),
        ),
      );

      final painter = customPaint.painter! as WigglyLinearPainter;
      expect(painter.progressEndColor, endColor);
    });
  });

  group('WigglyDotsLoader', () {
    test('asserts when progress is outside 0.0..1.0', () {
      expect(
        () => WigglyDotsLoader(progress: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyDotsLoader(progress: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts when dot parameters are invalid', () {
      expect(
        () => WigglyDotsLoader(progress: 0.5, dotCount: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyDotsLoader(progress: 0.5, dotSize: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyDotsLoader(progress: 0.5, spacing: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('renders determinate without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: WigglyDotsLoader(progress: 0.5)),
          ),
        ),
      );

      expect(find.byType(WigglyDotsLoader), findsOneWidget);
    });

    testWidgets('renders indeterminate without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: WigglyDotsLoader.indeterminate()),
          ),
        ),
      );

      expect(find.byType(WigglyDotsLoader), findsOneWidget);
    });

    testWidgets('supports switching from indeterminate to determinate',
        (tester) async {
      const key = ValueKey('dots-loader');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader.indeterminate(key: key),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader(
                key: key,
                progress: 0.4,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WigglyDotsLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts willAnimate false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader(
                progress: 0.5,
                willAnimate: false,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<WigglyDotsLoader>(
        find.byType(WigglyDotsLoader),
      );
      expect(widget.willAnimate, isFalse);
    });

    testWidgets('applies theme extension colors for default values',
        (tester) async {
      const themedColor = Color(0xFF16A34A);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              WigglyLoadersThemeData(dotsProgressColor: themedColor),
            ],
          ),
          home: const Scaffold(
            body: Center(
              child: WigglyDotsLoader(progress: 0.5),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyDotsLoader),
          matching: find.byType(CustomPaint),
        ),
      );

      final painter = customPaint.painter! as WigglyDotsPainter;
      expect(painter.progressColor, themedColor);
    });

    testWidgets('passes progressEndColor through to the painter',
        (tester) async {
      const endColor = Color(0xFFF97316);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader(
                progress: 0.5,
                progressEndColor: endColor,
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyDotsLoader),
          matching: find.byType(CustomPaint),
        ),
      );

      final painter = customPaint.painter! as WigglyDotsPainter;
      expect(painter.progressEndColor, endColor);
    });

    testWidgets('shared speed factor speeds up indeterminate dots motion',
        (tester) async {
      Future<double> pumpAndReadTravel({
        WigglyLoadersThemeData? theme,
      }) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: theme == null ? const [] : [theme],
            ),
            home: const Scaffold(
              body: Center(
                child: WigglyDotsLoader.indeterminate(willAnimate: false),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(WigglyDotsLoader),
            matching: find.byType(CustomPaint),
          ),
        );

        return (customPaint.painter! as WigglyDotsPainter).travel;
      }

      final defaultTravel = await pumpAndReadTravel();
      final fasterTravel = await pumpAndReadTravel(
        theme: const WigglyLoadersThemeData(speedFactor: 2.0),
      );

      expect(fasterTravel, greaterThan(defaultTravel));
    });

    testWidgets('softens wiggle amplitude when reduced motion is enabled',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: WigglyDotsLoader(
                  progress: 0.5,
                  wiggleAmplitude: 4,
                  willAnimate: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyDotsLoader),
          matching: find.byType(CustomPaint),
        ),
      );

      final painter = customPaint.painter! as WigglyDotsPainter;
      expect(painter.wiggleAmplitude, closeTo(2.6, 0.001));
    });

    testWidgets('sets default semantics for determinate dots loader',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader(progress: 0.42),
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(WigglyDotsLoader),
          matching: find.byType(Semantics),
        ),
      );
      expect(semantics.properties.label, 'Loading progress');
      expect(semantics.properties.value, '42 percent');
    });

    testWidgets('sets default semantics for indeterminate dots loader',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader.indeterminate(),
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(WigglyDotsLoader),
          matching: find.byType(Semantics),
        ),
      );
      expect(semantics.properties.label, 'Loading');
      expect(semantics.properties.value, isNull);
    });

    testWidgets('calls onComplete when progress reaches 1.0', (tester) async {
      var callCount = 0;
      const key = ValueKey('dots-complete');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader(
                key: key,
                progress: 0.6,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyDotsLoader(
                key: key,
                progress: 1.0,
                willAnimate: false,
                onComplete: () => callCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(callCount, 1);
    });
  });

  group('WigglyRefreshIndicator', () {
    test('asserts when refresh configuration is invalid', () {
      expect(
        () => WigglyRefreshIndicator(
          onRefresh: () async {},
          triggerDistance: 0,
          child: const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyRefreshIndicator(
          onRefresh: () async {},
          triggerDistance: 80,
          maxDragDistance: 40,
          child: const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglyRefreshIndicator(
          onRefresh: () async {},
          arcSpan: 1.2,
          child: const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

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

    testWidgets('accepts progressEndColor', (tester) async {
      const endColor = Color(0xFF22C55E);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WigglyRefreshIndicator(
              onRefresh: () async {},
              progressEndColor: endColor,
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
      expect(indicator.progressEndColor, endColor);
    });
  });
}
