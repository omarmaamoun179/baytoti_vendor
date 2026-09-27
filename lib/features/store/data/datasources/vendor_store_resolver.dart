import '../../../../core/app/session_notifier.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json_read.dart';

/// Which store the signed-in family works on: the first of
/// `GET /vendor/stores`. The API scopes products to a store while the app
/// speaks of "the store" — registration creates exactly one — so the store
/// and products sources both ask this.
///
/// Called inside a data source's `guardedRequest`, so it throws rather than
/// answering with `Either`: an account with no store is a
/// `RequestException('store_missing')`, and an answer that is not a list is
/// a `FormatException` — unexpected, never read as "no store".
///
/// The id is kept for the session and forgotten with it
/// ([SessionNotifier]): another account owns another store.
class VendorStoreResolver {
  final NetworkService _networkService;
  final SessionNotifier _sessionNotifier;

  int? _storeId;

  VendorStoreResolver(this._networkService, this._sessionNotifier) {
    _sessionNotifier.addListener(_forget);
  }

  /// The store's id, read once a session.
  Future<int> storeId() async {
    final known = _storeId;
    if (known != null) return known;

    await store();
    return _storeId!;
  }

  /// The store as `GET /vendor/stores` lists it, read afresh.
  Future<Map<String, dynamic>> store() async {
    final envelope = checkedResponse(
      await _networkService.get(ApiEndPoint.vendorStores),
    );

    final data = envelope.data;
    if (data is! List) {
      throw FormatException('vendor/stores sent no list', data);
    }

    final stores = [
      for (final row in asMapList(data))
        if (asInt(row['id']) != null) row,
    ];
    if (stores.isEmpty) {
      throw const RequestException('store_missing', statusCode: 404);
    }

    _storeId = asInt(stores.first['id']);
    return stores.first;
  }

  void _forget() => _storeId = null;
}
