import '../models/plusfinity_config.dart';
import '../models/val_artifact.dart';
import 'gateway_client.dart';

/// Reads generated animations. The per-artifact token is the credential here,
/// so these calls are safe from a client app.
class ArtifactService {
  ArtifactService({required this.config, GatewayClient? client})
    : _client = client ?? GatewayClient(config: config);

  final PlusfinityConfig config;
  final GatewayClient _client;

  Future<ValArtifact> fetch(String id, String? token) async {
    final json = await _client.getJson(config.artifactUri(id, token));
    return ValArtifact.fromJson(json);
  }

  /// queued → generating → narrating → ready.
  Stream<ValArtifact> watch(String id, String? token) =>
      _client.sse(config.artifactEventsUri(id, token)).map(ValArtifact.fromJson);

  void dispose() => _client.close();
}
