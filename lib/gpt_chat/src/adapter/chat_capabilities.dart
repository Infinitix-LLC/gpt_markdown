import 'package:flutter/foundation.dart';

/// What an adapter supports, and therefore which chrome the default UI shows.
///
/// This replaces per-widget `showX` flags: the screen adapts to the adapter it
/// was given rather than to whatever the call site remembered to pass.
@immutable
class ChatCapabilities {
  const ChatCapabilities({
    this.sessions = true,
    this.sessionPaging = false,
    this.deleteSessions = true,
    this.renameSessions = false,
    this.models = false,
    this.stop = true,
    this.retry = true,
    this.attachments = false,
    this.tools = false,
    this.suggestions = false,
  });

  /// Everything off but sending. The right starting point for a single-thread
  /// support widget or an embedded assistant.
  static const minimal = ChatCapabilities(
    sessions: false,
    deleteSessions: false,
    stop: false,
    retry: false,
  );

  /// A drawer listing conversations.
  final bool sessions;

  /// The session list is paged — the drawer shows a loading footer and calls
  /// `loadMoreSessions` as it nears the end.
  final bool sessionPaging;

  final bool deleteSessions;
  final bool renameSessions;

  /// A model picker, backed by a [ChatModelSource].
  final bool models;

  /// The send button turns into stop while a reply streams.
  final bool stop;

  /// Failed replies offer a retry.
  final bool retry;

  /// The composer shows the staged-attachment strip.
  ///
  /// The attach button itself is host-supplied — the package ships no picker
  /// dependency. Add one via `ChatBuilders.composerLeading`.
  final bool attachments;

  /// The host offers modes (search, deep research, video).
  ///
  /// Nothing package-side is gated on this: the modes and their picker are
  /// yours. Read it in your own `ChatBuilders.composerLeading` and drive
  /// `ChatController.setTool`, which puts the choice on `ChatDraft.tool`.
  final bool tools;

  /// The empty state shows [ChatAdapter.suggestions] as chips.
  final bool suggestions;

  ChatCapabilities copyWith({
    bool? sessions,
    bool? sessionPaging,
    bool? deleteSessions,
    bool? renameSessions,
    bool? models,
    bool? stop,
    bool? retry,
    bool? attachments,
    bool? tools,
    bool? suggestions,
  }) {
    return ChatCapabilities(
      sessions: sessions ?? this.sessions,
      sessionPaging: sessionPaging ?? this.sessionPaging,
      deleteSessions: deleteSessions ?? this.deleteSessions,
      renameSessions: renameSessions ?? this.renameSessions,
      models: models ?? this.models,
      stop: stop ?? this.stop,
      retry: retry ?? this.retry,
      attachments: attachments ?? this.attachments,
      tools: tools ?? this.tools,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatCapabilities &&
      other.sessions == sessions &&
      other.sessionPaging == sessionPaging &&
      other.deleteSessions == deleteSessions &&
      other.renameSessions == renameSessions &&
      other.models == models &&
      other.stop == stop &&
      other.retry == retry &&
      other.attachments == attachments &&
      other.tools == tools &&
      other.suggestions == suggestions;

  @override
  int get hashCode => Object.hash(
    sessions,
    sessionPaging,
    deleteSessions,
    renameSessions,
    models,
    stop,
    retry,
    attachments,
    tools,
    suggestions,
  );
}
