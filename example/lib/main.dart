import 'package:flutter/material.dart';
import 'package:wiggly_loaders/wiggly_loaders.dart';

void main() => runApp(const WigglyLoadersExample());

class WigglyLoadersExample extends StatelessWidget {
  const WigglyLoadersExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wiggly Loaders Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
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
  double _progress = 0.65;

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wiggly Demo'),
      ),
      body: WigglyRefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.all(32),
          children: [
            const _SectionTitle('WigglyLoader — determinate'),
            const SizedBox(height: 16),
            Center(
              child: WigglyLoader(
                trackColor: Colors.transparent,
                progress: _progress,
                size: 80,
                child: Text('${(_progress * 100).round()}%'),
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
            ),
            const SizedBox(height: 24),
            const _LoaderPreviewCard(
              title: 'WigglyLoader — indeterminate',
              child: Center(
                child: WigglyLoader.indeterminate(
                  trackColor: Colors.transparent,
                  progressColor: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _LoaderPreviewCard(
              title: 'WigglyLinearLoader — determinate',
              child: WigglyLinearLoader(
                progress: _progress,
                trackColor: Colors.transparent,
                height: 12,
                wiggleAmplitude: 4.0,
              ),
            ),
            const SizedBox(height: 24),
            const _LoaderPreviewCard(
              title: 'WigglyLinearLoader — indeterminate',
              child: WigglyLinearLoader.indeterminate(
                progressColor: Color(0xFF10B981),
                height: 12,
                wiggleAmplitude: 4.0,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Pull down anywhere on this screen to trigger WigglyRefreshIndicator.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 240),
          ],
        ),
      ),
    );
  }
}

class _LoaderPreviewCard extends StatelessWidget {
  const _LoaderPreviewCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}