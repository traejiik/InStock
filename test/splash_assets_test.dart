import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

({int width, int height}) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final header = bytes.take(8).toList();

  expect(header, equals([137, 80, 78, 71, 13, 10, 26, 10]));

  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  return (width: data.getUint32(16), height: data.getUint32(20));
}

void main() {
  const appSplash = 'assets/brand/splash.png';
  const android12Splash = 'assets/brand/android12_splash.png';

  test('brand splash composition is available for native launch screens', () {
    expect(_pngSize(appSplash), equals((width: 500, height: 671)));
    expect(_pngSize(android12Splash), equals((width: 1152, height: 1152)));
  });

  test('Android launch background centers the brand composition', () {
    final launchBackground = File(
      'android/app/src/main/res/drawable/launch_background.xml',
    ).readAsStringSync();
    final launchBackgroundV21 = File(
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    ).readAsStringSync();

    for (final xml in [launchBackground, launchBackgroundV21]) {
      expect(xml, contains('@drawable/background'));
      expect(xml, contains('android:gravity="fill"'));
      expect(xml, contains('@drawable/splash'));
      expect(xml, contains('android:gravity="center"'));
    }

    expect(
      _pngSize('android/app/src/main/res/drawable/background.png'),
      equals((width: 1, height: 1)),
    );
    expect(
      _pngSize('android/app/src/main/res/drawable-v21/background.png'),
      equals((width: 1, height: 1)),
    );
    expect(
      _pngSize('android/app/src/main/res/drawable-xxxhdpi/splash.png'),
      equals((width: 500, height: 671)),
    );
  });

  test('Android 12 uses a padded composition as the splash icon', () {
    final styles = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    final nightStyles = File(
      'android/app/src/main/res/values-night-v31/styles.xml',
    ).readAsStringSync();

    for (final xml in [styles, nightStyles]) {
      expect(xml, contains('android:windowSplashScreenBackground">#111214'));
      expect(
        xml,
        contains(
          'android:windowSplashScreenAnimatedIcon">@drawable/android12splash',
        ),
      );
      expect(
        xml,
        isNot(contains('android:windowSplashScreenIconBackgroundColor')),
      );
    }

    expect(
      _pngSize('android/app/src/main/res/drawable-xxxhdpi/android12splash.png'),
      equals((width: 1152, height: 1152)),
    );
  });

  test(
    'Android handoff theme keeps the composition visible until Flutter draws',
    () {
      const stylePaths = [
        'android/app/src/main/res/values/styles.xml',
        'android/app/src/main/res/values-night/styles.xml',
        'android/app/src/main/res/values-v31/styles.xml',
        'android/app/src/main/res/values-night-v31/styles.xml',
      ];

      for (final path in stylePaths) {
        final styles = File(path).readAsStringSync();
        expect(styles, contains('<style name="NormalTheme"'));
        expect(styles, contains('android:windowBackground">'));
        expect(styles, contains('@drawable/launch_background'));
      }
    },
  );

  test('iOS launch screen centers the brand composition', () {
    final storyboard = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();

    expect(storyboard, contains('contentMode="center"'));
    expect(storyboard, contains('image="LaunchBackground"'));
    expect(
      _pngSize(
        'ios/Runner/Assets.xcassets/LaunchBackground.imageset/'
        'background.png',
      ),
      equals((width: 1, height: 1)),
    );
    expect(
      _pngSize(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/'
        'LaunchImage@3x.png',
      ),
      equals((width: 375, height: 503)),
    );
  });
}
