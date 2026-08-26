import 'package:flutter/foundation.dart';

/// One slice of a streamed reply.
///
/// Most providers append; some (a non-streaming call, a server that re-sends the
/// whole message each tick) replace. Both are expressible so the adapter does
/// not have to buffer on the caller's behalf.
@immutable
class ChatDelta {
  /// Text to append to the reply so far.
  const ChatDelta(this.text, {this.payload}) : replaces = false;

  /// [text] is the complete reply so far, replacing anything already received.
  const ChatDelta.replace(this.text, {this.payload}) : replaces = true;

  /// Everything the chunk carried that is not prose — sources, tool status,
  /// media, reasoning. The package never reads it; override
  /// [StreamingChatAdapter.applyDelta] and route it into your own message.
  const ChatDelta.data(this.payload) : text = '', replaces = false;

  final String text;
  final bool replaces;

  /// Host-owned chunk data, untouched by the package.
  final Object? payload;

  /// Nothing to fold in — no prose and no payload.
  bool get isEmpty => text.isEmpty && payload == null;

  @override
  String toString() =>
      replaces
          ? 'ChatDelta.replace(${text.length})'
          : 'ChatDelta(${text.length})';
}
