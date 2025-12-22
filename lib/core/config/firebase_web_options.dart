import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Lightweight loader for Firebase web configuration via --dart-define flags.
/// Mobile platforms rely on their native config files, so we only handle web.
class FirebaseWebOptions {
  const FirebaseWebOptions._();

  static FirebaseOptions? web() {
    if (!kIsWeb) return null;

    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId =
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      authDomain: authDomain.isEmpty ? null : authDomain,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }
}
