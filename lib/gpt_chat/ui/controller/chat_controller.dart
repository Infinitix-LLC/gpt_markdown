import 'package:flutter/material.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../data/models/gateway_model.dart';
import '../view_models/chat_state.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/model_view_model.dart';
import 'chat_message_pair.dart';

/// Everything a chat builder needs: the current state, the input and scroll
/// objects, and the actions a custom UI can invoke.
///
/// This is the single argument passed to every builder in `ChatBuilders`, so a
/// replacement app bar, composer, or transcript never needs to reach for a view
/// model, a repository, or an inherited widget.
///
/// It is a [ChangeNotifier] that folds in the chat and model view models, so a
/// single `ListenableBuilder` on the controller rebuilds on any change.
class ChatController extends ChangeNotifier {
  ChatController({
    required ChatViewModel chat,
    required ModelViewModel models,
    ScrollController? scrollController,
    TextEditingController? inputController,
    FocusNode? inputFocusNode,
  }) : _chat = chat,
       _models = models,
       scrollController = scrollController ?? ScrollController(),
       _ownsScrollController = scrollController == null,
       input = inputController ?? TextEditingController(),
       _ownsInput = inputController == null,
       inputFocusNode = inputFocusNode ?? FocusNode(),
       _ownsFocusNode = inputFocusNode == null {
    _chat.addListener(_onSourceChanged);
    _models.addListener(_onSourceChanged);
    input.addListener(notifyListeners);
  }

  final ChatViewModel _chat;
  final ModelViewModel _models;

  final bool _ownsScrollController;
  final bool _ownsInput;
  final bool _ownsFocusNode;

  /// Distance from the bottom, in pixels, still counted as "at the latest".
  /// Generous enough that a fractional overscroll or a one-line growth spurt
  /// does not read as the user scrolling away.
  static const double followThreshold = 120;

  /// Transcript scroll controller. Attach it to whatever scrollable the
  /// transcript builder returns.
  final ScrollController scrollController;

  /// Composer text. Owned here so a custom composer can read, prefill, or clear
  /// it without holding its own state.
  final TextEditingController input;

  final FocusNode inputFocusNode;

  bool _followLatest = true;
  bool _autoScrolling = false;

  // ---------------------------------------------------------------- state ---

  ChatState get state => _chat.state;

  List<ChatSession> get sessions => state.sessions;
  ChatSession? get activeSession => state.activeSession;
  String? get activeSessionId => state.activeSessionId;
  List<ChatMessage> get messages => state.messages;

  /// [messages] grouped into question/answer exchanges.
  List<ChatMessagePair> get pairs => ChatMessagePair.fromMessages(messages);

  /// Sessions are still being restored from the store.
  bool get isLoading => state.isLoading;

  /// A reply is in flight.
  bool get isResponding => state.isResponding;

  bool get isEmpty => state.isEmpty;

  /// Last failure, or null.
  String? get error => state.error;

  List<GatewayModel> get availableModels => _models.models;
  String get selectedModel => _models.selected;
  bool get isLoadingModels => _models.isLoading;
  String? get modelError => _models.error;

  /// The composer holds something sendable and no reply is in flight.
  bool get canSend => input.text.trim().isNotEmpty && !isResponding;

  /// Whether the transcript is following new content.
  ///
  /// False once the user scrolls up; a custom UI can show a "jump to latest"
  /// affordance while it is false.
  bool get isFollowingLatest => _followLatest;

  /// True when the transcript has scrolled away from the latest message.
  bool get canJumpToLatest => !_followLatest && scrollController.hasClients;

  // -------------------------------------------------------------- actions ---

  /// Sends [text], or the composer's contents when omitted, and clears the
  /// composer.
  Future<void> onSend([String? text]) async {
    final prompt = (text ?? input.text).trim();
    if (prompt.isEmpty || isResponding) return;

    input.clear();
    await _chat.send(prompt);

    // After the send, so the scroll target accounts for the new question, and
    // so a user who had scrolled up is brought back to their own message.
    scrollToLatest();
  }

  /// Cancels the in-flight reply, keeping the text that already arrived.
  Future<void> onStop() => _chat.stop();

  /// Drops the failed reply and re-sends the question before it.
  Future<void> onRetry() => _chat.retryLast();

  /// Switches the model used for subsequent replies.
  void onModelChoose(String modelId) => _models.select(modelId);

  /// Loads the available model list. Safe to call repeatedly.
  Future<void> onLoadModels() => _models.load();

  Future<void> onNewSession() async {
    await _chat.newSession();
    _followLatest = true;
  }

  Future<void> onSelectSession(String sessionId) async {
    await _chat.selectSession(sessionId);
    _followLatest = true;
  }

  Future<void> onDeleteSession(String sessionId) =>
      _chat.deleteSession(sessionId);

  void onClearError() => _chat.clearError();

  // --------------------------------------------------------------- scroll ---

  /// Feed this to a `NotificationListener<ScrollNotification>` around the
  /// transcript.
  ///
  /// Following is driven by *user-initiated* scrolls only. Auto-scrolls during
  /// streaming would otherwise immediately re-arm following and the user could
  /// never scroll away from a fast reply.
  bool onScrollNotification(ScrollNotification notification) {
    if (_autoScrolling) return false;

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
    _chat.removeListener(_onSourceChanged);
    _models.removeListener(_onSourceChanged);
    input.removeListener(notifyListeners);

    if (_ownsScrollController) scrollController.dispose();
    if (_ownsInput) input.dispose();
    if (_ownsFocusNode) inputFocusNode.dispose();
    super.dispose();
  }
}
