import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_scope.dart';

/// Composer. Owns only the text controller; sending is delegated to the view model.
class ChatInputBox extends StatefulWidget {
  const ChatInputBox({super.key, required this.isResponding, this.hintText = 'Message'});

  final bool isResponding;
  final String hintText;

  @override
  State<ChatInputBox> createState() => _ChatInputBoxState();
}

class _ChatInputBoxState extends State<ChatInputBox> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    _controller.clear();
    ChatScope.of(context).chat.send(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Shortcuts(
                shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): _SendIntent()},
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
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(isResponding: widget.isResponding, onSend: _submit),
          ],
        ),
      ),
    );
  }
}

/// Send while idle, stop while a reply streams.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.isResponding, required this.onSend});

  final bool isResponding;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton.filled(
      onPressed: isResponding ? ChatScope.of(context).chat.stop : onSend,
      icon: Icon(isResponding ? Icons.stop_rounded : Icons.arrow_upward_rounded),
      tooltip: isResponding ? 'Stop' : 'Send',
      style: IconButton.styleFrom(
        backgroundColor: isResponding ? scheme.error : scheme.primary,
        foregroundColor: isResponding ? scheme.onError : scheme.onPrimary,
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}
