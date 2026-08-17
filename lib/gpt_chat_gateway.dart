/// The Plusfinity Gateway client for `gpt_chat`.
///
/// ```dart
/// GatewayChat(config: PlusfinityConfig(apiKey: 'plus_live_…'))
/// ```
///
/// Kept out of `gpt_chat.dart` so an app bringing its own backend does not pull
/// in the HTTP client, the gateway models, or the animation pipeline.
///
/// `/chat/completions` blocks browsers by design — on Flutter web, point
/// [PlusfinityConfig.baseUrl] at your own server-side proxy so the key never
/// ships in a bundle.
library;

export 'gpt_chat.dart';
export 'gpt_chat/src/gateway/artifact_scope.dart';
export 'gpt_chat/src/gateway/artifact_status_line.dart';
export 'gpt_chat/src/gateway/chat_gen_ui.dart';
export 'gpt_chat/src/gateway/gateway_chat.dart';
export 'gpt_chat/src/gateway/gateway_chat_adapter.dart';
export 'gpt_chat/src/gateway/gateway_model_source.dart';
export 'gpt_chat/src/gateway/models/artifact_frame.dart';
export 'gpt_chat/src/gateway/models/chat_exception.dart';
export 'gpt_chat/src/gateway/models/completion_chunk.dart';
export 'gpt_chat/src/gateway/models/gateway_model.dart';
export 'gpt_chat/src/gateway/models/gen_ui_widget_types.dart';
export 'gpt_chat/src/gateway/models/plusfinity_config.dart';
export 'gpt_chat/src/gateway/models/reasoning_effort.dart';
export 'gpt_chat/src/gateway/models/val_artifact.dart';
export 'gpt_chat/src/gateway/models/widget_selection.dart';
export 'gpt_chat/src/gateway/repositories/artifact_repository.dart';
export 'gpt_chat/src/gateway/services/artifact_service.dart';
export 'gpt_chat/src/gateway/services/gateway_chat_service.dart';
export 'gpt_chat/src/gateway/services/gateway_client.dart';
export 'gpt_chat/src/gateway/services/genui_parser.dart';
export 'gpt_chat/src/gateway/services/sse_decoder.dart';
export 'gpt_chat/src/gateway/val_artifact_card.dart';
