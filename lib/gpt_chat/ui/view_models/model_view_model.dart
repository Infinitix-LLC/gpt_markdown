import 'package:flutter/foundation.dart';

import '../../data/models/chat_exception.dart';
import '../../data/models/gateway_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/model_repository.dart';

/// Model list and current choice. Switching is a one-word change for the user.
class ModelViewModel extends ChangeNotifier {
  ModelViewModel({
    required ModelRepository repository,
    required ChatRepository chat,
    required String initialModel,
  }) : _repository = repository,
       _chat = chat,
       _selected = initialModel;

  final ModelRepository _repository;
  final ChatRepository _chat;

  List<GatewayModel> _models = const [];
  String _selected;
  bool _isLoading = false;
  String? _error;

  List<GatewayModel> get models => _models;
  String get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// A failed lookup is not fatal — the configured model still works.
  Future<void> load() async {
    if (_isLoading || _models.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _models = await _repository.list();
      _error = null;
    } catch (e) {
      _error = e is ChatException ? e.message : 'Could not load models.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void select(String model) {
    if (model == _selected) return;

    _selected = model;
    _chat.selectModel(model);
    notifyListeners();
  }
}
