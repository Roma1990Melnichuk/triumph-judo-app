/// E2E тести для ShopHomeScreen, ShopCatalogScreen, ShopCartScreen.
/// Не suppressує overflow — overflow-помилки повинні валити тест.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/models/cart_model.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/shop/providers/cart_provider.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';
import 'package:judo_app/features/shop/screens/shop_cart_screen.dart';
import 'package:judo_app/features/shop/screens/shop_catalog_screen.dart';
import 'package:judo_app/features/shop/screens/shop_home_screen.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

ShopProduct _product(String id, String title) {
  final base = ShopProduct.defaults.first;
  return base.copyWith(
    id: id,
    title: title,
    isActive: true,
    isFeatured: true,
    imageUrls: const [],
  );
}

final _emptyCart = CartModel(userId: 'coach1');

GoRouter _router(Widget screen) => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => screen),
        GoRoute(
            path: '/shop/product/:id',
            builder: (_, __) =>
                const Scaffold(body: Text('product detail'))),
        GoRoute(
            path: '/shop/catalog',
            builder: (_, __) => const Scaffold(body: Text('catalog'))),
        GoRoute(
            path: '/shop/cart',
            builder: (_, __) => const Scaffold(body: Text('cart'))),
        GoRoute(
            path: '/shop/admin',
            builder: (_, __) => const Scaffold(body: Text('admin'))),
        GoRoute(path: '/shop', builder: (_, __) => const Scaffold(body: Text('shop'))),
      ],
    );

Widget _app(Widget screen, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: _router(screen)),
    );

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ShopHomeScreen — без overflow', () {
    testWidgets('порожній каталог — рендериться без краша', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(
        const ShopHomeScreen(),
        [
          shopProductsProvider
              .overrideWith((_) => Stream.value(const [])),
          cartStreamProvider
              .overrideWith((_) => Stream.value(_emptyCart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('з 10 featured товарами — рендериться без overflow', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final products =
          List.generate(10, (i) => _product('p$i', 'Товар $i'));

      await tester.pumpWidget(_app(
        const ShopHomeScreen(),
        [
          shopProductsProvider
              .overrideWith((_) => Stream.value(products)),
          cartStreamProvider
              .overrideWith((_) => Stream.value(_emptyCart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('лічильник кошика — відображається коректно', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cart = CartModel(
        userId: 'coach1',
        items: const [
          CartItem(
            id: 'ci1',
            productId: 'p1',
            title: 'Кімоно',
            priceSnapshot: 1500,
            quantity: 3,
          ),
        ],
      );

      await tester.pumpWidget(_app(
        const ShopHomeScreen(),
        [
          shopProductsProvider
              .overrideWith((_) => Stream.value(const [])),
          cartStreamProvider.overrideWith((_) => Stream.value(cart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('ShopCatalogScreen — без overflow', () {
    testWidgets('рендериться без краша', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final products = [
        _product('k1', 'Кімоно Тріумф'),
        _product('b1', 'Пояс синій'),
      ];

      await tester.pumpWidget(_app(
        const ShopCatalogScreen(),
        [
          shopProductsProvider
              .overrideWith((_) => Stream.value(products)),
          cartStreamProvider
              .overrideWith((_) => Stream.value(_emptyCart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('50 товарів — без overflow у списку', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final products =
          List.generate(50, (i) => _product('p$i', 'Товар $i'));

      await tester.pumpWidget(_app(
        const ShopCatalogScreen(),
        [
          shopProductsProvider
              .overrideWith((_) => Stream.value(products)),
          cartStreamProvider
              .overrideWith((_) => Stream.value(_emptyCart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────

  group('ShopCartScreen — без overflow', () {
    testWidgets('порожній кошик — рендериться без краша', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_app(
        const ShopCartScreen(),
        [
          cartStreamProvider
              .overrideWith((_) => Stream.value(_emptyCart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('кошик з 5 позиціями — без overflow', (tester) async {
      _setPhoneSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cart = CartModel(
        userId: 'coach1',
        items: List.generate(
          5,
          (i) => CartItem(
            id: 'ci$i',
            productId: 'p$i',
            title: 'Товар $i',
            priceSnapshot: 1500.0,
            quantity: 1,
          ),
        ),
      );

      await tester.pumpWidget(_app(
        const ShopCartScreen(),
        [
          cartStreamProvider.overrideWith((_) => Stream.value(cart)),
          currentUserModelProvider
              .overrideWith((_) => Stream.value(_coach)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
