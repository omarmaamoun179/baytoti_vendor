import 'package:baytoti_vendor/core/app/app.dart';
import 'package:baytoti_vendor/core/common/localization_service.dart';
import 'package:baytoti_vendor/core/di/di_exports.dart';
import 'package:baytoti_vendor/core/widgets/header_icon_button.dart';
import 'package:baytoti_vendor/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:baytoti_vendor/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:baytoti_vendor/features/orders/presentation/widgets/order_card.dart';
import 'package:baytoti_vendor/features/shell/presentation/widgets/vendor_nav_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A walk through every screen on fixtures, signing in and up the way a
/// family would, with a screenshot of each — for comparing the build with
/// the design. Run it with the driver in `test_driver/`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  var shot = 0;
  Future<void> capture(String name) async {
    final number = (++shot).toString().padLeft(2, '0');
    await binding.takeScreenshot('${number}_$name');
  }

  /// Pumps frames for [duration] — `pumpAndSettle` never settles while a
  /// spinner turns.
  Future<void> wait(WidgetTester tester, [int ms = 1200]) async {
    for (var elapsed = 0; elapsed < ms; elapsed += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder navTab(String label) => find.descendant(
        of: find.byType(VendorNavBar),
        matching: find.text(label),
      );

  Future<void> tapText(WidgetTester tester, String text) async {
    // The sign-up form runs past the fold; a tap off screen hits nothing.
    await tester.ensureVisible(find.text(text).last);
    await tester.pump();
    await tester.tap(find.text(text).last);
    await wait(tester);
  }

  /// The design's own back button — `pageBack` looks for Material's.
  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(AppBackButton).last);
    await wait(tester);
  }

  Future<void> enterCode(WidgetTester tester) async {
    for (final digit in AuthMockDataSource.demoCode.split('')) {
      await tester.tap(find.text(digit).last);
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('screen tour', (tester) async {
    // The tour signs in with the fixtures' code, which the live API refuses.
    expect(
      useMockData,
      isTrue,
      reason: 'Run the tour with --dart-define=USE_MOCK_DATA=true',
    );
    await EasyLocalization.ensureInitialized();
    await initDependencies();
    await sl<AuthCubit>().restoreSession();
    // Start signed out, in Arabic, whatever an earlier run left behind.
    if (sl<AuthCubit>().state.hasSession) await sl<AuthCubit>().logout();

    await tester.pumpWidget(LocalizationService.wrap(const App()));
    await wait(tester, 400);
    final context = tester.element(find.byType(MaterialApp));
    await context.setLocale(const Locale('ar'));
    // The splash with its name and tagline in; it moves on at 3.5 s.
    await wait(tester, 2600);
    await capture('splash');
    await wait(tester, 1400);

    // ── Sign in ──────────────────────────────────────────────────────
    await capture('sign_in');
    await tester.enterText(find.byType(TextField).last, '51502244');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await wait(tester, 400);
    await tapText(tester, 'إرسال رمز التحقق');
    await enterCode(tester);
    await wait(tester, 300);
    await capture('otp');
    await tapText(tester, 'تحقق ومتابعة');
    await wait(tester, 1500);

    // ── Tabs ─────────────────────────────────────────────────────────
    await capture('dashboard');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await wait(tester, 600);
    await capture('dashboard_scrolled');

    await tester.tap(navTab('الطلبات'));
    await wait(tester);
    await capture('orders');

    await tester.tap(find.byType(OrderCard).first);
    await wait(tester);
    await capture('order_details');
    await tapText(tester, 'قبول الطلب');
    await capture('order_accepted');
    await back(tester);

    await tester.tap(navTab('المنتجات'));
    await wait(tester);
    await capture('products');

    await tapText(tester, '+ إضافة');
    await capture('product_editor');
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await wait(tester, 600);
    await capture('product_editor_scrolled');
    await back(tester);

    await tester.tap(navTab('العروض'));
    await wait(tester);
    await capture('offers');

    await tester.tap(navTab('المتجر'));
    await wait(tester);
    await capture('store');
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await wait(tester, 600);
    await capture('store_scrolled');
    await tapText(tester, 'الموقع');
    await wait(tester, 1000);
    await capture('location');
    await back(tester);

    // ── Notifications, from the dashboard's bell ─────────────────────
    await tester.tap(navTab('الرئيسية'));
    await wait(tester);
    await tester.tap(find.byType(NotificationBell).first);
    await wait(tester);
    await capture('notifications');
    await back(tester);

    // ── English ──────────────────────────────────────────────────────
    await context.setLocale(const Locale('en'));
    await wait(tester, 1500);
    await capture('dashboard_en');
    await tester.tap(navTab('Orders'));
    await wait(tester);
    await capture('orders_en');
    await context.setLocale(const Locale('ar'));
    await wait(tester, 1500);

    // ── A new family: sign up, choose a location, then the dashboard ─
    await sl<AuthCubit>().logout();
    await wait(tester, 1500);
    await tapText(tester, 'أسرة جديدة');
    await capture('sign_up');
    // By position in the form: the account (name, email, phone, password,
    // confirmation), then the business name (5) and the store name (13);
    // the optional fields between are left blank.
    Future<void> fill(int index, String text) async {
      final field = find.byType(TextField).at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
    }

    await fill(0, 'سارة العلي');
    await fill(1, 'sara@example.com');
    await fill(2, '66001122');
    await fill(3, 'kitchen2026');
    await fill(4, 'kitchen2026');
    await fill(5, 'مطبخ سارة');
    await fill(13, 'حلويات سارة');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await wait(tester, 400);
    await tapText(tester, 'إنشاء الحساب');
    await enterCode(tester);
    await tapText(tester, 'تحقق ومتابعة');
    await wait(tester, 1500);
    await capture('new_family_location');
    await tapText(tester, 'الكويت');
    await tapText(tester, 'حولي');
    await tapText(tester, 'متابعة');
    await wait(tester, 1500);
    await capture('new_family_dashboard');
  });
}
