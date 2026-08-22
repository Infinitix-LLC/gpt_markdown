import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../styles/code_block_style.dart';

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
    this.style = const CodeBlockStyle(),
    this.onCopy,
  });

  /// The language written after the opening fence.
  final String name;

  /// The code itself.
  final String codes;

  /// Resolved appearance. Every field is already filled in.
  final CodeBlockStyle style;

  /// Called with the code after it is copied to the clipboard.
  final void Function(String code)? onCopy;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    final borderColor = widget.style.borderColor;
    final showLabel = widget.style.showLanguageLabel ?? true;
    final showCopy = widget.style.showCopyButton ?? true;
    final family = widget.style.fontFamily;
    final codeStyle = TextStyle(
      // A caller-supplied family is not looked up inside this package.
      fontFamily: family ?? 'JetBrainsMono',
      package: family == null ? 'gpt_markdown' : widget.style.fontFamilyPackage,
      fontSize: widget.style.fontSize,
      color: widget.style.textColor,
    );
    // Rendered inside a `WidgetSpan`, and a paragraph lays inline children
    // out in scaled space: it hands them `maxWidth / scale` and multiplies
    // the reported size back. A child that also scales its own text is
    // counted twice. The markers here build their own `Text`, so they opt
    // out — the contract `config.getRich` already follows for nested
    // paragraphs.
    return MediaQuery.withNoTextScaling(
      child: Material(
        color:
            widget.style.backgroundColor ??
            Theme.of(context).colorScheme.onInverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            widget.style.borderRadius ?? const Radius.circular(8),
          ),
          side:
              borderColor == null
                  ? BorderSide.none
                  : BorderSide(
                    color: borderColor,
                    width: widget.style.borderWidth ?? 1,
                  ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel || showCopy)
              Row(
                children: [
                  if (showLabel)
                    Padding(
                      padding:
                          widget.style.headerPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8,
                          ),
                      child: Text(
                        widget.name,
                        style: widget.style.languageStyle,
                      ),
                    ),
                  const Spacer(),
                  if (showCopy)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.codes),
                        );
                        final onCopy = widget.onCopy;
                        if (onCopy != null) {
                          onCopy(widget.codes);
                        }
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _copied = true;
                        });
                        await Future.delayed(const Duration(seconds: 2));
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _copied = false;
                        });
                      },
                      icon: Icon(
                        (_copied) ? Icons.done : Icons.content_paste,
                        size: 15,
                      ),
                      label: Text(
                        _copied
                            ? (widget.style.copiedLabel ?? 'Copied!')
                            : (widget.style.copyLabel ?? 'Copy code'),
                      ),
                    ),
                ],
              ),
            if (showLabel || showCopy) const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: widget.style.padding ?? const EdgeInsets.all(16),
              child: Text(widget.codes, style: codeStyle),
            ),
          ],
        ),
      ),
    );
  }
}
