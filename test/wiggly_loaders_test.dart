import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiggly_loaders/wiggly_loaders.dart';
import 'package:wiggly_loaders/src/internal/wiggly_arc_canvas.dart';
import 'package:wiggly_loaders/src/internal/wiggly_arc_painter.dart';
import 'package:wiggly_loaders/src/internal/wiggly_dots_painter.dart';
import 'package:wiggly_loaders/src/internal/wiggly_linear_painter.dart';
import 'package:wiggly_loaders/src/internal/wiggly_skeleton_painter.dart';
import 'package:wiggly_loaders/src/internal/wiggly_button_painter.dart';

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

    testWidgets('controller can pause and resume indeterminate motion',
        (tester) async {
      final controller = WigglyController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader.indeterminate(
                controller: controller,
                willAnimate: false,
              ),
            ),
          ),
        ),
      );

      double rotationValue() {
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(WigglyLoader),
            matching: find.byType(CustomPaint),
          ),
        );
        return (customPaint.painter! as WigglyArcPainter).rotation;
      }

      await tester.pump(const Duration(milliseconds: 250));
      final beforePause = rotationValue();

      controller.pause();
      await tester.pump(const Duration(milliseconds: 250));
      final paused = rotationValue();

      controller.resume();
      await tester.pump(const Duration(milliseconds: 100));
      final resumedStart = rotationValue();
      await tester.pump(const Duration(milliseconds: 200));
      final resumedEnd = rotationValue();

      expect(paused, closeTo(beforePause, 0.0001));
      expect(resumedEnd, isNot(closeTo(resumedStart, 0.0001)));
      expect(controller.status, WigglyControllerStatus.playing);
    });

    testWidgets('controller can override progress and emit completed status',
        (tester) async {
      final controller = WigglyController();
      final statuses = <WigglyControllerStatus>[];
      controller.addStatusListener(statuses.add);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLoader.indeterminate(
                controller: controller,
                willAnimate: false,
              ),
            ),
          ),
        ),
      );

      controller.jumpTo(0.65);
      await tester.pump();

      var customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglyLoader),
          matching: find.byType(CustomPaint),
        ),
      );
      var painter = customPaint.painter! as WigglyArcPainter;
      expect(painter.indeterminate, isFalse);
      expect(painter.progress, closeTo(0.65, 0.001));

      controller.jumpTo(1.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(statuses, contains(WigglyControllerStatus.completed));
      expect(controller.progress, 1.0);
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

    testWidgets('global debug flag enables linear debug overlay',
        (tester) async {
      addTearDown(() => debugWigglyLoaders = false);
      debugWigglyLoaders = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyLinearLoader(progress: 0.4),
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
      expect(painter.debug, isTrue);
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

  group('WigglySkeletonLoader', () {
    test('asserts when geometry is invalid', () {
      expect(
        () => WigglySkeletonLoader(height: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglySkeletonLoader(borderRadius: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglySkeletonLoader(waveLength: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglySkeletonLoader.text(lines: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WigglySkeletonLoader.text(lastLineFraction: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('renders block variant without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglySkeletonLoader(width: 200, height: 16),
            ),
          ),
        ),
      );
      expect(find.byType(WigglySkeletonLoader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders text preset with line count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: WigglySkeletonLoader.text(lines: 4),
            ),
          ),
        ),
      );
      // 4 lines = 4 painters
      expect(
        find.descendant(
          of: find.byType(WigglySkeletonLoader),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('renders card preset with avatar + lines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: WigglySkeletonLoader.card(lines: 3),
            ),
          ),
        ),
      );
      // 1 avatar + 3 lines = 4 painters
      expect(
        find.descendant(
          of: find.byType(WigglySkeletonLoader),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('applies theme skeleton colors when defaults are used',
        (tester) async {
      const themedBase = Color(0xFFD1D5DB);
      const themedHighlight = Color(0xFFFAFAFA);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              WigglyLoadersThemeData(
                skeletonBaseColor: themedBase,
                skeletonHighlightColor: themedHighlight,
              ),
            ],
          ),
          home: const Scaffold(
            body: Center(
              child: WigglySkeletonLoader(width: 100, height: 14),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglySkeletonLoader),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as WigglySkeletonPainter;
      expect(painter.baseColor, themedBase);
      expect(painter.highlightColor, themedHighlight);
    });

    testWidgets('softens wave amplitude under reduced motion', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: WigglySkeletonLoader(
                  width: 120,
                  height: 16,
                  waveAmplitude: 6,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(WigglySkeletonLoader),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as WigglySkeletonPainter;
      expect(painter.waveAmplitude, closeTo(3.0, 0.001));
    });

    testWidgets('does not animate when willAnimate is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglySkeletonLoader(
                width: 100,
                height: 14,
                willAnimate: false,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<WigglySkeletonLoader>(
        find.byType(WigglySkeletonLoader),
      );
      expect(widget.willAnimate, isFalse);
    });
  });

  group('WigglyProgressButton', () {
    testWidgets('renders idle child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: WigglyButtonState.idle,
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(WigglyProgressButton), findsOneWidget);
    });

    testWidgets('shows dots in loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: WigglyButtonState.loading,
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.descendant(
          of: find.byType(WigglyProgressButton),
          matching: find.byType(WigglyDotsLoader),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows check icon in success state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: WigglyButtonState.success,
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('shows close icon in error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: WigglyButtonState.error,
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('onPressed only fires when idle', (tester) async {
      var calls = 0;
      Widget build(WigglyButtonState state) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: state,
                onPressed: () => calls++,
                child: const Text('Go'),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(WigglyButtonState.idle));
      await tester.tap(find.byType(WigglyProgressButton));
      await tester.pump();
      expect(calls, 1);

      await tester.pumpWidget(build(WigglyButtonState.loading));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(WigglyProgressButton), warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('fires onComplete when transitioning into success',
        (tester) async {
      var completed = 0;
      Widget build(WigglyButtonState state) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: state,
                onPressed: () {},
                onComplete: () => completed++,
                child: const Text('Save'),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(WigglyButtonState.loading));
      await tester.pump(const Duration(milliseconds: 200));
      expect(completed, 0);

      await tester.pumpWidget(build(WigglyButtonState.success));
      await tester.pump(const Duration(milliseconds: 400));
      expect(completed, 1);

      // Re-rendering same success state must not re-fire.
      await tester.pumpWidget(build(WigglyButtonState.success));
      await tester.pump(const Duration(milliseconds: 100));
      expect(completed, 1);
    });

    testWidgets('applies theme button colors', (tester) async {
      const successColor = Color(0xFF065F46);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              WigglyLoadersThemeData(buttonSuccessColor: successColor),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: WigglyProgressButton(
                state: WigglyButtonState.success,
                onPressed: () {},
                child: const Text('Done'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final paints = find
          .descendant(
            of: find.byType(WigglyProgressButton),
            matching: find.byType(CustomPaint),
          )
          .evaluate()
          .map((e) => (e.widget as CustomPaint).painter)
          .whereType<WigglyButtonPainter>()
          .toList();

      expect(paints, isNotEmpty);
      expect(paints.first.fillColor, successColor);
    });
  });
}
