import 'package:baytoti_vendor/core/app/session_notifier.dart';
import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/features/onboarding/data/datasources/application_mock_data_source.dart';
import 'package:baytoti_vendor/features/onboarding/data/models/vendor_application_model.dart';
import 'package:baytoti_vendor/features/onboarding/data/repositories/application_repository_impl.dart';
import 'package:baytoti_vendor/features/onboarding/domain/entities/vendor_application.dart';
import 'package:baytoti_vendor/features/onboarding/domain/usecases/application_usecases.dart';
import 'package:baytoti_vendor/features/onboarding/presentation/cubit/application_cubit.dart';
import 'package:baytoti_vendor/features/onboarding/presentation/cubit/application_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  ApplicationMockDataSource source(MemoryTokenStore tokens) =>
      ApplicationMockDataSource(tokens, MockLocale(FakeCacheService()));

  group('the application fixtures', () {
    test('a family that signed in is approved', () async {
      final result = await source(MemoryTokenStore.signedIn())
          .getApplication();
      final application = result.getOrElse(() => throw 'failed');

      expect(application.isApproved, isTrue);
      expect(application.steps.every((step) => step.done), isTrue);
    });

    test('a new family starts under review, documents in', () async {
      final result = await source(
        MemoryTokenStore.signedIn(isNewFamily: true, familyName: 'مطبخ سارة'),
      ).getApplication();
      final application = result.getOrElse(() => throw 'failed');

      expect(application.status, ReviewStatus.underReview);
      expect(application.familyName, 'مطبخ سارة');
      expect([for (final s in application.steps) s.done],
          [true, true, false, false]);
    });

    test('the review moves one step at a time to approval', () async {
      final fixtures = source(MemoryTokenStore.signedIn(isNewFamily: true));

      final once = (await fixtures.advanceReview())
          .getOrElse(() => throw 'failed');
      expect(once.isApproved, isTrue);

      final again = (await fixtures.getApplication())
          .getOrElse(() => throw 'failed');
      expect(again.isApproved, isTrue, reason: 'progress lasts the run');
    });

    test('a token the fixtures did not issue is refused', () async {
      final result = await source(MemoryTokenStore()).getApplication();
      expect(result.isLeft(), isTrue);
    });
  });

  group('ApplicationCubit', () {
    late SessionNotifier session;
    late ApplicationCubit cubit;

    setUp(() {
      session = SessionNotifier();
      final repository = ApplicationRepositoryImpl(
        source(MemoryTokenStore.signedIn(isNewFamily: true)),
      );
      cubit = ApplicationCubit(
        GetApplicationUseCase(repository),
        AdvanceReviewUseCase(repository),
        session,
      );
    });

    tearDown(() => cubit.close());

    test('reads the application when a session begins', () async {
      session.signedIn();
      await cubit.stream.firstWhere(
        (state) => state.status == ApplicationStatus.loaded,
      );

      expect(cubit.state.isApproved, isFalse);
    });

    test('forgets it when the session ends', () async {
      session.signedIn();
      await cubit.stream.firstWhere(
        (state) => state.status == ApplicationStatus.loaded,
      );

      session.signedOut();
      expect(cubit.state.application, isNull);
      expect(cubit.state.status, ApplicationStatus.initial);
    });

    test('advancing approves the family and opens the gate', () async {
      session.signedIn();
      await cubit.stream.firstWhere(
        (state) => state.status == ApplicationStatus.loaded,
      );

      await cubit.advance();
      expect(cubit.state.isApproved, isTrue);
      expect(cubit.state.advancing, isFalse);
    });
  });

  group('the review on /vendor/profile', () {
    VendorApplicationModel read(Object? status) =>
        VendorApplicationModel.fromProfile({
          'business': {'name': 'أسرة أم عبدالله'},
          'status': status,
        });

    test('active and approved open the store', () {
      expect(read('active').isApproved, isTrue);
      expect(read('approved').isApproved, isTrue);
    });

    test('pending, absent and unknown hold the family at the gate', () {
      expect(read('pending').status, ReviewStatus.underReview);
      expect(read(null).status, ReviewStatus.underReview);
      expect(read('whatever').status, ReviewStatus.underReview);
    });

    test('a refusal reads as rejected', () {
      expect(read('rejected').status, ReviewStatus.rejected);
      expect(read('suspended').status, ReviewStatus.rejected);
    });

    test('the family is named from the business', () {
      expect(read('pending').familyName, 'أسرة أم عبدالله');
    });
  });
}
