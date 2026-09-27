import 'package:baytoti_vendor/core/domain/failure.dart';
import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/features/dashboard/data/datasources/dashboard_mock_data_source.dart';
import 'package:baytoti_vendor/features/orders/data/datasources/order_fixtures.dart';
import 'package:baytoti_vendor/features/orders/data/datasources/orders_mock_data_source.dart';
import 'package:baytoti_vendor/features/orders/data/models/order_models.dart';
import 'package:baytoti_vendor/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:baytoti_vendor/features/orders/domain/entities/order_status.dart';
import 'package:baytoti_vendor/features/orders/domain/usecases/orders_usecases.dart';
import 'package:baytoti_vendor/features/orders/presentation/cubit/order_details_cubit.dart';
import 'package:baytoti_vendor/features/orders/presentation/cubit/order_details_state.dart';
import 'package:baytoti_vendor/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:baytoti_vendor/features/orders/presentation/cubit/orders_state.dart';
import 'package:baytoti_vendor/features/products/data/datasources/product_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late OrderFixtures fixtures;
  late OrdersMockDataSource source;
  late OrdersRepositoryImpl repository;

  setUp(() {
    fixtures = OrderFixtures();
    source = OrdersMockDataSource(fixtures, MockLocale(FakeCacheService()));
    repository = OrdersRepositoryImpl(source);
  });

  group('the order fixtures', () {
    test('every tab is counted, and the counts add up', () async {
      final list = (await source.getOrders(OrderTab.all, 1))
          .getOrElse(() => throw 'failed');
      final counts = list.counts;

      expect(counts.all, fixtures.orders.length);
      expect(counts.fresh, 2);
      expect(counts.fresh + counts.preparing + counts.done, counts.all);
    });

    test('the "new" tab holds only orders waiting on the family', () async {
      final list = (await source.getOrders(OrderTab.fresh, 1))
          .getOrElse(() => throw 'failed');

      expect(list.page.items, isNotEmpty);
      expect(
        list.page.items.every((order) => order.status == OrderStatus.placed),
        isTrue,
      );
    });

    test('an order moves only to its next status', () async {
      final skip = await source.advance('ord_2041', OrderStatus.ready);
      expect(
        skip.fold((f) => f.message, (_) => null),
        'order_transition_invalid',
      );

      final order = (await source.advance('ord_2041', OrderStatus.accepted))
          .getOrElse(() => throw 'failed');
      expect(order.status, OrderStatus.accepted);
      expect(order.nextStatus, OrderStatus.preparing);
      expect(order.canReject, isFalse);
    });

    test('an accepted order cannot be rejected', () async {
      final result = await source.reject('ord_2039', RejectReason.tooBusy);
      expect(
        result.fold((f) => f.message, (_) => null),
        'order_reject_not_allowed',
      );
    });

    test('a missing order is a 404, renamed', () async {
      final result = await source.getOrder('ord_1');
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure?.message, 'order_not_found');
    });

    test('the dashboard counts the same new orders', () async {
      final dashboard = DashboardMockDataSource(
        fixtures,
        ProductFixtures(),
        MockLocale(FakeCacheService()),
      );

      int newOrders() => fixtures.orders
          .where((order) => order.status == OrderStatus.placed)
          .length;

      final before = (await dashboard.getDashboard())
          .getOrElse(() => throw 'failed');
      expect(before.kpis.newOrders, newOrders());
      expect(before.kpis.lowStockCount, 3);
      expect(before.week, hasLength(7));

      await source.advance('ord_2041', OrderStatus.accepted);
      final after = (await dashboard.getDashboard())
          .getOrElse(() => throw 'failed');
      expect(after.kpis.newOrders, before.kpis.newOrders - 1);
    });
  });

  group('OrdersCubit', () {
    test('reads a tab and pages through "all"', () async {
      final cubit = OrdersCubit(GetOrdersUseCase(repository));
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, OrdersStatus.loaded);
      expect(cubit.state.orders, hasLength(10));
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.orders, hasLength(fixtures.orders.length));
      expect(cubit.state.hasMore, isFalse);

      // Past the last page there is nothing to ask for.
      await cubit.loadMore();
      expect(cubit.state.orders, hasLength(fixtures.orders.length));
    });

    test('switching tab replaces the list', () async {
      final cubit = OrdersCubit(GetOrdersUseCase(repository));
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.selectTab(OrderTab.done);

      expect(cubit.state.tab, OrderTab.done);
      expect(
        cubit.state.orders.every((order) => order.status.isClosed),
        isTrue,
      );
    });

    test('a tab switched mid-read drops the older answer', () async {
      final cubit = OrdersCubit(GetOrdersUseCase(repository));
      addTearDown(cubit.close);

      final first = cubit.load(tab: OrderTab.all);
      final second = cubit.load(tab: OrderTab.fresh);
      await Future.wait([first, second]);

      expect(cubit.state.tab, OrderTab.fresh);
      expect(
        cubit.state.orders.every((o) => o.status == OrderStatus.placed),
        isTrue,
      );
    });
  });

  group('OrderDetailsCubit', () {
    OrderDetailsCubit build() => OrderDetailsCubit(
          GetOrderUseCase(repository),
          AdvanceOrderUseCase(repository),
          RejectOrderUseCase(repository),
        );

    test('the one button walks an order to delivered', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('ord_2041');

      for (final expected in [
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.delivered,
      ]) {
        await cubit.advance();
        expect(cubit.state.order?.status, expected);
        expect(cubit.state.movedTo, expected);
      }

      expect(cubit.state.order?.nextStatus, isNull);
      expect(cubit.state.changed, isTrue);
    });

    test('rejecting a new order closes it', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('ord_2040');

      await cubit.reject(RejectReason.outOfStock);

      expect(cubit.state.order?.status, OrderStatus.rejected);
      expect(cubit.state.order?.canReject, isFalse);
      expect(cubit.state.actionStatus, OrderActionStatus.succeeded);
    });

    test('a missing order is an error screen', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('ord_1');

      expect(cubit.state.status, OrderDetailsStatus.error);
      expect(cubit.state.errorMessage, 'order_not_found');
    });
  });

  group('the live API\'s orders', () {
    final resource = {
      'id': 12,
      'order_number': 'ORD-2026-1258',
      'status': 'pending',
      'financials': {'subtotal': '8.500', 'total': '9.250'},
      'address': {
        'recipient_name': 'نورة العنزي',
        'phone': '96551502244',
        'area': 'حولي',
        'street': 'شارع تونس',
      },
      'items_count': 2,
      'items': [
        {'product_id': 3, 'product_name': 'كيك', 'quantity': 2, 'total': '8.500'},
      ],
      'created_at': '2026-09-21T14:10:00.000000Z',
    };

    test('a row reads its reference, customer and total', () {
      final row = VendorOrderSummaryModel.fromApi(resource);

      expect(row.id, '12');
      expect(row.reference, 'ORD-2026-1258');
      expect(row.status, OrderStatus.placed);
      expect(row.customerName, 'نورة العنزي');
      expect(row.totalFils, 9250);
      expect(row.itemCount, 2);
    });

    test('an order offers the next step, and only a new one is refused', () {
      final order = VendorOrderModel.fromApi(resource);

      expect(order.nextStatus, OrderStatus.accepted);
      expect(order.canReject, isTrue);
      expect(order.customer.phoneMasked, '•••• 2244');
      expect(order.lines.single.lineTotalFils, 8500);

      final shipped = VendorOrderModel.fromApi({...resource, 'status': 'shipped'});
      expect(shipped.status, OrderStatus.outForDelivery);
      expect(shipped.nextStatus, OrderStatus.delivered);
      expect(shipped.canReject, isFalse);

      final delivered =
          VendorOrderModel.fromApi({...resource, 'status': 'delivered'});
      expect(delivered.nextStatus, isNull);
    });

    test('every status goes back as the API spells it', () {
      for (final wire in [
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
      ]) {
        expect(orderStatusToApi(orderStatusFromApi(wire)), wire);
      }
      expect(orderStatusToApi(OrderStatus.rejected), 'cancelled');
      expect(orderStatusFromApi('refunded'), OrderStatus.unknown);
    });

    test('the counts come from the newest page and add up', () {
      final rows = [
        for (final status in ['pending', 'pending', 'processing', 'delivered'])
          VendorOrderSummaryModel.fromApi({...resource, 'status': status}),
      ];
      final counts = OrderListModel.countsFromApi(rows, total: 30);

      expect(counts.fresh, 2);
      expect(counts.preparing, 1);
      expect(counts.done, 27);
      expect(counts.all, 30);
    });
  });
}
