import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../common/bloc_observer.dart';
import '../common/localization_service.dart';
import '../di/di_exports.dart';
import '../routing/app_router.dart';
import 'app.dart';

/// The one startup path.
///
/// Everything that must happen before the first frame happens here, in order:
/// binding → localization → timezone data → DI → session restore → runApp.
Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await EasyLocalization.ensureInitialized();

      // Loads the tz database the date utilities format with.
      tz.initializeTimeZones();

      if (kDebugMode) Bloc.observer = AppBlocObserver();

      await initDependencies();

      // Reads the stored session and resolves the notifier on every branch
      // before the first frame — the router's guard waits for it.
      await sl<AuthCubit>().restoreSession();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        developer.log(
          'Flutter error',
          name: 'bootstrap',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // Outermost, so its simulated MediaQuery reaches everything below —
      // a no-op passthrough while disabled.
      runApp(
        DevicePreview(
          enabled: false, // Set to true to check other screen sizes.
          builder: (context) => RequestsInspector(
            // Debug only: the package has no release check of its own, and
            // on it keeps request bodies — tokens, addresses — in memory.
            enabled: kDebugMode,
            // Shake or long-press.
            showInspectorOn: ShowInspectorOn.Both,
            // The request/response Stopper raises its editor dialogs on it.
            navigatorKey: rootNavigatorKey,
            child: LocalizationService.wrap(const App()),
          ),
        ),
      );

      // Nothing above `runApp` may reach the network. The inspector's
      // controller is a singleton created by whoever asks first, and when
      // that is the Dio interceptor rather than [RequestsInspector] it is
      // created disabled — every request after it is silently dropped.
      // A restored session shows the account as it was kept at sign-in;
      // `/me` brings it up to date.
      final auth = sl<AuthCubit>();
      if (auth.state.hasSession) unawaited(auth.refreshAccount());
    },
    (error, stackTrace) => developer.log(
      'Uncaught zone error',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}
