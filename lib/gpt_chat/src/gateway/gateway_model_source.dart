import '../adapter/chat_model_source.dart';
import 'gateway_chat_adapter.dart';
import 'models/chat_exception.dart';

/// The models a gateway key can reach, fetched once per session.
class GatewayModelSource extends ChatModelSource {
  GatewayModelSource({required GatewayChatAdapter adapter})
    : _adapter = adapter,
      _selected = adapter.model;

  final GatewayChatAdapter _adapter;

  List<ChatModelOption> _models = const [];
  String _selected;
  bool _isLoading = false;
  String? _error;

  @override
  List<ChatModelOption> get models => _models;

  @override
  String get selected => _selected;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  /// A failed lookup is not fatal — the configured model still works.
  @override
  Future<void> load() async {
    if (_isLoading || _models.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _adapter.service.listModels();
      _models = [
        for (final model in fetched)
          ChatModelOption(id: model.id, description: model.ownedBy),
      ];
      _error = null;
    } catch (e) {
      _error = e is ChatException ? e.message : 'Could not load models.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void select(String modelId) {
    if (modelId == _selected) return;

    _selected = modelId;
    _adapter.selectModel(modelId);
    notifyListeners();
  }
}
