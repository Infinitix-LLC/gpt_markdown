import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

import 'fakes.dart';

ChatViewModel build(ChatRepository repository) => ChatViewModel(
  chatRepository: repository,
  sessionRepository: SessionRepository(store: InMemorySessionStore()),
);

void main() {
  test('init opens a session', () async {
    final viewModel = build(FakeChatRepository());
    await viewModel.init();

    expect(viewModel.state.isLoading, isFalse);
    expect(viewModel.state.activeSession, isNotNull);
  });

  test('send appends the user message and the streamed reply', () async {
    final viewModel = build(FakeChatRepository(deltas: ['He', 'llo']));
    await viewModel.init();
    await viewModel.send('hi');
    await pumpEventQueue();

    final messages = viewModel.state.messages;
    expect(messages.map((m) => m.role), [ChatRole.user, ChatRole.assistant]);
    expect(messages.last.content, 'Hello');
    expect(messages.last.status, ChatMessageStatus.done);
    expect(viewModel.state.isResponding, isFalse);
  });

  test('send titles the session from the first message', () async {
    final viewModel = build(FakeChatRepository());
    await viewModel.init();
    await viewModel.send('Explain quantum tunneling');
    await pumpEventQueue();

    expect(viewModel.state.activeSession!.title, 'Explain quantum tunneling');
  });

  test('send ignores blank input', () async {
    final repository = FakeChatRepository();
    final viewModel = build(repository);
    await viewModel.init();
    await viewModel.send('   ');

    expect(viewModel.state.messages, isEmpty);
    expect(repository.calls, isEmpty);
  });

  test('history excludes the empty assistant placeholder', () async {
    final repository = FakeChatRepository();
    final viewModel = build(repository);
    await viewModel.init();
    await viewModel.send('hi');
    await pumpEventQueue();

    expect(repository.calls.single.map((m) => m.content), ['hi']);
  });

  test('a failed reply surfaces the error and keeps partial text', () async {
    final viewModel = build(
      FakeChatRepository(deltas: ['partial'], error: const ChatException('rate limited')),
    );
    await viewModel.init();
    await viewModel.send('hi');
    await pumpEventQueue();

    expect(viewModel.state.error, 'rate limited');
    expect(viewModel.state.messages.last.content, 'partial');
    expect(viewModel.state.messages.last.status, ChatMessageStatus.error);
    expect(viewModel.state.isResponding, isFalse);
  });

  test('retryLast re-sends the failed prompt', () async {
    final repository = FakeChatRepository(error: const ChatException('boom'));
    final viewModel = build(repository);
    await viewModel.init();
    await viewModel.send('hi');
    await pumpEventQueue();

    await viewModel.retryLast();
    await pumpEventQueue();

    expect(repository.calls, hasLength(2));
    expect(viewModel.state.messages.map((m) => m.content), ['hi', 'Hello']);
  });

  test('stop keeps the text received so far', () async {
    final repository = ManualChatRepository();
    final viewModel = build(repository);
    await viewModel.init();
    await viewModel.send('hi');

    repository.emit('half ');
    await pumpEventQueue();
    await viewModel.stop();

    expect(viewModel.state.isResponding, isFalse);
    expect(viewModel.state.messages.last.content, 'half ');
    expect(viewModel.state.messages.last.status, ChatMessageStatus.done);
  });

  test('newSession reuses the current session while it is empty', () async {
    final viewModel = build(FakeChatRepository());
    await viewModel.init();
    final first = viewModel.state.activeSessionId;

    await viewModel.newSession();

    expect(viewModel.state.sessions, hasLength(1));
    expect(viewModel.state.activeSessionId, first);
  });

  test('newSession starts a fresh thread once the current one is used', () async {
    final viewModel = build(FakeChatRepository());
    await viewModel.init();
    await viewModel.send('hi');
    await pumpEventQueue();

    await viewModel.newSession();

    expect(viewModel.state.sessions, hasLength(2));
    expect(viewModel.state.messages, isEmpty);
  });

  test('deleteSession always leaves an active session', () async {
    final viewModel = build(FakeChatRepository());
    await viewModel.init();
    await viewModel.send('hi');
    await pumpEventQueue();

    await viewModel.deleteSession(viewModel.state.activeSessionId!);

    expect(viewModel.state.activeSession, isNotNull);
    expect(viewModel.state.messages, isEmpty);
  });

  test('dispose releases the repository', () async {
    final repository = FakeChatRepository();
    final viewModel = build(repository);
    await viewModel.init();
    viewModel.dispose();

    expect(repository.disposed, isTrue);
  });
}
