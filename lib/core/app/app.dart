import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/di_exports.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/app_lifecycle_manager.dart';
import '../utils/screen_util_scope.dart';
import 'locale_sync.dart';

/// The root widget: the state that outlives any route, then the router.
///
/// A cubit that several screens must agree on — the signed-in family, its
/// application, the badges — is a lazy singleton provided here, never one
/// per screen.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkCubit>.value(value: sl<NetworkCubit>()),
        BlocProvider<AuthCubit>.value(value: sl<AuthCubit>()),
        BlocProvider<ApplicationCubit>.value(value: sl<ApplicationCubit>()),
        BlocProvider<OrdersBadgeCubit>.value(value: sl<OrdersBadgeCubit>()),
        BlocProvider<NotificationBadgeCubit>.value(
          value: sl<NotificationBadgeCubit>(),
        ),
      ],
      child: LocaleSync(
        cacheService: sl<CacheService>(),
        child: ScreenUtilScope(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlayStyle,
            child: AppLifecycleManager(
              // The theme's type is sized with `.sp`, which ScreenUtil can
              // only answer once [ScreenUtilScope] has built — so the app is
              // built beneath it, never in this method.
              child: Builder(
                builder: (context) => MaterialApp.router(
                  // The task switcher's label, in the app's language.
                  onGenerateTitle: (context) => 'app_name'.tr(),
                  debugShowCheckedModeBanner: false,
                  // The design is light only.
                  theme: AppTheme.light,
                  themeMode: ThemeMode.light,
                  routerConfig: appRouter,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  // Re-translates every screen once a new language loads,
                  // and applies device_preview's simulated device (a
                  // passthrough unless it is running).
                  builder: (context, child) => LocaleRefresh(
                    child: DevicePreview.appBuilder(context, child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
