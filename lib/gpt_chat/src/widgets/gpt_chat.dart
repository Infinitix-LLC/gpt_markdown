import 'package:flutter/material.dart';

import '../../../gen_ui/gen_ui_registry.dart';
import '../adapter/chat_adapter.dart';
import '../adapter/chat_model_source.dart';
import '../builders/chat_builders.dart';
import '../controller/chat_controller.dart';
import '../theme/chat_theme.dart';
import 'chat_scope.dart';
import 'chat_view.dart';

/// A complete chat screen, driven by a [ChatAdapter].
///
/// ```dart
/// GptChat(adapter: MyAdapter())
/// ```
///
/// Customization is progressive, and in this order:
///
/// 1. [theme] — colours, radii, spacing, widths, typography. Most apps stop here.
/// 2. [builders] — replace or decorate individual parts. Each builder receives
///    the default widget *and* the parts that composed it, so overriding one
///    level never means rebuilding the levels beneath it.
/// 3. Drop [GptChat] entirely: put a [ChatScope] above your own page and use the
///    exported widgets à la carte.
class GptChat extends StatefulWidget {
  const GptChat({
    super.key,
    required this.adapter,
    this.models,
    this.builders = const ChatBuilders(),
    this.theme,
    this.genUiRegistry,
    this.controller,
    this.appBarActions = const [],
    this.onControllerReady,
  });

  /// Where the conversation comes from. Extend [StreamingChatAdapter] if the app
  /// has no state layer of its own; extend [ChatAdapter] if it does.
  ///
  /// Not disposed here — an adapter usually outlives the screen. Dispose it
  /// wherever it was created.
  final ChatAdapter adapter;

  /// Optional model list. Without one, no picker is shown.
  final ChatModelSource? models;

  /// Per-part overrides for the default UI.
  final ChatBuilders builders;

  /// Overrides the ambient [ChatTheme] extension.
  final ChatTheme? theme;

  /// Renders the widgets a model draws inside replies.
  final GenUiRegistry? genUiRegistry;

  /// Supply one to drive the chat from outside — prefilling the composer,
  /// sending programmatically, scrolling. Created internally when omitted.
  final ChatController? controller;

  /// Appended to the default app-bar actions.
  final List<Widget> appBarActions;

  /// Called once the controller exists.
  final void Function(ChatController controller)? onControllerReady;

  @override
  State<GptChat> createState() => _GptChatState();
}

class _GptChatState extends State<GptChat> {
  late ChatController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _createController();
    widget.adapter.init();
  }

  void _createController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        ChatController(adapter: widget.adapter, models: widget.models);
    widget.onControllerReady?.call(_controller);
  }

  @override
  void didUpdateWidget(GptChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adapter == oldWidget.adapter &&
        widget.models == oldWidget.models &&
        widget.controller == oldWidget.controller) {
      return;
    }

    if (_ownsController) _controller.dispose();
    _createController();
    if (widget.adapter != oldWidget.adapter) widget.adapter.init();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScope(
      controller: _controller,
      theme: ChatTheme.of(context, widget.theme),
      builders: widget.builders,
      genUi: widget.genUiRegistry,
      child: ChatView(appBarActions: widget.appBarActions),
    );
  }
}
