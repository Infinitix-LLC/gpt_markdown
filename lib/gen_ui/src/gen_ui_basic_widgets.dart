import 'package:flutter/material.dart';

import 'gen_ui_values.dart';

/// Signature for `button` presses. [action] is the payload's `action` field
/// (falling back to the label), [attributes] is the whole button payload.
typedef GenUiActionCallback =
    void Function(String action, Map<String, dynamic> attributes);

/// `text`: plain text, styled by the ambient [DefaultTextStyle].
class GenText extends StatelessWidget {
  const GenText({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final text = genUiString(attributes['text'] ?? attributes['value']);
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Text(text);
  }
}

/// `genui_error`: a widget the gateway could not render.
///
/// Emitted in place of a widget rather than leaving a gap, because the prose
/// around it has usually already said "as the chart shows" — a missing chart
/// makes the answer look wrong, while a quiet notice makes it make sense. It is
/// deliberately unobtrusive: this is our failure, not something the reader can
/// act on.
class GenUiError extends StatelessWidget {
  const GenUiError({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message =
        genUiString(attributes['message']) ??
        'This content could not be displayed.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `image`: a network image with a loading placeholder and an error box.
class GenImage extends StatelessWidget {
  const GenImage({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final url = genUiString(attributes['url'] ?? attributes['src']);
    if (url == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final width = genUiDouble(attributes['width']);
    final height = genUiDouble(attributes['height']);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: width,
            height: height ?? 120,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder:
            (context, error, stackTrace) => Container(
              width: width,
              height: height ?? 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      ),
    );
  }
}

/// `button`: a text button. Presses are forwarded to [onAction]; with no
/// callback the button renders disabled rather than silently doing nothing.
class GenButton extends StatelessWidget {
  const GenButton({super.key, required this.attributes, this.onAction});

  final Map<String, dynamic> attributes;
  final GenUiActionCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = genUiString(attributes['text'] ?? attributes['label']);
    if (label == null) {
      return const SizedBox.shrink();
    }

    final callback = onAction;
    final action = genUiString(attributes['action']) ?? label;

    return TextButton(
      onPressed:
          callback == null
              ? null
              : () => callback(action, Map<String, dynamic>.from(attributes)),
      child: Text(label),
    );
  }
}
