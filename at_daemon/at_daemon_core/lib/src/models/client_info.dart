class ClientInfo {
  final String clientId; // Web URL or applicationId
  final String clientName; // Human readable / pretty version of clientId
  final String syncSpace; // Requesting application's syncSpace

  ClientInfo({
    required this.clientId,
    String? clientName, // defaults to match clientId
    this.syncSpace = '.*', // defaults to everything
  }) : clientName = clientName ?? clientId;
}
