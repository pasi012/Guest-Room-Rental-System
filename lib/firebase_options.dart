// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_O9rBLz1Ug9CbYd-US_AM189UEjFUoP4',
    appId: '1:74840937020:web:1562ac854295680b046939',
    messagingSenderId: '74840937020',
    projectId: 'guest-house-rental-system',
    authDomain: 'guest-house-rental-system.firebaseapp.com',
    storageBucket: 'guest-house-rental-system.appspot.com',
    measurementId: 'G-GP2SZ2FHN5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgKISF7thqxrHUk8JiarXCUEEbyUzn8Cg',
    appId: '1:74840937020:android:c39554a368d069a1046939',
    messagingSenderId: '74840937020',
    projectId: 'guest-house-rental-system',
    storageBucket: 'guest-house-rental-system.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBUXzw2sIkabRlqFJ2tSfoVMYenelV72Zc',
    appId: '1:74840937020:ios:acbb4cf7496f0c48046939',
    messagingSenderId: '74840937020',
    projectId: 'guest-house-rental-system',
    storageBucket: 'guest-house-rental-system.appspot.com',
    iosBundleId: 'com.example.guestHouseRentalSystem',
  );
}
