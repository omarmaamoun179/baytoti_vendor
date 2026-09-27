/// Freshness wrapper around a cached read payload.
///
/// Every cached read is stored as a JSON string (see [PrefsCacheStore],
/// namespaced within `SharedPreferences`'s single flat keyspace) wrapped in
/// this envelope, so freshness is tracked **per entry** rather than per
/// device-online moment.
class CacheEnvelope {
  const CacheEnvelope({required this.savedAt, required this.payload});

  /// When this payload was written through from a successful network read.
  final DateTime savedAt;

  /// The decoded JSON payload.
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'saved_at': savedAt.toIso8601String(),
        'payload': payload,
      };

  factory CacheEnvelope.fromJson(Map<String, dynamic> json) => CacheEnvelope(
        savedAt: DateTime.parse(json['saved_at'] as String),
        payload: json['payload'] as Map<String, dynamic>,
      );
}
