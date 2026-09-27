part of 'di_exports.dart';

/// True while the app runs on fixtures instead of a live API.
///
/// Every feature has only its fixture source today — no server implements
/// the API contract yet — so this decides nothing but what the onboarding
/// button says. When a feature gains a remote source, register it beside
/// the mock and choose between them here:
///
/// ```dart
/// sl.registerLazySingleton<OrdersDataSource>(
///   () => useMockData
///       ? OrdersMockDataSource(sl(), sl())
///       : OrdersRemoteDataSource(sl<NetworkService>()),
/// );
/// ```
///
/// Flip it with `--dart-define=USE_MOCK_DATA=false`.
const bool useMockData = bool.fromEnvironment(
  'USE_MOCK_DATA',
  defaultValue: true,
);

/// Wires up everything the app needs. Called once from `bootstrap()` before
/// `runApp`.
///
/// Registration style, applied consistently:
///   * `registerSingleton`     — core services created eagerly at startup
///   * `registerLazySingleton` — data sources, repositories, use cases,
///                               app-wide cubits
///   * `registerFactory`       — one cubit per screen
///
/// Data sources are lazy singletons because a fixture source holds the fake
/// backend's state for the run — an accepted order, a new product — and a
/// second instance would forget it.
Future<void> initDependencies() async {
  await _registerAppInfo();
  await _registerStorage();
  _registerNetwork();
  _registerAppState();
  _registerFixtures();
  _registerAuthFeature();
  _registerOnboardingFeature();
  _registerUploadsFeature();
  _registerOrdersFeature();
  _registerProductsFeature();
  _registerDashboardFeature();
  _registerOffersFeature();
  _registerStoreFeature();
  _registerNotificationsFeature();
}

Future<void> _registerAppInfo() async {
  final appInfoService = AppInfoServiceImpl();
  sl.registerSingleton<AppInfoServiceImpl>(appInfoService);
  sl.registerSingleton<AppInfo>(await appInfoService.init());
  sl.registerSingleton<LauncherService>(LauncherServiceImpl());
}

Future<void> _registerStorage() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  sl.registerSingleton<SecureStorageService>(
    SecureStorageServiceImpl(
      sl<FlutterSecureStorage>(),
      sl<SharedPreferences>(),
    ),
  );
  sl.registerSingleton<SharedPrefService>(
    SharedPrefServiceImpl(sl<SharedPreferences>()),
  );

  // iOS keeps Keychain entries across an uninstall; wipe them the first time
  // a fresh install runs so a reinstall never resumes someone else's session.
  await sl<SecureStorageService>().clearOnReinstall();

  sl.registerSingleton<CacheService>(
    CacheServiceImpl(sl<SharedPrefService>(), sl<SecureStorageService>()),
  );
  sl.registerSingleton<TokenStore>(
    SecureTokenStore(sl<SecureStorageService>()),
  );
}

/// Ready for the remote sources to come: none calls it yet.
void _registerNetwork() {
  sl.registerSingleton<InternetConnection>(InternetConnection());
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl<InternetConnection>()));
  sl.registerSingleton<NetworkCubit>(NetworkCubit(sl<NetworkInfo>()));

  sl.registerSingleton<NetworkServiceUtil>(
    NetworkServiceUtilImpl(sl<CacheService>(), sl<TokenStore>(), sl<AppInfo>()),
  );
  sl.registerSingleton<NetworkService>(
    NetworkServiceImpl(
      sl<NetworkServiceUtil>(),
      // A refused token ends the session. The cubit forgets the rest of it and
      // tells the notifier, which sends the router back to sign-in.
      onSessionExpired: () => sl<AuthCubit>().sessionExpired(),
    ),
  );
}

void _registerAppState() {
  sl.registerSingleton<SessionNotifier>(SessionNotifier());
}

/// The fake backend: the language it answers in, and the tables more than
/// one fixture source reads — the dashboard counts the same orders and
/// products the other tabs show.
void _registerFixtures() {
  sl.registerLazySingleton(() => MockLocale(sl<CacheService>()));
  sl.registerLazySingleton(() => OrderFixtures());
  sl.registerLazySingleton(() => ProductFixtures());
}

void _registerAuthFeature() {
  sl.registerLazySingleton<AuthDataSource>(
    () => useMockData
        ? AuthMockDataSource(sl<TokenStore>(), sl<MockLocale>())
        : AuthRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<TokenStore>(), sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthDataSource>(),
      sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => RequestOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResendOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RestoreSessionUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RefreshAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ClearSessionUseCase(sl<AuthRepository>()));

  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      sl<RequestOtpUseCase>(),
      sl<ResendOtpUseCase>(),
      sl<VerifyOtpUseCase>(),
      sl<RestoreSessionUseCase>(),
      sl<RefreshAccountUseCase>(),
      sl<LogoutUseCase>(),
      sl<ClearSessionUseCase>(),
      sl<SessionNotifier>(),
    ),
  );
}

void _registerOnboardingFeature() {
  sl.registerLazySingleton<ApplicationDataSource>(
    () => useMockData
        ? ApplicationMockDataSource(sl<TokenStore>(), sl<MockLocale>())
        : ApplicationRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ApplicationRepository>(
    () => ApplicationRepositoryImpl(sl<ApplicationDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetApplicationUseCase(sl<ApplicationRepository>()),
  );
  sl.registerLazySingleton(
    () => AdvanceReviewUseCase(sl<ApplicationRepository>()),
  );

  sl.registerLazySingleton<ApplicationCubit>(
    () => ApplicationCubit(sl(), sl(), sl<SessionNotifier>()),
  );
}

void _registerUploadsFeature() {
  sl.registerLazySingleton<UploadsDataSource>(() => UploadsMockDataSource());
  sl.registerLazySingleton<UploadsRepository>(
    () => UploadsRepositoryImpl(sl<UploadsDataSource>()),
  );
  sl.registerLazySingleton(() => UploadImageUseCase(sl<UploadsRepository>()));
}

void _registerOrdersFeature() {
  sl.registerLazySingleton<OrdersDataSource>(
    () => OrdersMockDataSource(sl<OrderFixtures>(), sl<MockLocale>()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(sl<OrdersDataSource>()),
  );

  sl.registerLazySingleton(() => GetOrdersUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => GetOrderUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => AdvanceOrderUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => RejectOrderUseCase(sl<OrdersRepository>()));

  sl.registerFactory(() => OrdersCubit(sl()));
  sl.registerFactory(() => OrderDetailsCubit(sl(), sl(), sl()));
  sl.registerLazySingleton<OrdersBadgeCubit>(
    () => OrdersBadgeCubit(sl<SessionNotifier>()),
  );
}

void _registerProductsFeature() {
  sl.registerLazySingleton<ProductsDataSource>(
    () => ProductsMockDataSource(sl<ProductFixtures>(), sl<MockLocale>()),
  );
  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(sl<ProductsDataSource>()),
  );

  sl.registerLazySingleton(() => GetProductsUseCase(sl<ProductsRepository>()));
  sl.registerLazySingleton(() => GetProductUseCase(sl<ProductsRepository>()));
  sl.registerLazySingleton(
    () => GetCategoriesUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton(() => SaveProductUseCase(sl<ProductsRepository>()));
  sl.registerLazySingleton(
    () => SetProductVisibilityUseCase(sl<ProductsRepository>()),
  );

  sl.registerFactory(() => ProductsCubit(sl(), sl()));
  sl.registerFactory(() => ProductEditorCubit(sl(), sl(), sl(), sl()));
}

void _registerDashboardFeature() {
  sl.registerLazySingleton<DashboardDataSource>(
    () => DashboardMockDataSource(
      sl<OrderFixtures>(),
      sl<ProductFixtures>(),
      sl<MockLocale>(),
    ),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl<DashboardDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetDashboardUseCase(sl<DashboardRepository>()),
  );

  sl.registerFactory(() => DashboardCubit(sl()));
}

void _registerOffersFeature() {
  sl.registerLazySingleton<OffersDataSource>(
    () => OffersMockDataSource(sl<MockLocale>()),
  );
  sl.registerLazySingleton<OffersRepository>(
    () => OffersRepositoryImpl(sl<OffersDataSource>()),
  );

  sl.registerLazySingleton(() => GetOffersUseCase(sl<OffersRepository>()));
  sl.registerLazySingleton(() => CreateOfferUseCase(sl<OffersRepository>()));
  sl.registerLazySingleton(() => DeleteOfferUseCase(sl<OffersRepository>()));

  sl.registerFactory(() => OffersCubit(sl(), sl(), sl()));
}

void _registerStoreFeature() {
  // The store the live products source works in, too.
  sl.registerLazySingleton(
    () => VendorStoreResolver(sl<NetworkService>(), sl<SessionNotifier>()),
  );
  sl.registerLazySingleton<StoreDataSource>(
    () => useMockData
        ? StoreMockDataSource(sl<TokenStore>(), sl<MockLocale>())
        : StoreRemoteDataSource(
            sl<NetworkService>(),
            sl<VendorStoreResolver>(),
          ),
  );
  sl.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(sl<StoreDataSource>()),
  );

  sl.registerLazySingleton(() => GetStoreUseCase(sl<StoreRepository>()));
  sl.registerLazySingleton(() => UpdateStoreUseCase(sl<StoreRepository>()));

  sl.registerFactory(() => StoreCubit(sl(), sl(), sl()));
}

void _registerNotificationsFeature() {
  sl.registerLazySingleton<NotificationsDataSource>(
    () => NotificationsMockDataSource(sl<MockLocale>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl<NotificationsDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetNotificationsUseCase(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkAllNotificationsReadUseCase(sl<NotificationsRepository>()),
  );

  sl.registerFactory(() => NotificationsCubit(sl(), sl()));
  sl.registerLazySingleton<NotificationBadgeCubit>(
    () => NotificationBadgeCubit(sl(), sl<SessionNotifier>()),
  );
}

/// Tears the locator down — used by tests and by any "sign out and start
/// clean" path that needs a fresh object graph.
Future<void> resetDependencies() => sl.reset();
