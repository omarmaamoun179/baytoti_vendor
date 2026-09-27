import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/mock/mock_session_token.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../models/vendor_application_model.dart';
import 'application_data_source.dart';

/// The application on fixtures.
///
/// Who is asking comes from the token, as it would on the server
/// ([MockSessionToken]): a family that signed in is approved, one that just
/// signed up starts under review with its account created and its documents
/// in review — the design's opening state. [advanceReview] ticks the next
/// step, the way the design's "Simulate approval" does. Progress lasts the
/// run; a relaunch starts the review over.
class ApplicationMockDataSource implements ApplicationDataSource {
  static const List<(String, Localized)> _steps = [
    ('account_created', Localized('إنشاء الحساب', 'Account created')),
    ('documents_review', Localized('مراجعة المستندات', 'Documents review')),
    ('approved', Localized('اعتماد الأسرة', 'Family approved')),
    ('first_product', Localized('أول منتج منشور', 'First product live')),
  ];

  /// The index of the step that makes an application approved.
  static const int _approvedStep = 2;

  static const Localized _sla =
      Localized('من يوم إلى ثلاثة أيام عمل', 'one to three working days');

  final TokenStore _tokenStore;
  final MockLocale _locale;

  /// Steps done so far, by account (the token's phone).
  final Map<String, int> _progress = {};

  ApplicationMockDataSource(this._tokenStore, this._locale);

  @override
  Future<Either<Failure, VendorApplicationModel>> getApplication() =>
      guardedRequest(
        'ApplicationMockDataSource.getApplication',
        () async {
          await Future<void>.delayed(mockLatency);
          final account = await _account();
          return _answer(account, _doneThrough(account));
        },
        fallbackMessage: 'application_failed',
      );

  @override
  Future<Either<Failure, VendorApplicationModel>> advanceReview() =>
      guardedRequest(
        'ApplicationMockDataSource.advanceReview',
        () async {
          await Future<void>.delayed(mockLatency);
          final account = await _account();

          final next = (_doneThrough(account) + 1).clamp(0, _approvedStep);
          _progress[account.phoneDigits] = next;
          return _answer(account, next);
        },
        fallbackMessage: 'application_failed',
      );

  Future<MockSessionToken> _account() async {
    final token = MockSessionToken.decode(
      (await _tokenStore.read())?.accessToken,
    );
    // What the server says to a token it did not issue.
    if (token == null) throw const SessionExpiredException();
    return token;
  }

  /// The last step done: a returning family has them all, a new one has
  /// its account created and its documents sent.
  int _doneThrough(MockSessionToken account) =>
      _progress[account.phoneDigits] ??
      (account.isNewFamily ? 1 : _steps.length - 1);

  Future<VendorApplicationModel> _answer(
    MockSessionToken account,
    int doneThrough,
  ) async {
    final ar = await _locale.isArabic();

    return VendorApplicationModel.fromJson({
      'state': doneThrough >= _approvedStep ? 'approved' : 'under_review',
      'family_name': account.familyName,
      'steps': [
        for (var i = 0; i < _steps.length; i++)
          {
            'key': _steps[i].$1,
            'label': _steps[i].$2.pick(ar),
            'done': i <= doneThrough,
          },
      ],
      'review_sla_display': _sla.pick(ar),
    });
  }
}
