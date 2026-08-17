/// A chat UI layer for any app, rendered with `gpt_markdown`.
///
/// The package owns the shell — scaffold, transcript, scrolling, composer,
/// theming. Where the conversation comes from is yours: implement a
/// [ChatAdapter] over whatever state layer you already have, or extend
/// [StreamingChatAdapter] if you have none.
///
/// ```dart
/// class EchoAdapter extends StreamingChatAdapter {
///   @override
///   Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
///     yield ChatDelta('You said: ${history.last.content}');
///   }
/// }
///
/// GptChat(adapter: EchoAdapter());
/// ```
///
/// Customization is progressive:
///
/// * [ChatTheme] for colours, radii, spacing, widths, typography.
/// * [ChatBuilders] to replace or decorate individual parts. Every builder is
///   handed the default widget *and* the parts that composed it, so overriding
///   one level never forces you to rebuild the levels beneath it.
/// * [ChatScope] over your own page, using the exported widgets à la carte.
///
/// The Plusfinity Gateway client lives in `gpt_chat_gateway.dart`; this library
/// pulls in no HTTP dependency.
library;

export 'gen_ui/gen_ui.dart';
export 'gpt_chat/src/adapter/chat_adapter.dart';
export 'gpt_chat/src/adapter/chat_capabilities.dart';
export 'gpt_chat/src/adapter/chat_delta.dart';
export 'gpt_chat/src/adapter/chat_draft.dart';
export 'gpt_chat/src/adapter/chat_message.dart';
export 'gpt_chat/src/adapter/chat_model_source.dart';
export 'gpt_chat/src/adapter/chat_session.dart';
export 'gpt_chat/src/adapter/chat_snapshot.dart';
export 'gpt_chat/src/adapter/session_store.dart';
export 'gpt_chat/src/adapter/streaming_chat_adapter.dart';
export 'gpt_chat/src/builders/chat_builders.dart';
export 'gpt_chat/src/builders/chat_slots.dart';
export 'gpt_chat/src/controller/chat_controller.dart';
export 'gpt_chat/src/controller/chat_message_pair.dart';
export 'gpt_chat/src/theme/chat_theme.dart';
export 'gpt_chat/src/widgets/chat_answer.dart';
export 'gpt_chat/src/widgets/chat_app_bar.dart';
export 'gpt_chat/src/widgets/chat_attachments.dart';
export 'gpt_chat/src/widgets/chat_composer.dart';
export 'gpt_chat/src/widgets/chat_drawer.dart';
export 'gpt_chat/src/widgets/chat_indicators.dart';
export 'gpt_chat/src/widgets/chat_model_picker.dart';
export 'gpt_chat/src/widgets/chat_question.dart';
export 'gpt_chat/src/widgets/chat_scope.dart';
export 'gpt_chat/src/widgets/chat_transcript.dart';
export 'gpt_chat/src/widgets/chat_view.dart';
export 'gpt_chat/src/widgets/gpt_chat.dart';
