import 'package:flutter/foundation.dart';

import 'artifact_frame.dart';
import 'reasoning_effort.dart';
import 'widget_selection.dart';

/// Connection settings for the Plusfinity Gateway (OpenAI-compatible).
///
/// `/chat/completions` blocks browsers by design — on Flutter web, point
/// [baseUrl] at your own server-side proxy so the key never ships in a bundle.
class PlusfinityConfig {
  const PlusfinityConfig({
    required this.apiKey,
    this.baseUrl = defaultBaseUrl,
    this.model = 'gpt-5.4',
    this.systemPrompt,
    this.temperature,
    this.maxTokens,
    this.reasoningEffort,
    this.stream = true,
    this.headers = const {},
    this.historyLimit = 40,
    this.timeout = const Duration(seconds: 90),
    this.widgets = WidgetSelection.defaults,
    this.frame = ArtifactFrame.square,
    this.languageCode,
    this.artifactsEnabled = true,
  });

  static const defaultBaseUrl = 'https://us-central1-yalagpt.cloudfunctions.net/v1';

  final String apiKey;

  /// Root of the API, with or without a trailing slash.
  final String baseUrl;
  final String model;
  final String? systemPrompt;

  /// Rejected by the reasoning models — use [reasoningEffort] there instead.
  final double? temperature;
  final int? maxTokens;

  /// Thinking depth for reasoning models. Ignored by the others.
  final ReasoningEffort? reasoningEffort;

  /// Server-sent-events streaming. Falls back to a single response when false.
  final bool stream;

  /// Extra headers merged over `Authorization` and `Content-Type`.
  final Map<String, String> headers;

  /// Most recent messages sent as context.
  final int historyLimit;
  final Duration timeout;

  /// Which gen-UI widgets the model may draw.
  final WidgetSelection widgets;

  /// Aspect ratio for generated animations.
  final ArtifactFrame frame;

  /// Narration language. Null lets the gateway detect it.
  final String? languageCode;

  /// False turns the gateway into a plain model proxy — no animations.
  final bool artifactsEnabled;

  Uri get completionsUri => _endpoint('chat/completions');
  Uri get modelsUri => _endpoint('models');

  Uri artifactUri(String id, String? token) => _endpoint('artifacts/$id', token);
  Uri artifactEventsUri(String id, String? token) => _endpoint('artifacts/$id/events', token);

  Uri _endpoint(String path, [String? token]) {
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$root/$path').replace(queryParameters: token == null ? null : {'token': token});
  }

  Map<String, String> get requestHeaders => {
    'Content-Type': 'application/json',
    if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    ...headers,
  };

  /// The `x_plusfinity` request extension. Omitted when everything is default.
  Map<String, dynamic>? get requestExtension {
    final extension = <String, dynamic>{
      if (!widgets.isDefault) 'widgets': widgets.toWire(),
      if (frame != ArtifactFrame.square) 'frame': frame.wireName,
      if (languageCode != null) 'languageCode': languageCode,
      if (!artifactsEnabled) 'artifacts': false,
    };
    return extension.isEmpty ? null : extension;
  }

  PlusfinityConfig copyWith({
    String? model,
    ArtifactFrame? frame,
    String? languageCode,
    WidgetSelection? widgets,
    ReasoningEffort? reasoningEffort,
  }) {
    return PlusfinityConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model ?? this.model,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      stream: stream,
      headers: headers,
      historyLimit: historyLimit,
      timeout: timeout,
      widgets: widgets ?? this.widgets,
      frame: frame ?? this.frame,
      languageCode: languageCode ?? this.languageCode,
      artifactsEnabled: artifactsEnabled,
    );
  }

  // Value equality keeps an inline `PlusfinityConfig(...)` from rebuilding the view model.
  @override
  bool operator ==(Object other) =>
      other is PlusfinityConfig &&
      other.baseUrl == baseUrl &&
      other.apiKey == apiKey &&
      other.model == model &&
      other.systemPrompt == systemPrompt &&
      other.temperature == temperature &&
      other.maxTokens == maxTokens &&
      other.reasoningEffort == reasoningEffort &&
      other.stream == stream &&
      other.historyLimit == historyLimit &&
      other.timeout == timeout &&
      other.widgets == widgets &&
      other.frame == frame &&
      other.languageCode == languageCode &&
      other.artifactsEnabled == artifactsEnabled &&
      mapEquals(other.headers, headers);

  @override
  int get hashCode => Object.hash(
    baseUrl,
    apiKey,
    model,
    systemPrompt,
    temperature,
    maxTokens,
    reasoningEffort,
    stream,
    historyLimit,
    timeout,
    widgets,
    frame,
    languageCode,
    artifactsEnabled,
    Object.hashAllUnordered(headers.entries.map((e) => Object.hash(e.key, e.value))),
  );
}
