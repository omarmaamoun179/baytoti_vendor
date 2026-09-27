import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every translation key an error can end up carrying.
///
/// `Failure.message` goes straight into a toast, and `easy_localization`
/// answers a key it does not know with the key itself — so a missing entry
/// here is not a crash but a family reading `order_not_found`.
///
/// Sources: the defaults on `AppException`'s subclasses, the substitutions
/// `mapExceptionToFailure` makes, the `fallbackMessage` each data source
/// passes, and the sentinels the fixtures throw the way the server would.
/// Add a feature's keys here when it lands.
const List<String> errorMessageKeys = [
  // Network layer and mapper
  'session_expired',
  'cache_error',
  'request_failed',
  'connection_failed',
  'server_error',
  'unexpected_error',
  'request_cancelled',
  'security_certificate_error',
  // Auth
  'otp_send_failed',
  'otp_verify_failed',
  'otp_invalid',
  'otp_expired',
  'account_refresh_failed',
  'session_save_failed',
  'session_clear_failed',
  'signup_failed',
  'signup_code_failed',
  'phone_taken',
  'auth_token_missing',
  // Onboarding
  'application_failed',
  // Uploads
  'upload_failed',
  'image_too_large',
  'photo_pick_failed',
  // Dashboard
  'dashboard_failed',
  // Orders
  'orders_failed',
  'order_failed',
  'order_not_found',
  'order_status_failed',
  'order_reject_failed',
  'order_transition_invalid',
  'order_reject_not_allowed',
  // Products
  'products_failed',
  'product_failed',
  'product_not_found',
  'categories_failed',
  'product_save_failed',
  'product_visibility_failed',
  'product_pending_review',
  'product_rejected_cannot_publish',
  'product_out_of_stock_publish',
  'product_photos_uploading',
  'product_photos_failed',
  'product_photo_required',
  'product_review_not_sent',
  'product_images_too_large',
  // Offers
  'offers_failed',
  'offer_create_failed',
  'offer_delete_failed',
  'offer_not_found',
  'offer_percent_invalid',
  'offer_limit_reached',
  'offer_end_past',
  // Store
  'store_failed',
  'store_save_failed',
  'store_missing',
  'store_cover_uploading',
  'store_cover_failed',
  // Notifications
  'notifications_failed',
];

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

/// Every text a key resolves to — one, or each plural form.
Iterable<String> _texts(Object? value) => switch (value) {
      final String text => [text],
      final Map<String, dynamic> forms => forms.values.cast<String>(),
      _ => const [],
    };

void main() {
  final en = _load('en');
  final ar = _load('ar');

  group('error messages are translated', () {
    for (final key in errorMessageKeys) {
      test('$key exists in both locales and is not its own slug', () {
        expect(en, contains(key), reason: 'missing from en.json');
        expect(ar, contains(key), reason: 'missing from ar.json');
        expect(en[key], isNot(key));
        expect(ar[key], isNot(key));
      });
    }
  });

  group('the locales agree', () {
    test('every en key has an ar counterpart, and the reverse', () {
      expect(ar.keys.toSet(), en.keys.toSet());
    });

    test('no value is left empty', () {
      final blank = [
        for (final entry in {...en, ...ar}.entries)
          if (_texts(entry.value).isEmpty ||
              _texts(entry.value).any((text) => text.trim().isEmpty))
            entry.key,
      ];

      expect(blank, isEmpty);
    });

    test('a plural key is plural in both, with an "other" form', () {
      for (final key in en.keys) {
        final isPlural = en[key] is Map || ar[key] is Map;
        if (!isPlural) continue;

        expect(en[key], isA<Map>(), reason: '$key is plural only in ar');
        expect(ar[key], isA<Map>(), reason: '$key is plural only in en');
        expect(en[key], contains('other'), reason: '$key has no en "other"');
        expect(ar[key], contains('other'), reason: '$key has no ar "other"');
      }
    });

    test('a placeholder in one language is in the other', () {
      int placeholders(Object? value) =>
          _texts(value).map((t) => '{}'.allMatches(t).length).fold(0, _max);

      for (final key in en.keys) {
        expect(
          placeholders(ar[key]),
          placeholders(en[key]),
          reason: '$key takes a different number of arguments per language',
        );
      }
    });
  });
}

int _max(int a, int b) => a > b ? a : b;
