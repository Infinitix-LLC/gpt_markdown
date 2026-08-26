import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';
import 'chat_scope.dart';

/// Three pulsing dots shown while waiting for the first token.
class ChatTypingDots extends StatefulWidget {
  const ChatTypingDots({super.key});

  @override
  State<ChatTypingDots> createState() => _ChatTypingDotsState();
}

class _ChatTypingDotsState extends State<ChatTypingDots>
    with SingleTickerProviderStateMixin {
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
      builder:
          (context, _) => Row(
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

/// Shown before the first message: a greeting, and suggestion chips when the
/// adapter offers them.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    this.title,
    this.subtitle,
    this.suggestions,
  });

  final String? title;
  final String? subtitle;

  /// Overrides the adapter's own suggestions. Null uses those, which are empty
  /// unless `capabilities.suggestions` is on.
  final List<String>? suggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = ChatScope.of(context);

    return Center(
      child: ChatColumn(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scope.theme.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? scope.theme.placeholder,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ChatSuggestionChips(suggestions: suggestions),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prompt suggestions. Tapping one prefills the composer rather than sending,
/// so the user can edit it first.
///
/// Collapses to nothing unless the adapter offers suggestions and
/// `ChatCapabilities.suggestions` is on.
class ChatSuggestionChips extends StatelessWidget {
  const ChatSuggestionChips({super.key, this.suggestions});

  /// Overrides the adapter's own suggestions.
  final List<String>? suggestions;

  @override
  Widget build(BuildContext context) {
    final controller = ChatScope.of(context).controller;
    final prompts = suggestions ?? controller.suggestions;
    if (prompts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final prompt in prompts)
          ActionChip(
            label: Text(prompt),
            onPressed: () => controller.prefill(prompt),
          ),
      ],
    );
  }
}

/// Dismissible banner for the last failure, with a retry shortcut.
class ChatErrorBar extends StatelessWidget {
  const ChatErrorBar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ChatScope.of(context).controller;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // The message is truncated to three lines, and a gateway failure
              // carries the status and body that make it diagnosable — so
              // offer the full text rather than making it re-typable by eye.
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => _copy(context),
                tooltip: 'Copy error',
                color: scheme.onErrorContainer,
              ),
              if (controller.capabilities.retry)
                TextButton(
                  onPressed: controller.onRetry,
                  child: const Text('Retry'),
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: controller.onClearError,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Error copied'),
          duration: Duration(seconds: 1),
        ),
      );
  }
}

/// Shown while the transcript is scrolled away from the newest message.
///
/// The counterpart to following-that-yields: the view stops chasing new tokens
/// the moment the user scrolls up, and this is how they get back.
class ChatJumpToLatest extends StatelessWidget {
  const ChatJumpToLatest({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = controller.canJumpToLatest;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      offset: visible ? Offset.zero : const Offset(0, 0.6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: scheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                tooltip: 'Jump to latest',
                onPressed: controller.onJumpToLatest,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
