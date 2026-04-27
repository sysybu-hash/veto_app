// File generated for VETO — replace with `flutterfire configure` + your Firebase project.
// Placeholder values allow the app to compile; FCM will not deliver until you add real config.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'replace-me',
        appId: '1:0:web:0',
        messagingSenderId: '0',
        projectId: 'veto-legal-dev',
        authDomain: 'veto-legal-dev.firebaseapp.com',
        storageBucket: 'veto-legal-dev.appspot.com',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'replace-me',
          appId: '1:0:android:0',
          messagingSenderId: '0',
          projectId: 'veto-legal-dev',
          storageBucket: 'veto-legal-dev.appspot.com',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'replace-me',
          appId: '1:0:ios:0',
          messagingSenderId: '0',
          projectId: 'veto-legal-dev',
          storageBucket: 'veto-legal-dev.appspot.com',
          iosBundleId: 'com.example.veto',
        );
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not set for this platform.');
    }
  }
}
