import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../adapter/chat_model_source.dart';
import '../builders/chat_slots.dart';
import '../controller/chat_controller.dart';
import 'chat_scope.dart';

/// The model pill.
///
/// Tapping opens a sheet rather than a popup menu: model names are long, the
/// list grows, and a sheet gives each row room for a description.
class ChatModelPicker extends StatefulWidget {
  const ChatModelPicker({super.key, required this.controller});

  final ChatController controller;

  @override
  State<ChatModelPicker> createState() => _ChatModelPickerState();
}

class _ChatModelPickerState extends State<ChatModelPicker> {
  @override
  void initState() {
    super.initState();
    // The list is usually a network call; deferring keeps it off the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.onLoadModels();
    });
  }

  Future<void> _open() async {
    HapticFeedback.lightImpact();
    // Drop the keyboard first, or the sheet fights it for the bottom half.
    FocusManager.instance.primaryFocus?.unfocus();

    final scope = ChatScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ChatScope(
        controller: scope.controller,
        theme: scope.theme,
        builders: scope.builders,
        genUi: scope.genUi,
        child: ChatModelSheet(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final selected = widget.controller.selectedModel;
    final label = widget.controller.availableModels
        .where((m) => m.id == selected)
        .map((m) => m.name)
        .firstOrNull;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _open,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label ?? selected,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more,
              size: 20,
              color: foreground.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sheet listing every model the source offers.
class ChatModelSheet extends StatelessWidget {
  const ChatModelSheet({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = ChatScope.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // The configured model may not be in the fetched list — a failed or
        // pending lookup must not make the current choice disappear.
        final options = <ChatModelOption>[
          ...controller.availableModels,
          if (!controller.availableModels.any(
            (m) => m.id == controller.selectedModel,
          ))
            ChatModelOption(id: controller.selectedModel),
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Model', style: theme.textTheme.titleMedium),
              ),
              if (controller.isLoadingModels)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.id == controller.selectedModel;

                    return scope.build(
                      scope.builders.modelTile,
                      ChatModelSlot(
                        context: context,
                        controller: controller,
                        theme: scope.theme,
                        model: option,
                        isSelected: isSelected,
                        child: ListTile(
                          selected: isSelected,
                          title: Text(option.name),
                          subtitle: option.description == null
                              ? null
                              : Text(option.description!),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, size: 20)
                              : null,
                          onTap: () {
                            controller.onModelChoose(option.id);
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (controller.modelError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    controller.modelError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
