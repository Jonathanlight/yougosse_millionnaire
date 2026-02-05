// Firebase configuration for Yougosse Millionaire
// Generated from google-services.json and GoogleService-Info.plist

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhuRHbfvf9PXPBnoknsww9UKYLSswGmns',
    appId: '1:558527837591:android:a8aa043199221bd32740d2',
    messagingSenderId: '558527837591',
    projectId: 'yougosse-millionaire',
    storageBucket: 'yougosse-millionaire.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAH6xK2p9AhH3Jd_ksS4jGSqJtzr6mUdcg',
    appId: '1:558527837591:ios:ac1d37e6a31b00f62740d2',
    messagingSenderId: '558527837591',
    projectId: 'yougosse-millionaire',
    storageBucket: 'yougosse-millionaire.firebasestorage.app',
    iosBundleId: 'com.yougossemillionaire.yougossemillionaire',
  );
}
