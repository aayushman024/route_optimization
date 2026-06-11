class Client {
  final String clientId;
  final String clientName;
  final int order;
  final double latitude;
  final double longitude;
  final String visitingAddress;

  Client({
    required this.clientId,
    required this.clientName,
    required this.order,
    required this.latitude,
    required this.longitude,
    required this.visitingAddress,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      clientId: json['clientId'],
      clientName: json['clientName'],
      order: json['order'],
      latitude: (json['coordinates'][1] as num).toDouble(),
      longitude: (json['coordinates'][0] as num).toDouble(),
      visitingAddress: json['visitingAddress'],
    );
  }
}
