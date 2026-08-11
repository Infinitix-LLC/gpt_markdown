import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/chat_controller.dart';

/// Model picker pill, sized to sit in the composer's action row.
///
/// It lives with the composer rather than in the app bar because the model is
/// a property of the message you are about to send — it belongs next to the
/// send button, where you decide, not in the title bar.
///
/// Tapping opens a sheet rather than a popup menu: model names are long, the
/// list grows, and a sheet gives each row room for a description.
class SessionModelSelector extends StatefulWidget {
  const SessionModelSelector({super.key, required this.controller});

  final ChatController controller;

  @override
  State<SessionModelSelector> createState() => _SessionModelSelectorState();
}

class _SessionModelSelectorState extends State<SessionModelSelector> {
  @override
  void initState() {
    super.initState();
    // The list is a network call; deferring it keeps it off the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.onLoadModels();
    });
  }

  Future<void> _open() async {
    HapticFeedback.lightImpact();
    // Drop the keyboard first, or the sheet fights it for the bottom half.
    FocusManager.instance.primaryFocus?.unfocus();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SessionModelSheet(controller: widget.controller),
    );

    if (mounted) widget.controller.inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _open,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: foreground.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                widget.controller.selectedModel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 18,
              color: foreground.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sheet listing every model the gateway offers.
class SessionModelSheet extends StatelessWidget {
  const SessionModelSheet({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // The configured model may not be in the fetched list — a failed or
        // pending lookup must not make the current choice disappear.
        final ids = <String>{
          controller.selectedModel,
          ...controller.availableModels.map((model) => model.id),
        }.toList();

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
                  itemCount: ids.length,
                  itemBuilder: (context, index) {
                    final id = ids[index];
                    final isSelected = id == controller.selectedModel;

                    return ListTile(
                      selected: isSelected,
                      title: Text(id),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                      onTap: () {
                        controller.onModelChoose(id);
                        Navigator.of(context).maybePop();
                      },
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
