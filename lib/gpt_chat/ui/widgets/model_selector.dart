import 'package:flutter/material.dart';

import 'chat_scope.dart';

/// Model picker. OpenAI and Gemini ids share one list.
class ModelSelector extends StatefulWidget {
  const ModelSelector({super.key});

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ChatScope.of(context).models.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final models = ChatScope.of(context).models;

    return ListenableBuilder(
      listenable: models,
      builder: (context, _) {
        final ids = {models.selected, ...models.models.map((m) => m.id)}.toList();

        return PopupMenuButton<String>(
          tooltip: 'Model',
          initialValue: models.selected,
          onSelected: models.select,
          itemBuilder: (context) => [
            for (final id in ids) PopupMenuItem(value: id, child: Text(id)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    models.selected,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
