import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/main.dart';

/// Minimal in-memory loader to avoid depending on asset files during widget tests.
class _EmptyAssetLoader extends AssetLoader {
  const _EmptyAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds inside localization + provider scope', (tester) async {
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [
            Locale('ru'),
            Locale('en'),
            Locale('kk'),
            Locale('zh'),
          ],
          path: 'assets/translations',
          fallbackLocale: const Locale('ru'),
          assetLoader: const _EmptyAssetLoader(),
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('app_title')),
            ),
          ),
        ),
      ),
    );

    // Pump a couple of frames to let localization delegates initialize.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('app_title'), findsOneWidget);
  });
}
