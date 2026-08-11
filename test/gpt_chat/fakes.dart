import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

const testConfig = PlusfinityConfig(apiKey: 'plus_live_test');

/// Emits a fixed script of deltas, optionally failing at the end.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.deltas = const ['Hello'], this.error});

  final List<String> deltas;
  final Object? error;
  final List<List<ChatMessage>> calls = [];
  String? selectedModel;
  bool disposed = false;

  @override
  Stream<String> streamReply(List<ChatMessage> history) async* {
    calls.add(history);
    for (final delta in deltas) {
      yield delta;
    }
    if (error != null) throw error!;
  }

  @override
  void selectModel(String model) => selectedModel = model;

  @override
  void dispose() => disposed = true;
}

/// Lets a test drive the reply stream by hand.
class ManualChatRepository implements ChatRepository {
  final _controller = StreamController<String>();

  void emit(String delta) => _controller.add(delta);
  void finish() => _controller.close();

  @override
  Stream<String> streamReply(List<ChatMessage> history) => _controller.stream;

  @override
  void selectModel(String model) {}

  @override
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}

/// Replays artifact updates without touching the network.
class FakeArtifactService extends ArtifactService {
  FakeArtifactService() : super(config: testConfig);

  final Map<String, StreamController<ValArtifact>> _controllers = {};
  final List<String> watched = [];

  void emit(String id, ValArtifact artifact) => _controllers[id]?.add(artifact);

  void failWatch(String id, Object error) => _controllers[id]?.addError(error);

  @override
  Stream<ValArtifact> watch(String id, String? token) {
    watched.add(id);
    return (_controllers[id] = StreamController<ValArtifact>()).stream;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}

/// Builds a scope around [child] so widgets can be pumped in isolation.
Widget scopedChat({
  required Widget child,
  ChatRepository? chat,
  ArtifactService? artifactService,
  ValArtifactBuilder? artifactBuilder,
  GenUiRegistry? genUi,
}) {
  final chatRepository = chat ?? FakeChatRepository();
  final artifacts = ArtifactRepository(service: artifactService ?? FakeArtifactService());
  final chatViewModel = ChatViewModel(
    chatRepository: chatRepository,
    sessionRepository: SessionRepository(store: InMemorySessionStore()),
  );
  final modelViewModel = ModelViewModel(
    repository: ModelRepository(service: GatewayChatService(config: testConfig)),
    chat: chatRepository,
    initialModel: testConfig.model,
  );

  return MaterialApp(
    home: ChatScope(
      chat: chatViewModel,
      artifacts: ArtifactViewModel(repository: artifacts),
      models: modelViewModel,
      controller: ChatController(chat: chatViewModel, models: modelViewModel),
      genUi: chatGenUiRegistry(genUi),
      artifactBuilder: artifactBuilder,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}
