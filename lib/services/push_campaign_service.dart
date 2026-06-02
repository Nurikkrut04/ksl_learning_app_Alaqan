import 'package:cloud_functions/cloud_functions.dart';

class PushCampaignResult {
  final bool success;
  final String campaignId;
  final String audience;
  final int targetedCount;
  final int successCount;
  final int failureCount;
  final int invalidTokenCount;
  final String message;

  const PushCampaignResult({
    required this.success,
    required this.campaignId,
    required this.audience,
    required this.targetedCount,
    required this.successCount,
    required this.failureCount,
    required this.invalidTokenCount,
    required this.message,
  });

  factory PushCampaignResult.fromMap(Map<String, dynamic> map) {
    return PushCampaignResult(
      success: map['success'] == true,
      campaignId: (map['campaignId'] ?? '').toString(),
      audience: (map['audience'] ?? '').toString(),
      targetedCount: _toInt(map['targetedCount']),
      successCount: _toInt(map['successCount']),
      failureCount: _toInt(map['failureCount']),
      invalidTokenCount: _toInt(map['invalidTokenCount']),
      message: (map['message'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class PushCampaignService {
  PushCampaignService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<PushCampaignResult> sendCampaign({
    required String title,
    required String body,
    required String audience,
    String route = '',
  }) async {
    final callable = _functions.httpsCallable('sendPushCampaign');
    final response = await callable.call<Map<String, dynamic>>({
      'title': title,
      'body': body,
      'audience': audience,
      'route': route,
    });

    final rawData = response.data;
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return PushCampaignResult.fromMap(data);
  }
}
