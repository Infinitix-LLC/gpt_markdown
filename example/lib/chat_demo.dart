import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'adapter_demo.dart';

/// A few of the models the gateway serves — the chat's own picker reads the
/// live list from `GET /models`.
const _models = [
  'gpt-5.6-luna',
  'gpt-5.6-sol',
  'gpt-5.4',
  'gemini-3.6-flash',
  'gemini-3.1-pro-preview',
];

/// The `x_plusfinity.widgets` options, as offered in the demo.
enum _Widgets {
  all('All 18', WidgetSelection.all),
  defaults('Default 9', WidgetSelection.defaults),
  chartsOnly('Charts only', null),
  none('None — plain text', WidgetSelection.none);

  const _Widgets(this.label, this._selection);

  final String label;
  final WidgetSelection? _selection;

  WidgetSelection get selection =>
      _selection ??
      WidgetSelection.only(const ['line_chart', 'bar_chart', 'pie_chart']);
}

/// Setup screen for the Plusfinity Gateway chat. Fill in a key, pick a frame,
/// and the next page is a working chat UI.
class ChatDemoPage extends StatefulWidget {
  const ChatDemoPage({super.key});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  final _apiKey = TextEditingController(text: 'plus_live_test');
  final _baseUrl = TextEditingController(text: PlusfinityConfig.defaultBaseUrl);
  final _model = TextEditingController(text: 'gpt-5.4');

  ArtifactFrame _frame = ArtifactFrame.square;
  bool _artifacts = true;
  _Widgets _widgets = _Widgets.all;
  ReasoningEffort? _effort;

  @override
  void dispose() {
    _apiKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    super.dispose();
  }

  void _openChat() {
    final config = PlusfinityConfig(
      apiKey: _apiKey.text.trim(),
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
      frame: _frame,
      artifactsEnabled: _artifacts,
      widgets: _widgets.selection,
      reasoningEffort: _effort,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            GatewayChat(config: config, showGenUiPreview: true),
      ),
    );
  }

  void _openGenUiPreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const GenUiPreviewPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plusfinity chat demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cable),
            tooltip: 'Adapter demo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AdapterDemoPage(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Gen UI preview',
            onPressed: _openGenUiPreview,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Any non-empty key is accepted while the gateway is pre-launch.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          _Field(controller: _baseUrl, label: 'Base URL'),
          _Field(controller: _apiKey, label: 'API key'),
          _Field(
            controller: _model,
            label: 'Model',
            helper: 'OpenAI or Gemini — same request either way',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final id in _models)
                ActionChip(
                  label: Text(id),
                  onPressed: () => setState(() => _model.text = id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<_Widgets>(
            initialValue: _widgets,
            decoration: const InputDecoration(labelText: 'Gen UI widgets'),
            items: [
              for (final option in _Widgets.values)
                DropdownMenuItem(value: option, child: Text(option.label)),
            ],
            onChanged: (value) => setState(() => _widgets = value ?? _widgets),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ReasoningEffort?>(
            initialValue: _effort,
            decoration: const InputDecoration(
              labelText: 'Reasoning effort',
              helperText: 'Reasoning models reject temperature — use this',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('unset')),
              for (final effort in ReasoningEffort.values)
                DropdownMenuItem(value: effort, child: Text(effort.wireName)),
            ],
            onChanged: (value) => setState(() => _effort = value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ArtifactFrame>(
            initialValue: _frame,
            decoration: const InputDecoration(labelText: 'Animation frame'),
            items: [
              for (final frame in ArtifactFrame.values)
                DropdownMenuItem(value: frame, child: Text(frame.wireName)),
            ],
            onChanged: (frame) => setState(() => _frame = frame ?? _frame),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _artifacts,
            title: const Text('Generate animations'),
            subtitle:
                const Text('Off turns the gateway into a plain model proxy'),
            onChanged: (value) => setState(() => _artifacts = value),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _openChat, child: const Text('Open chat')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openGenUiPreview,
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('Open gen UI preview (no gateway needed)'),
          ),
          const SizedBox(height: 16),
          const _Hints(),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.helper});

  final TextEditingController controller;
  final String label;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );
  }
}

class _Hints extends StatelessWidget {
  const _Hints();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Try asking', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text('• Animate how a seed grows into a plant.'),
        const Text('• Explain the Pythagorean theorem with math.'),
        if (kIsWeb) ...[
          const SizedBox(height: 12),
          Text(
            'On web the gateway blocks /chat/completions by design — point the '
            'base URL at your own server-side proxy.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
