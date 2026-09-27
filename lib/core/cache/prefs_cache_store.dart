import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cache_envelope.dart';

/// SharedPreferences-backed cache store, namespaced key-value with an
/// [CacheEnvelope] wrapper — the parent-app counterpart of the driver/
/// supervisor apps' Hive-backed `HiveCacheStore`. Currently backs the
/// route-geometry cache (see `CachingDirectionsService`) only.
///
/// Takes the raw [SharedPreferences] instance rather than this app's
/// `SharedPrefService` wrapper: [SharedPrefService.readString] wraps a
/// synchronous `getString` in a needless `Future`, and `read` here must stay
/// SYNCHRONOUS — `CachingDirectionsService._readDisk` calls it inline before
/// an L2 freshness decision, and its `peek()` (used to paint a cached route
/// instantly, before the first network response) is itself synchronous.
/// `SharedPreferences` is already a DI singleton, loaded once at startup with
/// the whole store resident in memory, so `getString`/`getKeys` cost no I/O.
///
/// SharedPreferences is one flat keyspace shared with `user_data`,
/// `cart_uuid`, easy_localization's own keys, and everything else in the
/// app — every key this store touches is prefixed with [namespace] so a
/// prefix scan ([deleteByPrefix], [sweepExpired], [capEntries], [clear])
/// can never touch anything outside its own feature's entries.
///
/// Reads self-heal: a corrupt or schema-mismatched entry is deleted and
/// treated as a miss rather than surfacing a decode error.
class PrefsCacheStore {
  PrefsCacheStore(this._prefs, {required String namespace})
      : _ns = '$namespace:';

  final SharedPreferences _prefs;
  final String _ns;

  String _namespaced(String key) => '$_ns$key';

  /// The envelope stored at [key], or `null` on a miss or a poisoned entry
  /// (deleted as a side effect so it self-heals on the next write).
  CacheEnvelope? read(String key) {
    final String? raw = _prefs.getString(_namespaced(key));
    if (raw == null) return null;
    try {
      return CacheEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      unawaited(_prefs.remove(_namespaced(key)));
      return null;
    }
  }

  /// Write-through: stamps [payload] with the current time (or [savedAt], for
  /// a caller that owns its own clock — MUST match whatever clock that
  /// caller judges freshness with, e.g. an injected `now()` in
  /// `CachingDirectionsService`, or the freshness window measures one clock
  /// against another and stops meaning anything).
  Future<void> write(
    String key,
    Map<String, dynamic> payload, {
    DateTime? savedAt,
  }) =>
      _prefs.setString(
        _namespaced(key),
        jsonEncode(
          CacheEnvelope(savedAt: savedAt ?? DateTime.now(), payload: payload)
              .toJson(),
        ),
      );

  Future<void> delete(String key) => _prefs.remove(_namespaced(key));

  /// Deletes every entry (within this namespace) whose key starts with
  /// [prefix] — e.g. everything cached for one trip.
  Future<void> deleteByPrefix(String prefix) async {
    final String fullPrefix = _namespaced(prefix);
    final List<String> matching =
        _prefs.getKeys().where((k) => k.startsWith(fullPrefix)).toList();
    for (final String key in matching) {
      await _prefs.remove(key);
    }
  }

  /// Deletes every entry older than [maxAge] (and any undecodable one).
  /// Intended to run once at launch.
  Future<void> sweepExpired(Duration maxAge) async {
    final DateTime cutoff = DateTime.now().subtract(maxAge);
    final List<String> keys =
        _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    for (final String key in keys) {
      final String? raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final env =
            CacheEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (env.savedAt.isBefore(cutoff)) await _prefs.remove(key);
      } catch (_) {
        await _prefs.remove(key); // poisoned — drop regardless of age
      }
    }
  }

  /// Keeps only the [max] most-recently-saved entries in this namespace,
  /// deleting the rest. A hard bound on file size independent of TTL math —
  /// this app tracks at most one or two trips a day, so [max] comfortably
  /// covers a week without the backing store growing unbounded.
  Future<void> capEntries(int max) async {
    final List<String> keys =
        _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    if (keys.length <= max) return;
    final List<MapEntry<String, DateTime>> withTimes = [];
    for (final String key in keys) {
      final String? raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final env =
            CacheEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        withTimes.add(MapEntry(key, env.savedAt));
      } catch (_) {
        await _prefs.remove(key); // poisoned — drop regardless of the cap
      }
    }
    withTimes.sort((a, b) => b.value.compareTo(a.value)); // newest first
    for (final entry in withTimes.skip(max)) {
      await _prefs.remove(entry.key);
    }
  }

  /// Drops every entry in this namespace (called on logout — route geometry
  /// traces the child's home address).
  Future<void> clear() async {
    final List<String> keys =
        _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    for (final String key in keys) {
      await _prefs.remove(key);
    }
  }
}
