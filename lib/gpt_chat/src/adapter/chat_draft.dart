import 'package:flutter/foundation.dart';

/// Broad kind of an attachment, enough for the default UI to pick an icon and a
/// preview. Anything finer belongs in [ChatAttachment.payload].
enum ChatAttachmentKind { image, video, audio, file }

/// Something staged alongside a message.
///
/// The package never interprets [payload] — it is where a host puts its own
/// object (an upload handle, a `StudyMaterial`, a `SessionImage`) so its own
/// builders can read it back without the package knowing the type.
@immutable
class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.kind,
    this.name,
    this.uri,
    this.bytes,
    this.payload,
  });

  final String id;
  final ChatAttachmentKind kind;

  /// Shown under the thumbnail. Falls back to the last path segment of [uri].
  final String? name;

  /// Local file path or remote URL, whichever the host has.
  final String? uri;

  /// In-memory data, for attachments picked but not yet uploaded.
  final Uint8List? bytes;

  /// Host-owned object, untouched by the package.
  final Object? payload;

  String get label => name ?? uri?.split('/').last ?? id;

  ChatAttachment copyWith({
    ChatAttachmentKind? kind,
    String? name,
    String? uri,
    Uint8List? bytes,
    Object? payload,
  }) {
    return ChatAttachment(
      id: id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      uri: uri ?? this.uri,
      bytes: bytes ?? this.bytes,
      payload: payload ?? this.payload,
    );
  }

  @override
  bool operator ==(Object other) => other is ChatAttachment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// What the composer hands to [ChatAdapter.send].
///
/// [tool] is deliberately untyped: hosts that offer modes (search, video, deep
/// research) put their own enum there and read it back in their adapter.
@immutable
class ChatDraft {
  const ChatDraft({
    required this.text,
    this.attachments = const [],
    this.tool,
    this.replyTo,
  });

  final String text;
  final List<ChatAttachment> attachments;

  /// The mode selected in the composer, or null.
  final Object? tool;

  /// Id of the message being replied to or quoted, or null.
  final String? replyTo;

  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;
  bool get isNotEmpty => !isEmpty;

  ChatDraft copyWith({
    String? text,
    List<ChatAttachment>? attachments,
    Object? tool,
    String? replyTo,
  }) {
    return ChatDraft(
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      tool: tool ?? this.tool,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  @override
  String toString() =>
      'ChatDraft("$text", ${attachments.length} attachments, tool: $tool)';
}
