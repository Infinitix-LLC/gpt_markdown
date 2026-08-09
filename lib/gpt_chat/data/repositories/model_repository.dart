import '../models/gateway_model.dart';
import '../services/gateway_chat_service.dart';

/// Models available to the key, fetched once per session.
class ModelRepository {
  ModelRepository({required GatewayChatService service}) : _service = service;

  final GatewayChatService _service;
  List<GatewayModel>? _cache;

  Future<List<GatewayModel>> list() async => _cache ??= await _service.listModels();
}
