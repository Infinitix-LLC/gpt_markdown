import 'package:flutter/material.dart';

/// Three pulsing dots shown while waiting for the first token.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_controller.value - i * 0.2) % 1.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Opacity(
              opacity: 0.3 + 0.7 * (1 - (phase * 2 - 1).abs()),
              child: CircleAvatar(radius: 3, backgroundColor: color),
            ),
          );
        }),
      ),
    );
  }
}
