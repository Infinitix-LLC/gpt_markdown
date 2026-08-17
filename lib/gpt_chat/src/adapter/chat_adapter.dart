import 'package:flutter/foundation.dart';

import 'chat_capabilities.dart';
import 'chat_draft.dart';
import 'chat_snapshot.dart';

/// The seam between this chat UI and whatever produces the conversation.
///
/// The package owns the shell — scaffold, transcript, scrolling, composer,
/// theming — and nothing else. **State stays with the host.** An app that
/// already has a chat view model, a use-case layer and its own persistence keeps
/// all of it and projects it through these methods; it does not hand ownership
/// over and it does not end up with two sources of truth.
///
/// Hosts with no state layer of their own should extend [StreamingChatAdapter]
/// instead, which implements everything here on top of a single `streamReply`.
///
/// ```dart
/// class MyAdapter extends ChatAdapter {
///   MyAdapter(this._vm) { _vm.addListener(notifyListeners); }
///   final MyChatViewModel _vm;
///
///   @override
///   ChatSnapshot get snapshot => ChatSnapshot(
///     messages: _vm.messages,          // MyMessage implements ChatMessage
///     isResponding: _vm.isStreaming,
///     error: _vm.error,
///   );
///
///   @override
///   ChatCapabilities get capabilities =>
///       const ChatCapabilities(sessions: false, attachments: true);
///
///   @override
///   Future<void> send(ChatDraft draft) => _vm.ask(draft.text, draft.attachments);
///   // …
/// }
/// ```
///
/// Call [notifyListeners] whenever [snapshot] changes shape — a message added or
/// removed, the session switched, the responding flag flipped. Token-level
/// updates inside one message do **not** need it if the message itself is a
/// [Listenable]; see [messageListenable].
abstract class ChatAdapter extends ChangeNotifier {
  /// The current picture of the conversation. Read on every rebuild, so keep it
  /// cheap — build it from fields, do not recompute a list every call if the
  /// list is large.
  ChatSnapshot get snapshot;

  /// Which chrome the default UI should show.
  ChatCapabilities get capabilities => const ChatCapabilities();

  /// Prompt suggestions offered in the empty state.
  ///
  /// Only shown when `capabilities.suggestions` is true. Tapping one prefills
  /// the composer rather than sending, so the user can edit it first.
  List<String> get suggestions => const [];

  /// Called once when the chat screen mounts. Restore persisted state here.
  ///
  /// Must be idempotent: an adapter shared between screens, or one whose widget
  /// remounts, will see this more than once.
  Future<void> init() async {}

  /// Sends a draft and streams the reply into [snapshot].
  Future<void> send(ChatDraft draft);

  /// Cancels the in-flight reply, keeping whatever text already arrived.
  Future<void> stop() async {}

  /// Drops the failed reply and re-sends the message before it.
  Future<void> retryLast() async {}

  Future<void> newSession() async {}

  Future<void> selectSession(String sessionId) async {}

  Future<void> deleteSession(String sessionId) async {}

  Future<void> renameSession(String sessionId, String title) async {}

  /// Fetches the next page of sessions. Only called when
  /// `capabilities.sessionPaging` is true and `snapshot.hasMoreSessions` is set.
  Future<void> loadMoreSessions() async {}

  /// Dismisses [ChatSnapshot.error].
  void clearError() {}

  /// Something that changes whenever *this one message* changes.
  ///
  /// The transcript wraps each message in a `ListenableBuilder` on the result,
  /// so a streaming reply repaints one bubble instead of the whole list. The
  /// default handles the common case: if the message object is itself a
  /// [Listenable] — a `ChangeNotifier`-based model, say — it is used directly.
  /// Override for immutable messages that are individually observable some other
  /// way; return null to fall back to whole-list rebuilds.
  Listenable? messageListenable(String messageId) {
    for (final message in snapshot.messages) {
      if (message.id == messageId) {
        return message is Listenable ? message as Listenable : null;
      }
    }
    return null;
  }
}
