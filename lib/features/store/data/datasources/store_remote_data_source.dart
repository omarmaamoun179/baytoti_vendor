import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json_read.dart';
import '../../domain/entities/store_profile.dart';
import '../models/store_profile_model.dart';
import 'store_data_source.dart';
import 'vendor_store_resolver.dart';

/// The family's store on the live API: the first of `GET /vendor/stores`,
/// saved with `PUT /vendor/stores/{store}`, and the governorates of its
/// country as the places it may trade.
class StoreRemoteDataSource implements StoreDataSource {
  final NetworkService _networkService;
  final VendorStoreResolver _stores;

  /// Governorates by country, read once: they change with the platform, not
  /// with a session.
  final Map<int, List<StoreArea>> _areas = {};

  /// The country whose governorates were last offered — what a save sends
  /// beside the chosen one.
  int? _countryId;

  StoreRemoteDataSource(this._networkService, this._stores);

  @override
  Future<Either<Failure, StoreProfileModel>> getStore() => guardedRequest(
        'StoreRemoteDataSource.getStore',
        () async => _profileOf(await _stores.store()),
        fallbackMessage: 'store_failed',
        messageForStatus: const {404: 'store_missing'},
      );

  @override
  Future<Either<Failure, StoreProfileModel>> updateStore(
    UpdateStoreParams params,
  ) =>
      guardedRequest(
        'StoreRemoteDataSource.updateStore',
        () async {
          final id = await _stores.storeId();
          final envelope = checkedResponse(
            await _networkService.put(
              ApiEndPoint.vendorStore('$id'),
              data: updateStoreBody(params, countryId: _countryId),
            ),
          );

          // Typed only as "object": the store, the store under `store`, or a
          // bare confirmation — then it is read back.
          final data = envelope.dataMap;
          final saved = data['store'] is Map ? asMap(data['store']) : data;
          return _profileOf(
            asInt(saved['id']) == null ? await _stores.store() : saved,
          );
        },
        fallbackMessage: 'store_save_failed',
        messageForStatus: const {404: 'store_missing'},
      );

  Future<StoreProfileModel> _profileOf(Map<String, dynamic> store) async {
    final countryId = countryIdOf(store) ?? await _firstCountryId();
    _countryId = countryId;

    return StoreProfileModel.fromApi(
      store,
      areas: countryId == null ? const [] : await _areasOf(countryId),
    );
  }

  Future<List<StoreArea>> _areasOf(int countryId) async {
    final known = _areas[countryId];
    if (known != null) return known;

    final envelope = checkedResponse(
      await _networkService.get(
        ApiEndPoint.governorates('$countryId'),
        skipAuthRefresh: true,
      ),
    );
    return _areas[countryId] = areasFromApi(envelope.dataList);
  }

  /// A store with no country yet is offered the first active country's
  /// governorates, and saved into that country with the one chosen.
  Future<int?> _firstCountryId() async {
    final envelope = checkedResponse(
      await _networkService.get(ApiEndPoint.countries, skipAuthRefresh: true),
    );

    for (final country in asMapList(envelope.dataList)) {
      if (!(asBool(country['status']) ?? true)) continue;
      if (asInt(country['id']) case final id?) return id;
    }
    return null;
  }
}
