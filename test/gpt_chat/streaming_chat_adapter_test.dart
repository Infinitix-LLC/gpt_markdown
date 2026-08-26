import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

void main() {
  test('init opens a session', () async {
    final adapter = FakeAdapter();
    await adapter.init();

    expect(adapter.snapshot.isLoading, isFalse);
    expect(adapter.snapshot.activeSession, isNotNull);
  });

  test('init is idempotent', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    final first = adapter.snapshot.activeSessionId;
    await adapter.init();

    expect(adapter.snapshot.sessions, hasLength(1));
    expect(adapter.snapshot.activeSessionId, first);
  });

  test('send appends the user message and the streamed reply', () async {
    final adapter = FakeAdapter(deltas: ['He', 'llo']);
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    final messages = adapter.snapshot.messages;
    expect(messages.map((m) => m.role), [ChatRole.user, ChatRole.assistant]);
    expect(messages.last.content, 'Hello');
    expect(messages.last.status, ChatMessageStatus.done);
    expect(adapter.snapshot.isResponding, isFalse);
  });

  test('a replacing delta discards what came before it', () async {
    final adapter = _ReplacingAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    expect(adapter.snapshot.messages.last.content, 'final');
  });

  test('send titles the session from the first message', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'Explain quantum tunneling'));
    await pumpEventQueue();

    expect(adapter.snapshot.activeSession!.title, 'Explain quantum tunneling');
  });

  test('send ignores blank input', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: '   '));

    expect(adapter.snapshot.messages, isEmpty);
    expect(adapter.calls, isEmpty);
  });

  test('history excludes the empty assistant placeholder', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    expect(adapter.calls.single.map((m) => m.content), ['hi']);
  });

  test('a failed reply surfaces the error and keeps partial text', () async {
    final adapter = FakeAdapter(
      deltas: ['partial'],
      error: const ChatException('rate limited'),
    );
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    expect(adapter.snapshot.error, 'rate limited');
    expect(adapter.snapshot.messages.last.content, 'partial');
    expect(adapter.snapshot.messages.last.status, ChatMessageStatus.error);
    expect(adapter.snapshot.isResponding, isFalse);
  });

  test('retryLast re-sends the failed prompt', () async {
    final adapter = FakeAdapter(error: const ChatException('boom'));
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    await adapter.retryLast();
    await pumpEventQueue();

    expect(adapter.calls, hasLength(2));
    expect(adapter.snapshot.messages.map((m) => m.content), ['hi', 'Hello']);
  });

  test('stop keeps the text received so far', () async {
    final adapter = ManualAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));

    adapter.emit('half ');
    await pumpEventQueue();
    await adapter.stop();

    expect(adapter.snapshot.isResponding, isFalse);
    expect(adapter.snapshot.messages.last.content, 'half ');
    expect(adapter.snapshot.messages.last.status, ChatMessageStatus.done);
  });

  test('newSession reuses the current session while it is empty', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    final first = adapter.snapshot.activeSessionId;

    await adapter.newSession();

    expect(adapter.snapshot.sessions, hasLength(1));
    expect(adapter.snapshot.activeSessionId, first);
  });

  test(
    'newSession starts a fresh thread once the current one is used',
    () async {
      final adapter = FakeAdapter();
      await adapter.init();
      await adapter.send(const ChatDraft(text: 'hi'));
      await pumpEventQueue();

      await adapter.newSession();

      expect(adapter.snapshot.sessions, hasLength(2));
      expect(adapter.snapshot.messages, isEmpty);
    },
  );

  test('deleteSession always leaves an active session', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    await adapter.deleteSession(adapter.snapshot.activeSessionId!);

    expect(adapter.snapshot.activeSession, isNotNull);
    expect(adapter.snapshot.messages, isEmpty);
  });

  test('renameSession retitles the thread', () async {
    final adapter = FakeAdapter();
    await adapter.init();
    await adapter.renameSession(adapter.snapshot.activeSessionId!, 'Renamed');

    expect(adapter.snapshot.activeSession!.title, 'Renamed');
  });

  test(
    'messages that are Listenable are reported as individually observable',
    () {
      final adapter = _ObservableAdapter();

      expect(adapter.messageListenable('m1'), isNotNull);
      expect(adapter.messageListenable('nope'), isNull);
    },
  );

  group('a host model instead of SimpleChatMessage', _hostModelTests);
}

class _ReplacingAdapter extends StreamingChatAdapter {
  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
    yield const ChatDelta('draft');
    yield const ChatDelta.replace('final');
  }
}

/// A host whose messages are their own change notifiers.
class _ObservableMessage extends ChangeNotifier implements ChatMessage {
  @override
  String get id => 'm1';
  @override
  ChatRole get role => ChatRole.assistant;
  @override
  String get content => 'hi';
  @override
  DateTime get createdAt => DateTime(2024);
  @override
  ChatMessageStatus get status => ChatMessageStatus.done;
  @override
  String? get error => null;
}

class _ObservableAdapter extends ChatAdapter {
  @override
  ChatSnapshot get snapshot => ChatSnapshot(messages: [_ObservableMessage()]);

  @override
  Future<void> send(ChatDraft draft) async {}
}

/// A host model: mutable, its own fields, not the package's type.
class _HostMessage extends ChangeNotifier implements ChatMessage {
  _HostMessage({required this.id, required this.role, this.content = ''});

  @override
  final String id;
  @override
  final ChatRole role;
  @override
  String content;
  @override
  DateTime get createdAt => DateTime(2024);
  @override
  ChatMessageStatus status = ChatMessageStatus.done;
  @override
  String? error;

  /// The point of the exercise: a field the package knows nothing about.
  final List<String> sources = [];
}

class _HostAdapter extends StreamingChatAdapter {
  int minted = 0;

  @override
  ChatMessage newMessage({
    required ChatRole role,
    required String content,
    ChatMessageStatus status = ChatMessageStatus.done,
  }) {
    minted++;
    return _HostMessage(id: 'host-$minted', role: role, content: content)
      ..status = status;
  }

  @override
  ChatMessage updateMessage(
    ChatMessage message, {
    String? content,
    ChatMessageStatus? status,
    String? error,
  }) {
    final host = message as _HostMessage;
    if (content != null) host.content = content;
    if (status != null) host.status = status;
    if (error != null) host.error = error;
    host.notifyListeners();
    return host;
  }

  @override
  ChatMessage applyDelta(ChatMessage reply, ChatDelta delta, String buffered) {
    final payload = delta.payload;
    if (payload is List<String>) {
      (reply as _HostMessage).sources.addAll(payload);
    }
    return super.applyDelta(reply, delta, buffered);
  }

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
    yield const ChatDelta.data(<String>['wikipedia.org']);
    yield const ChatDelta('the ');
    yield const ChatDelta('answer');
  }
}

void _hostModelTests() {
  test('a host message type survives the whole streaming path', () async {
    final adapter = _HostAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    final reply = adapter.snapshot.messages.last;
    expect(reply, isA<_HostMessage>());
    expect(reply.content, 'the answer');
    expect(reply.status, ChatMessageStatus.done);
  });

  test(
    'a data-only chunk routes into a field the package cannot see',
    () async {
      final adapter = _HostAdapter();
      await adapter.init();
      await adapter.send(const ChatDraft(text: 'hi'));
      await pumpEventQueue();

      final reply = adapter.snapshot.messages.last as _HostMessage;
      expect(reply.sources, ['wikipedia.org']);
    },
  );

  test('a mutable host message is its own Listenable', () async {
    final adapter = _HostAdapter();
    await adapter.init();
    await adapter.send(const ChatDraft(text: 'hi'));
    await pumpEventQueue();

    final id = adapter.snapshot.messages.last.id;
    expect(adapter.messageListenable(id), isNotNull);
  });

  test('forgetting updateMessage fails loudly, not silently', () async {
    final adapter = _ForgetfulAdapter();
    await adapter.init();

    await expectLater(
      () => adapter.send(const ChatDraft(text: 'hi')),
      throwsA(isA<StateError>()),
    );
  });
}

/// Mints its own type but never says how to change one.
class _ForgetfulAdapter extends StreamingChatAdapter {
  @override
  ChatMessage newMessage({
    required ChatRole role,
    required String content,
    ChatMessageStatus status = ChatMessageStatus.done,
  }) => _HostMessage(id: 'x', role: role, content: content);

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) =>
      Stream.value(const ChatDelta('hi'));
}
