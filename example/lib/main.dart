import 'package:flutter/material.dart';
import 'package:wiggly_loaders/wiggly_loaders.dart';

void main() => runApp(const WigglyLoadersExample());

class WigglyLoadersExample extends StatelessWidget {
  const WigglyLoadersExample({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF111827);
    const accentSoft = Color(0xFFE5E7EB);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wiggly Loaders',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.copyWith(
              displayLarge: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w700,
                letterSpacing: -2.4,
                height: 0.96,
              ),
              displayMedium: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.8,
                height: 1,
              ),
              headlineMedium: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.0,
                height: 1.08,
              ),
              titleLarge: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              titleMedium: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              bodyLarge: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4B5563),
              ),
            ),
        dividerColor: const Color(0xFFE5E7EB),
        cardTheme: const CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
        ),
        extensions: const [
          WigglyLoadersThemeData(
            progressColor: accent,
            trackColor: accentSoft,
            backgroundColor: Colors.white,
            sizeScale: 1.08,
            strokeWidthScale: 1.08,
            speedFactor: 1.05,
            ease: Curves.easeOutCubic,
          ),
        ],
      ),
      home: const _DemoPage(),
    );
  }
}

class _DemoPage extends StatefulWidget {
  const _DemoPage();

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  double _progress = 0.72;
  bool _simulateReducedMotion = false;
  bool _debugOverlay = false;
  final WigglyController _controller = WigglyController();

  @override
  void dispose() {
    debugWigglyLoaders = false;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5F5F7),
            ],
          ),
        ),
        child: SafeArea(
          child: MediaQuery(
            data:
                mediaQuery.copyWith(disableAnimations: _simulateReducedMotion),
            child: WigglyRefreshIndicator(
              onRefresh: _handleRefresh,
              triggerDistance: 90,
              maxDragDistance: 150,
              notificationPredicate: (notification) => notification.depth == 0,
              semanticsLabel: 'Refresh example content',
              child: ListView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 56),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1060),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(
                              simulateReducedMotion: _simulateReducedMotion),
                          const SizedBox(height: 20),
                          _Hero(
                            progress: _progress,
                            onProgressChanged: (value) {
                              setState(() => _progress = value);
                            },
                          ),
                          const SizedBox(height: 56),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 860;

                              if (stacked) {
                                return Column(
                                  children: [
                                    _FeaturePanel(
                                      progress: _progress,
                                      simulateReducedMotion:
                                          _simulateReducedMotion,
                                      debugOverlay: _debugOverlay,
                                      onReducedMotionChanged: (value) {
                                        setState(
                                          () => _simulateReducedMotion = value,
                                        );
                                      },
                                      onDebugOverlayChanged: (value) {
                                        setState(() => _debugOverlay = value);
                                        debugWigglyLoaders = value;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _LoaderGrid(
                                      progress: _progress,
                                      controller: _controller,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _FeaturePanel(
                                      progress: _progress,
                                      simulateReducedMotion:
                                          _simulateReducedMotion,
                                      debugOverlay: _debugOverlay,
                                      onReducedMotionChanged: (value) {
                                        setState(
                                          () => _simulateReducedMotion = value,
                                        );
                                      },
                                      onDebugOverlayChanged: (value) {
                                        setState(() => _debugOverlay = value);
                                        debugWigglyLoaders = value;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 6,
                                    child: _LoaderGrid(
                                      progress: _progress,
                                      controller: _controller,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 56),
                          const _UsageSection(),
                          const SizedBox(height: 28),
                          const _RefreshFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.simulateReducedMotion,
  });

  final bool simulateReducedMotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Wiggly Loaders',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            simulateReducedMotion ? 'Reduced Motion On' : 'Reduced Motion Off',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.progress,
    required this.onProgressChanged,
  });

  final double progress;
  final ValueChanged<double> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressLabel = '${(progress * 100).round()}%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 820;

        final copy = Expanded(
          flex: stacked ? 0 : 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'A minimal loader system for Flutter with circular, linear, dot, and refresh variants that feel related without demanding attention.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Slider(
                      value: progress,
                      onChanged: onProgressChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    progressLabel,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        );

        final preview = Expanded(
          flex: stacked ? 0 : 5,
          child: Align(
            alignment: stacked ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Current Preview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 18),
                  WigglyLoader(
                    progress: progress,
                    size: 110,
                    strokeWidth: 5,
                    progressEndColor: const Color(0xFF2563EB),
                    child: Text(
                      progressLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  WigglyLinearLoader(
                    progress: progress,
                    height: 10,
                    progressEndColor: const Color(0xFF2563EB),
                    semanticsLabel: 'Preview progress',
                    semanticsValue: '$progressLabel complete',
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Syncing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      WigglyDotsLoader.indeterminate(
                        dotCount: 3,
                        dotSize: 8,
                        spacing: 7,
                        semanticsLabel: 'Syncing',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 28),
              preview,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            copy,
            const SizedBox(width: 28),
            preview,
          ],
        );
      },
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel({
    required this.progress,
    required this.simulateReducedMotion,
    required this.debugOverlay,
    required this.onReducedMotionChanged,
    required this.onDebugOverlayChanged,
  });

  final double progress;
  final bool simulateReducedMotion;
  final bool debugOverlay;
  final ValueChanged<bool> onReducedMotionChanged;
  final ValueChanged<bool> onDebugOverlayChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why it feels calm',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const _FeatureLine(
            title: 'Consistent motion language',
            body:
                'Circular, linear, and dot loaders share the same visual DNA.',
          ),
          const Divider(height: 32),
          const _FeatureLine(
            title: 'Compact by default',
            body:
                'Useful in buttons, cards, chat rows, and long-running tasks.',
          ),
          const Divider(height: 32),
          _FeatureLine(
            title: 'Accessible motion control',
            body: simulateReducedMotion
                ? 'Reduced motion is active and the loaders already soften their movement.'
                : 'Toggle reduced motion to preview softer animation behavior.',
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            value: simulateReducedMotion,
            contentPadding: EdgeInsets.zero,
            onChanged: onReducedMotionChanged,
            title: const Text(
              'Simulate reduced motion',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Progress preview: ${(progress * 100).round()}%',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          const Divider(height: 12),
          SwitchListTile.adaptive(
            value: debugOverlay,
            contentPadding: EdgeInsets.zero,
            onChanged: onDebugOverlayChanged,
            title: const Text(
              'Enable debug overlay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Shows wave guides and sample points across loaders.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoaderGrid extends StatelessWidget {
  const _LoaderGrid({
    required this.progress,
    required this.controller,
  });

  final double progress;
  final WigglyController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoaderCard(
          title: 'Circular',
          subtitle: 'For focused progress and standalone status.',
          child: Center(
            child: WigglyLoader(
              progress: progress,
              size: 88,
              progressEndColor: const Color(0xFF2563EB),
              child: Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LoaderCard(
          title: 'Controller Playground',
          subtitle:
              'Pause, resume, or jump from looping motion into exact progress.',
          child: _ControllerDemo(controller: controller),
        ),
        const SizedBox(height: 16),
        _LoaderCard(
          title: 'Inline Dots',
          subtitle: 'For compact status inside buttons, rows, and sends.',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preparing assets',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              WigglyDotsLoader(
                progress: progress,
                dotCount: 5,
                dotSize: 10,
                spacing: 8,
                progressEndColor: const Color(0xFF2563EB),
                semanticsLabel: 'Preparing assets',
                semanticsValue: '${(progress * 100).round()} percent',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _LoaderCard(
          title: 'Linear',
          subtitle: 'For transfer progress, sync tasks, and content loading.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WigglyLinearLoader(
                progress: progress,
                height: 10,
                progressEndColor: const Color(0xFF2563EB),
                semanticsLabel: 'Transfer progress',
                semanticsValue: '${(progress * 100).round()} percent',
              ),
              const SizedBox(height: 12),
              Text(
                'Upload in progress',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _LoaderCard(
          title: 'Skeleton',
          subtitle:
              'Wave-based shimmer that travels across cards and text rows.',
          child: WigglySkeletonLoader.card(
            avatarSize: 48,
            lines: 3,
          ),
        ),
        const SizedBox(height: 16),
        const _LoaderCard(
          title: 'Progress Button',
          subtitle:
              'A self-animating action button that morphs between idle, loading, success, and error.',
          child: Center(child: _ProgressButtonDemo()),
        ),
      ],
    );
  }
}

class _ProgressButtonDemo extends StatefulWidget {
  const _ProgressButtonDemo();

  @override
  State<_ProgressButtonDemo> createState() => _ProgressButtonDemoState();
}

class _ProgressButtonDemoState extends State<_ProgressButtonDemo> {
  WigglyButtonState _state = WigglyButtonState.idle;
  bool _failNext = false;

  Future<void> _runFlow() async {
    setState(() => _state = WigglyButtonState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _state = _failNext ? WigglyButtonState.error : WigglyButtonState.success;
      _failNext = !_failNext;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _state = WigglyButtonState.idle);
  }

  @override
  Widget build(BuildContext context) {
    return WigglyProgressButton(
      state: _state,
      onPressed: _runFlow,
      width: 220,
      height: 52,
      progressColor: const Color(0xFF111827),
      child: const Text('Submit'),
    );
  }
}

class _ControllerDemo extends StatefulWidget {
  const _ControllerDemo({
    required this.controller,
  });

  final WigglyController controller;

  @override
  State<_ControllerDemo> createState() => _ControllerDemoState();
}

class _ControllerDemoState extends State<_ControllerDemo> {
  double _progress = 0.38;
  late WigglyControllerStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.controller.status;
    widget.controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant _ControllerDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeStatusListener(_handleStatusChanged);
    widget.controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  void _handleStatusChanged(WigglyControllerStatus status) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _status == status) return;
      setState(() => _status = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            WigglyLoader.indeterminate(
              controller: widget.controller,
              willAnimate: false,
              size: 76,
              progressEndColor: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${_status.name.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drive a loader like a tiny Lottie instance: freeze it, resume it, or snap to a milestone.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Slider(
          value: _progress,
          onChanged: (value) {
            setState(() => _progress = value);
            widget.controller.jumpTo(value);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: widget.controller.pause,
              child: const Text('Pause'),
            ),
            OutlinedButton(
              onPressed: widget.controller.resume,
              child: const Text('Resume'),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() => _progress = 1.0);
                widget.controller.jumpTo(1.0);
              },
              child: const Text('Jump to 100%'),
            ),
            OutlinedButton(
              onPressed: widget.controller.clearProgress,
              child: const Text('Back to loop'),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typical placements',
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'The package works best when the loading state supports the interface instead of dominating it.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 860;

            final cards = [
              const _MiniUsageCard(
                title: 'Primary Button',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sending',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 10),
                    _MiniDots(),
                  ],
                ),
              ),
              const _MiniUsageCard(
                title: 'Progress Tile',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Downloading design-system.sketch',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 12),
                    WigglyLinearLoader.indeterminate(
                      height: 8,
                      semanticsLabel: 'Downloading file',
                    ),
                  ],
                ),
              ),
              const _MiniUsageCard(
                title: 'Refresh State',
                child: Center(
                  child: Text(
                    'Pull down on this page\nto preview refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const _MiniUsageCard(
                title: 'Skeleton Rows',
                child: WigglySkeletonLoader.text(
                  lines: 4,
                  lineHeight: 10,
                  lineSpacing: 10,
                ),
              ),
            ];

            if (stacked) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i != 0) const SizedBox(height: 14),
                    cards[i],
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i != 0) const SizedBox(width: 14),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RefreshFooter extends StatelessWidget {
  const _RefreshFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pull to refresh this page to preview the custom refresh indicator in context.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoaderCard extends StatelessWidget {
  const _LoaderCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _MiniUsageCard extends StatelessWidget {
  const _MiniUsageCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _MiniDots extends StatelessWidget {
  const _MiniDots();

  @override
  Widget build(BuildContext context) {
    return const WigglyDotsLoader.indeterminate(
      dotCount: 3,
      dotSize: 8,
      spacing: 6,
      semanticsLabel: 'Sending',
    );
  }
}
