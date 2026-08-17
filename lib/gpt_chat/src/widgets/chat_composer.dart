import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';
import 'chat_attachments.dart';
import 'chat_scope.dart';

/// The floating composer.
///
/// Layout, top to bottom: banners, suggestions, staged attachments, then the
/// input row — leading controls, the field, trailing controls, send.
///
/// Text and focus live on the [ChatController], not here, so a replacement
/// composer drives the same objects and can prefill or clear them.
///
/// The package ships no file-picker dependency, so there is no default attach
/// button. Add one through `ChatBuilders.composerLeading` using
/// [ChatAttachButton], wired to whatever picker the app already uses.
class ChatComposer extends StatelessWidget {
  const ChatComposer({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final scope = ChatScope.of(context);
    final theme = scope.theme;
    final builders = scope.builders;

    ChatSlot plain(Widget child) => ChatSlot(
      context: context,
      controller: controller,
      theme: theme,
      child: child,
    );

    final above = scope.build(
      builders.composerAbove,
      plain(const SizedBox.shrink()),
    );
    final suggestions = scope.build(
      builders.composerSuggestions,
      plain(const SizedBox.shrink()),
    );
    final attachmentPreview = scope.build(
      builders.composerAttachments,
      plain(
        controller.capabilities.attachments
            ? ChatAttachmentStrip(
              attachments: controller.attachments,
              isStaged: true,
            )
            : const SizedBox.shrink(),
      ),
    );
    final field = scope.build(
      builders.composerField,
      plain(ChatComposerField(controller: controller)),
    );
    final send = scope.build(
      builders.composerSend,
      plain(ChatSendButton(controller: controller)),
    );
    final stop = scope.build(
      builders.composerStop,
      plain(ChatStopButton(controller: controller)),
    );

    final leading = [
      for (final build
          in builders.composerLeading ?? const <ChatBuild<ChatSlot>>[])
        build(plain(const SizedBox.shrink())),
    ];
    final trailing = [
      for (final build
          in builders.composerTrailing ?? const <ChatBuild<ChatSlot>>[])
        build(plain(const SizedBox.shrink())),
    ];

    // Stop takes the send button's place while a reply streams — same spot,
    // so the control the user is already aiming at is the one that cancels.
    final showStop = controller.isResponding && controller.capabilities.stop;

    final bar = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ChatColumn(
          maxWidth: theme.composerWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              above,
              suggestions,
              Material(
                elevation: theme.composerElevation ?? 0,
                color: theme.composerColor,
                borderRadius: theme.composerRadius,
                child: Padding(
                  padding: theme.composerPadding ?? EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      attachmentPreview,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ...leading,
                          Expanded(child: field),
                          ...trailing,
                          if (showStop) stop else send,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return scope.build(
      builders.composer,
      ChatComposerSlot(
        context: context,
        controller: controller,
        theme: theme,
        field: field,
        send: send,
        stop: stop,
        attachmentPreview: attachmentPreview,
        suggestions: suggestions,
        above: above,
        leading: leading,
        trailing: trailing,
        child: bar,
      ),
    );
  }
}

/// The text field, with Enter to send and Shift+Enter for a newline.
class ChatComposerField extends StatelessWidget {
  const ChatComposerField({super.key, required this.controller, this.hintText});

  final ChatController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final theme = ChatScope.of(context).theme;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
      },
      child: Actions(
        actions: {
          _SendIntent: CallbackAction<_SendIntent>(
            onInvoke: (_) {
              if (controller.canSend) controller.onSend();
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
          style: theme.answerTextStyle,
          decoration: InputDecoration(
            hintText: hintText ?? theme.placeholder,
            hintStyle: theme.composerHintStyle,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sends the draft. Disabled while there is nothing to send.
class ChatSendButton extends StatelessWidget {
  const ChatSendButton({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ChatScope.of(context).theme;

    return ChatComposerButton(
      onPressed: controller.canSend ? controller.onSend : null,
      icon: Icons.arrow_upward_rounded,
      tooltip: 'Send',
      background: theme.sendButtonColor,
      foreground: theme.sendButtonForegroundColor,
    );
  }
}

/// Cancels the in-flight reply, keeping the text that already arrived.
///
/// Takes the send button's place while a reply streams.
class ChatStopButton extends StatelessWidget {
  const ChatStopButton({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ChatScope.of(context).theme;

    return ChatComposerButton(
      onPressed: controller.onStop,
      icon: Icons.stop_rounded,
      tooltip: 'Stop',
      background: theme.stopButtonColor,
      foreground: theme.sendButtonForegroundColor,
    );
  }
}

/// The round filled button the composer uses, so a custom send or stop keeps
/// the same shape without copying its metrics.
class ChatComposerButton extends StatelessWidget {
  const ChatComposerButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.background,
    this.foreground,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
      ),
    );
  }
}

/// An attach affordance for `ChatBuilders.composerLeading`.
///
/// The package deliberately ships no picker dependency — wire this to whatever
/// the app already uses and hand the result to
/// `controller.addAttachment(...)`.
class ChatAttachButton extends StatelessWidget {
  const ChatAttachButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip = 'Attach',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: IconButton(
        icon: Icon(icon, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}
