import 'package:flutter/foundation.dart';

/// One entry in the model picker.
@immutable
class ChatModelOption {
  const ChatModelOption({
    required this.id,
    this.label,
    this.description,
    this.iconData,
  });

  final String id;

  /// Shown in the picker. Falls back to [id].
  final String? label;

  /// Second line in the picker sheet.
  final String? description;

  /// Code point of a Material icon, kept as an int so this stays free of
  /// `dart:ui` for a future non-Flutter port.
  final int? iconData;

  String get name => label ?? id;

  @override
  bool operator ==(Object other) => other is ChatModelOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Model list and current choice.
///
/// Separate from [ChatAdapter] because plenty of hosts have exactly one model
/// and want no picker at all — those pass none and leave
/// `ChatCapabilities.models` false.
abstract class ChatModelSource extends ChangeNotifier {
  List<ChatModelOption> get models;

  /// Id of the current choice. May not appear in [models] while the list is
  /// still loading or has failed — the picker keeps showing it regardless.
  String get selected;

  bool get isLoading;

  /// Last lookup failure, or null. Never fatal: the selected model still works.
  String? get error;

  /// Fetches the list. Safe to call repeatedly; implementations should no-op
  /// once loaded.
  Future<void> load();

  void select(String modelId);
}

/// A fixed list, for hosts that know their models up front.
class StaticChatModelSource extends ChatModelSource {
  StaticChatModelSource({
    required List<ChatModelOption> models,
    String? selected,
    this.onSelected,
  }) : _models = models,
       _selected = selected ?? (models.isNotEmpty ? models.first.id : '');

  final List<ChatModelOption> _models;
  String _selected;

  /// Called after a choice, so the host can push it into its own request layer.
  final void Function(String modelId)? onSelected;

  @override
  List<ChatModelOption> get models => _models;

  @override
  String get selected => _selected;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> load() async {}

  @override
  void select(String modelId) {
    if (modelId == _selected) return;
    _selected = modelId;
    onSelected?.call(modelId);
    notifyListeners();
  }
}
