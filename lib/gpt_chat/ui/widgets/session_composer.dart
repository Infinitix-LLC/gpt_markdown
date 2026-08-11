import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/chat_controller.dart';
import 'chat_scope.dart';
import 'session_layout.dart';
import 'session_model_picker.dart';

/// The floating composer: the text field on top, an action row beneath it
/// holding the model picker and the send button.
///
/// Splitting the controls onto their own row is what makes room for the model
/// pill without squeezing the text, and it puts the model choice next to Send —
/// the model is a property of the message you are about to send, so it belongs
/// where you decide to send it.
///
/// Text and focus live on the [ChatController], not here, so a replacement
/// composer can drive the same objects and prefill or clear them.
class SessionComposer extends StatelessWidget {
  const SessionComposer({
    super.key,
    required this.controller,
    this.hintText = 'Message',
    this.showModelSelector = true,
  });

  final ChatController controller;
  final String hintText;
  final bool showModelSelector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final builders = ChatScope.of(context).builders;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SessionLayout.constrain(
          Material(
            elevation: 3,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.18),
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Shortcuts(
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
                      },
                      child: Actions(
                        actions: {
                          _SendIntent: CallbackAction<_SendIntent>(
                            onInvoke: (_) {
                              _submit();
                              return null;
                            },
                          ),
                        },
                        child: TextField(
                          controller: controller.input,
                          focusNode: controller.inputFocusNode,
                          minLines: 1,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: hintText,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (showModelSelector)
                        builders.modelSelector?.call(context, controller) ??
                            SessionModelSelector(controller: controller),
                      const Spacer(),
                      builders.sendButton?.call(context, controller) ??
                          SessionSendButton(controller: controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
          maxWidth: SessionLayout.composerMaxWidth,
        ),
      ),
    );
  }

  void _submit() {
    if (!controller.canSend) return;
    controller.onSend();
  }
}

/// Send while idle, stop while a reply streams.
class SessionSendButton extends StatelessWidget {
  const SessionSendButton({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isResponding = controller.isResponding;

    return IconButton.filled(
      onPressed: isResponding
          ? controller.onStop
          : (controller.canSend ? controller.onSend : null),
      icon: Icon(
        isResponding ? Icons.stop_rounded : Icons.arrow_upward_rounded,
        size: 20,
      ),
      tooltip: isResponding ? 'Stop' : 'Send',
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: isResponding ? scheme.error : scheme.primary,
        foregroundColor: isResponding ? scheme.onError : scheme.onPrimary,
      ),
    );
  }
}

/// Shown while the transcript is scrolled away from the newest message.
///
/// This is the counterpart to following-that-yields: the view stops chasing new
/// tokens the moment the user scrolls up, and this is how they get back.
class SessionJumpToLatest extends StatelessWidget {
  const SessionJumpToLatest({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      offset: controller.canJumpToLatest ? Offset.zero : const Offset(0, 0.6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: controller.canJumpToLatest ? 1 : 0,
        child: IgnorePointer(
          ignoring: !controller.canJumpToLatest,
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

class _SendIntent extends Intent {
  const _SendIntent();
}
