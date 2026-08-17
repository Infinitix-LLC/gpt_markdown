import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

const testConfig = PlusfinityConfig(apiKey: 'plus_live_test');

/// Emits a fixed script of deltas, optionally failing at the end.
class FakeAdapter extends StreamingChatAdapter {
  FakeAdapter({this.deltas = const ['Hello'], this.error, super.store});

  final List<String> deltas;
  final Object? error;
  final List<List<ChatMessage>> calls = [];
  bool disposed = false;

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
    calls.add(history);
    for (final delta in deltas) {
      yield ChatDelta(delta);
    }
    if (error != null) throw error!;
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Lets a test drive the reply stream by hand.
class ManualAdapter extends StreamingChatAdapter {
  final _controller = StreamController<ChatDelta>();

  void emit(String delta) => _controller.add(ChatDelta(delta));
  void finish() => _controller.close();

  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) =>
      _controller.stream;

  @override
  void dispose() {
    if (!_controller.isClosed) _controller.close();
    super.dispose();
  }
}

/// Records the model the UI picked.
class FakeModelSource extends StaticChatModelSource {
  FakeModelSource()
    : super(
        models: const [
          ChatModelOption(id: 'gpt-5.4'),
          ChatModelOption(id: 'gemini-3.6-flash'),
        ],
        selected: 'gpt-5.4',
      );

  String? chosen;

  @override
  void select(String modelId) {
    chosen = modelId;
    super.select(modelId);
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

/// An assistant message, for widgets pumped in isolation.
SimpleChatMessage reply(String content, {String id = 'm1'}) =>
    SimpleChatMessage(
      id: id,
      role: ChatRole.assistant,
      content: content,
      createdAt: DateTime(2024),
    );

/// Builds a scope around [child] so chat widgets can be pumped on their own.
Widget scopedChat({
  required Widget child,
  ChatAdapter? adapter,
  ArtifactService? artifactService,
  ValArtifactBuilder? artifactBuilder,
  GenUiRegistry? genUi,
}) {
  final chatAdapter = adapter ?? FakeAdapter();
  final artifacts = ArtifactRepository(
    service: artifactService ?? FakeArtifactService(),
  );
  final registry = chatGenUiRegistry(genUi);

  Widget buildGenUi(BuildContext context, String payload) {
    final legacy = parseLegacyGenUiArtifact(payload);
    if (legacy != null) return ValArtifactCard(initial: legacy);
    return registry.build(context, payload);
  }

  return MaterialApp(
    home: Builder(
      builder:
          (context) => ArtifactScope(
            store: ArtifactStore(repository: artifacts),
            builder: artifactBuilder,
            child: ChatScope(
              controller: ChatController(adapter: chatAdapter),
              theme: ChatTheme.of(context),
              genUi: registry,
              builders: ChatBuilders(genUi: buildGenUi),
              child: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
    ),
  );
}
