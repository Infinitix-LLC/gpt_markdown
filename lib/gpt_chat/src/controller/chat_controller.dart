import 'package:flutter/material.dart';

import '../adapter/chat_adapter.dart';
import '../adapter/chat_capabilities.dart';
import '../adapter/chat_draft.dart';
import '../adapter/chat_message.dart';
import '../adapter/chat_model_source.dart';
import '../adapter/chat_session.dart';
import '../adapter/chat_snapshot.dart';
import 'chat_message_pair.dart';

/// Everything a chat builder needs, in one object: the current state, the input
/// and scroll objects, the staged draft, and the actions.
///
/// This is what every slot carries, so a replacement app bar, composer or
/// transcript never has to reach for an adapter, a view model or an inherited
/// widget.
///
/// It folds the adapter and the model source into a single [ChangeNotifier], so
/// one `ListenableBuilder` rebuilds on any change.
class ChatController extends ChangeNotifier {
  ChatController({
    required ChatAdapter adapter,
    ChatModelSource? models,
    ScrollController? scrollController,
    TextEditingController? inputController,
    FocusNode? inputFocusNode,
    this.followLatest = true,
  }) : _adapter = adapter,
       _models = models,
       scrollController = scrollController ?? ScrollController(),
       _ownsScrollController = scrollController == null,
       input = inputController ?? TextEditingController(),
       _ownsInput = inputController == null,
       inputFocusNode = inputFocusNode ?? FocusNode(),
       _ownsFocusNode = inputFocusNode == null {
    _adapter.addListener(_onSourceChanged);
    _models?.addListener(notifyListeners);
    input.addListener(notifyListeners);
  }

  final ChatAdapter _adapter;
  final ChatModelSource? _models;

  final bool _ownsScrollController;
  final bool _ownsInput;
  final bool _ownsFocusNode;

  /// Distance from the bottom, in pixels, still counted as "at the latest".
  /// Generous enough that a fractional overscroll or a one-line growth spurt
  /// does not read as the user scrolling away.
  static const double followThreshold = 120;

  /// Transcript scroll controller. Attach it to whatever scrollable a custom
  /// transcript returns.
  final ScrollController scrollController;

  /// Composer text. Owned here so a custom composer can read, prefill or clear
  /// it without holding state of its own.
  final TextEditingController input;

  final FocusNode inputFocusNode;

  /// Whether the transcript keeps itself pinned to the newest content.
  ///
  /// Set false when the host drives scrolling itself — the controller then
  /// never moves the viewport, and `onSend` leaves the position alone. Without
  /// this, two things fight over one `ScrollController`.
  final bool followLatest;

  bool _followLatest = true;
  bool _autoScrolling = false;
  List<ChatAttachment> _attachments = const [];
  Object? _tool;

  /// The adapter driving this chat. Reach for it only when a slot needs
  /// something the controller does not forward.
  ChatAdapter get adapter => _adapter;

  ChatModelSource? get modelSource => _models;

  // ---------------------------------------------------------------- state ---

  ChatSnapshot get snapshot => _adapter.snapshot;
  ChatCapabilities get capabilities => _adapter.capabilities;

  List<ChatSession> get sessions => snapshot.sessions;
  ChatSession? get activeSession => snapshot.activeSession;
  String? get activeSessionId => snapshot.activeSessionId;
  List<ChatMessage> get messages => snapshot.messages;

  /// [messages] grouped into question/answer exchanges.
  List<ChatMessagePair> get pairs => ChatMessagePair.fromMessages(messages);

  /// The conversation is still being restored.
  bool get isLoading => snapshot.isLoading;

  /// A reply is in flight.
  bool get isResponding => snapshot.isResponding;

  bool get isEmpty => snapshot.isEmpty;

  /// Last failure, or null.
  String? get error => snapshot.error;

  bool get hasMoreSessions => snapshot.hasMoreSessions;
  bool get isLoadingSessions => snapshot.isLoadingSessions;

  /// Prompt suggestions, or empty when the adapter offers none.
  List<String> get suggestions =>
      capabilities.suggestions ? _adapter.suggestions : const [];

  List<ChatModelOption> get availableModels => _models?.models ?? const [];
  String get selectedModel => _models?.selected ?? '';
  bool get isLoadingModels => _models?.isLoading ?? false;
  String? get modelError => _models?.error;

  // ---------------------------------------------------------------- draft ---

  /// Attachments staged in the composer but not yet sent.
  List<ChatAttachment> get attachments => _attachments;

  /// The mode selected in the composer, or null. Host-defined.
  Object? get tool => _tool;

  /// The draft as it would be sent right now.
  ChatDraft get draft =>
      ChatDraft(text: input.text, attachments: _attachments, tool: _tool);

  /// Something is sendable and no reply is in flight.
  bool get canSend =>
      (input.text.trim().isNotEmpty || _attachments.isNotEmpty) &&
      !isResponding;

  void addAttachment(ChatAttachment attachment) {
    _attachments = [..._attachments, attachment];
    notifyListeners();
  }

  void removeAttachment(String attachmentId) {
    _attachments = _attachments.where((a) => a.id != attachmentId).toList();
    notifyListeners();
  }

  void clearAttachments() {
    if (_attachments.isEmpty) return;
    _attachments = const [];
    notifyListeners();
  }

  void setTool(Object? tool) {
    if (tool == _tool) return;
    _tool = tool;
    notifyListeners();
  }

  // -------------------------------------------------------------- actions ---

  /// Sends [text], or the composer's contents when omitted, and clears the
  /// composer.
  Future<void> onSend([String? text]) async {
    final outgoing =
        text == null
            ? draft
            : ChatDraft(text: text, attachments: _attachments, tool: _tool);
    if (outgoing.isEmpty || isResponding) return;

    input.clear();
    _attachments = const [];
    await _adapter.send(outgoing);

    // After the send, so the scroll target accounts for the new question, and
    // so a user who had scrolled up is brought back to their own message.
    scrollToLatest();
  }

  /// Sends [draft] verbatim, bypassing the composer.
  Future<void> onSendDraft(ChatDraft draft) async {
    if (draft.isEmpty || isResponding) return;
    await _adapter.send(draft);
    scrollToLatest();
  }

  /// Cancels the in-flight reply, keeping the text that already arrived.
  Future<void> onStop() => _adapter.stop();

  /// Drops the failed reply and re-sends the question before it.
  Future<void> onRetry() => _adapter.retryLast();

  /// Switches the model used for subsequent replies.
  void onModelChoose(String modelId) => _models?.select(modelId);

  /// Loads the available model list. Safe to call repeatedly.
  Future<void> onLoadModels() async => _models?.load();

  Future<void> onNewSession() async {
    await _adapter.newSession();
    _followLatest = true;
  }

  Future<void> onSelectSession(String sessionId) async {
    await _adapter.selectSession(sessionId);
    _followLatest = true;
  }

  Future<void> onDeleteSession(String sessionId) =>
      _adapter.deleteSession(sessionId);

  Future<void> onRenameSession(String sessionId, String title) =>
      _adapter.renameSession(sessionId, title);

  Future<void> onLoadMoreSessions() => _adapter.loadMoreSessions();

  void onClearError() => _adapter.clearError();

  /// Puts [text] in the composer and focuses it. What a suggestion chip does.
  void prefill(String text, {bool focus = true}) {
    input
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    if (focus) inputFocusNode.requestFocus();
  }

  /// Something that changes when this one message changes, or null. Used by the
  /// transcript to rebuild a single bubble while a reply streams.
  Listenable? messageListenable(String messageId) =>
      _adapter.messageListenable(messageId);

  // --------------------------------------------------------------- scroll ---

  /// Whether the transcript is following new content.
  ///
  /// False once the user scrolls up; a custom UI can show a "jump to latest"
  /// affordance while it is false.
  bool get isFollowingLatest => _followLatest;

  /// True when the transcript has scrolled away from the latest message.
  bool get canJumpToLatest =>
      followLatest && !_followLatest && scrollController.hasClients;

  /// Feed this to a `NotificationListener<ScrollNotification>` around the
  /// transcript.
  ///
  /// Following is driven by *user-initiated* scrolls only. Auto-scrolls during
  /// streaming would otherwise immediately re-arm following and the user could
  /// never scroll away from a fast reply.
  bool onScrollNotification(ScrollNotification notification) {
    if (!followLatest || _autoScrolling) return false;

    final isUserDriven =
        notification is UserScrollNotification ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null) ||
        notification is ScrollEndNotification;
    if (!isUserDriven) return false;

    final following = _isAtLatest;
    if (following != _followLatest) {
      _followLatest = following;
      notifyListeners();
    }
    return false;
  }

  /// Scrolls to the newest content and resumes following.
  ///
  /// Returns immediately: the scroll runs after the next frame, once the
  /// message that triggered it has been laid out and `maxScrollExtent` reflects
  /// it. Awaiting the frame here instead would deadlock any caller that has not
  /// yet pumped one.
  void scrollToLatest({bool animated = true}) {
    if (!followLatest) return;
    _followLatest = true;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd(animated: animated);
    });
  }

  /// Alias matching the affordance's name.
  void onJumpToLatest() => scrollToLatest();

  bool get _isAtLatest {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return position.maxScrollExtent - position.pixels <= followThreshold;
  }

  Future<void> _scrollToEnd({bool animated = true}) async {
    if (!scrollController.hasClients) return;

    _autoScrolling = true;
    try {
      final target = scrollController.position.maxScrollExtent;
      if (animated) {
        await scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        scrollController.jumpTo(target);
      }
    } finally {
      _autoScrolling = false;
    }
  }

  /// Keeps the newest tokens visible while a reply streams, without ever taking
  /// scrolling away from the user: if they scrolled up, following is off and
  /// nothing here moves the viewport.
  void _followIfNeeded() {
    if (!followLatest) return;
    if (!_followLatest || !scrollController.hasClients) return;
    if (_isAtLatest) return;

    // Jump rather than animate: an animation restarted on every token fights
    // itself and never settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_followLatest || !scrollController.hasClients) return;
      _autoScrolling = true;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      _autoScrolling = false;
    });
  }

  void _onSourceChanged() {
    _followIfNeeded();
    notifyListeners();
  }

  @override
  void dispose() {
    _adapter.removeListener(_onSourceChanged);
    _models?.removeListener(notifyListeners);
    input.removeListener(notifyListeners);

    if (_ownsScrollController) scrollController.dispose();
    if (_ownsInput) input.dispose();
    if (_ownsFocusNode) inputFocusNode.dispose();
    super.dispose();
  }
}
