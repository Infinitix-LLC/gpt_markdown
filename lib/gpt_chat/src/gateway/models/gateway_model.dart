/// An entry from `GET /models`.
class GatewayModel {
  const GatewayModel({required this.id, this.ownedBy});

  final String id;
  final String? ownedBy;

  factory GatewayModel.fromJson(Map<String, dynamic> json) => GatewayModel(
    id: json['id'] as String? ?? '',
    ownedBy: json['owned_by'] as String?,
  );
}
