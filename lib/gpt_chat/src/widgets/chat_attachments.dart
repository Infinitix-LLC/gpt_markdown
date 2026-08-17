import 'package:flutter/material.dart';

import '../adapter/chat_draft.dart';
import '../builders/chat_slots.dart';
import 'chat_scope.dart';

/// One attachment, as a thumbnail with a label.
///
/// Staged attachments (still in the composer) carry a remove button; sent ones
/// do not.
class ChatAttachmentTile extends StatelessWidget {
  const ChatAttachmentTile({
    super.key,
    required this.attachment,
    this.isStaged = false,
    this.onRemove,
  });

  final ChatAttachment attachment;
  final bool isStaged;
  final VoidCallback? onRemove;

  static const double _size = 60;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _preview(context),
          ),
          if (isStaged && onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: scheme.inverseSurface,
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: scheme.onInverseSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (attachment.kind == ChatAttachmentKind.image) {
      if (attachment.bytes != null) {
        return Image.memory(attachment.bytes!, fit: BoxFit.cover);
      }
      final uri = attachment.uri;
      if (uri != null && uri.startsWith('http')) {
        return Image.network(
          uri,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _icon(scheme),
        );
      }
    }
    return _icon(scheme);
  }

  Widget _icon(ColorScheme scheme) {
    final icon = switch (attachment.kind) {
      ChatAttachmentKind.image => Icons.image_outlined,
      ChatAttachmentKind.video => Icons.videocam_outlined,
      ChatAttachmentKind.audio => Icons.graphic_eq,
      ChatAttachmentKind.file => Icons.description_outlined,
    };

    return Center(child: Icon(icon, color: scheme.onSurfaceVariant, size: 24));
  }
}

/// A horizontal strip of attachments. Collapses to nothing when empty.
class ChatAttachmentStrip extends StatelessWidget {
  const ChatAttachmentStrip({
    super.key,
    required this.attachments,
    this.isStaged = false,
    this.alignment = MainAxisAlignment.start,
  });

  final List<ChatAttachment> attachments;
  final bool isStaged;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final scope = ChatScope.of(context);
    final controller = scope.controller;
    final builder = isStaged
        ? scope.builders.composerAttachmentTile
        : scope.builders.questionAttachmentTile;

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return scope.build(
            builder,
            ChatAttachmentSlot(
              context: context,
              controller: controller,
              theme: scope.theme,
              attachment: attachment,
              index: index,
              isStaged: isStaged,
              child: ChatAttachmentTile(
                attachment: attachment,
                isStaged: isStaged,
                onRemove: isStaged
                    ? () => controller.removeAttachment(attachment.id)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
