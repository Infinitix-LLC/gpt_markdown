import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/chat_message.dart';

/// Character count past which the bubble collapses.
const int _longContentThreshold = 150;

/// Lines shown while collapsed.
const int _collapsedMaxLines = 3;

/// Height of the fade that softens the clipped last line.
const double _fadeHeight = 40;

/// The user's message: a right-aligned bubble, inset from the left so it never
/// spans the full column.
///
/// A long question is collapsed to a few lines behind a fade with a Show
/// more/less toggle — pasted material can run for screens, and left whole it
/// would bury the answer it belongs to. Long-press copies.
class SessionQuestion extends StatefulWidget {
  const SessionQuestion({super.key, required this.message});

  final ChatMessage message;

  @override
  State<SessionQuestion> createState() => _SessionQuestionState();
}

class _SessionQuestionState extends State<SessionQuestion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.message.content;
    if (content.trim().isEmpty) return const SizedBox.shrink();

    final isLong = content.length > _longContentThreshold;
    final isClipped = isLong && !_expanded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            // Keeps the bubble off the left edge so it reads as one side of a
            // conversation rather than a full-width block.
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 7, 0, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: content));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.maybeOf(context)
                        ?..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Text(
                            content,
                            maxLines: isClipped ? _collapsedMaxLines : null,
                            overflow: isClipped ? TextOverflow.ellipsis : null,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (isClipped)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: _fadeHeight,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.colorScheme.surfaceContainerHigh
                                            .withValues(alpha: 0),
                                        theme.colorScheme.surfaceContainerHigh,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isLong)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _expanded ? 'Show less' : 'Show more',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
