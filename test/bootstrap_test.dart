import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/bootstrap.dart';

void main() {
  testWidgets('boot splash renders the centered brand composition', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InStockSplashScreen()));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/brand/splash.png');
    expect(image.fit, BoxFit.contain);
    expect(find.byType(Center), findsOneWidget);
  });
}
