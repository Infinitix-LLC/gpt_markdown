import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays code with syntax highlighting and a copy button.
///
/// The [CodeField] widget takes a [name] parameter which is displayed as a label
/// above the code block, and a [codes] parameter containing the actual code text
/// to display.
///
/// Features:
/// - Displays code in a Material container with rounded corners
/// - Shows the code language/name as a label
/// - Provides a copy button to copy code to clipboard
/// - Visual feedback when code is copied
/// - Themed colors that adapt to light/dark mode
class CodeField extends StatefulWidget {
  const CodeField({
    super.key,
    required this.name,
    required this.codes,
    this.backgroundColor,
    this.textColor,
  });

  final String name;
  final String codes;

  final Color? backgroundColor;
  final Color? textColor;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          widget.backgroundColor ??
          Theme.of(context).colorScheme.onInverseSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Text(
                  widget.name,
                  style: TextStyle(
                    color:
                        widget.textColor ??
                        Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor:
                      widget.textColor ??
                      Theme.of(context).colorScheme.onSurface,
                  textStyle: const TextStyle(fontWeight: FontWeight.normal),
                ),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.codes),
                  ).then((value) {
                    setState(() {
                      _copied = true;
                    });
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    _copied = false;
                  });
                },
                icon: Icon(
                  (_copied) ? Icons.done : Icons.content_paste,
                  size: 15,
                ),
                label: Text(
                  (_copied) ? "Copied!" : "Copy code",
                  style: TextStyle(
                    color:
                        widget.textColor ??
                        Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.codes,
              style: TextStyle(
                color:
                    widget.textColor ?? Theme.of(context).colorScheme.onSurface,
                fontFamily: 'JetBrainsMono',
                package: "gpt_markdown",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
