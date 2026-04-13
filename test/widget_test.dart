import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/main.dart';

void main() {
  testWidgets('app boots into populated dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const InStockApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('InStock'), findsOneWidget);
    expect(
      find.text('Plan tonight with less kitchen guesswork.'),
      findsOneWidget,
    );
    expect(find.text('Build list'), findsOneWidget);
    expect(find.text('Get AI help'), findsOneWidget);
  });
}
