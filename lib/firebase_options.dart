// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';

// ...
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBo5yUqwWNsghUGDaXfn7yuWNGelVZHnm4',
    appId: '1:268803480135:web:baeb2edf9e2c28ae90ef62',
    messagingSenderId: '268803480135',
    projectId: 'med4free-65f22',
    authDomain: 'med4free-65f22.firebaseapp.com',
    databaseURL: 'https://med4free-65f22-default-rtdb.firebaseio.com',
    storageBucket: 'med4free-65f22.firebasestorage.app',
    measurementId: 'G-GCEZ84TRXT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMKvXYfEzeqlYUtdCwCCC866DAwciC5xo',
    appId: '1:268803480135:android:bb620bc1103d887d90ef62',
    messagingSenderId: '268803480135',
    projectId: 'med4free-65f22',
    databaseURL: 'https://med4free-65f22-default-rtdb.firebaseio.com',
    storageBucket: 'med4free-65f22.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3zOCGeCvPZeevIMh92CWiocqVGMOIBrQ',
    appId: '1:268803480135:ios:4813f5fd4feb732590ef62',
    messagingSenderId: '268803480135',
    projectId: 'med4free-65f22',
    databaseURL: 'https://med4free-65f22-default-rtdb.firebaseio.com',
    storageBucket: 'med4free-65f22.firebasestorage.app',
    iosBundleId: 'com.example.med4free',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC3zOCGeCvPZeevIMh92CWiocqVGMOIBrQ',
    appId: '1:268803480135:ios:4813f5fd4feb732590ef62',
    messagingSenderId: '268803480135',
    projectId: 'med4free-65f22',
    databaseURL: 'https://med4free-65f22-default-rtdb.firebaseio.com',
    storageBucket: 'med4free-65f22.firebasestorage.app',
    iosBundleId: 'com.example.med4free',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBo5yUqwWNsghUGDaXfn7yuWNGelVZHnm4',
    appId: '1:268803480135:web:0cbc96d0c0ed45cd90ef62',
    messagingSenderId: '268803480135',
    projectId: 'med4free-65f22',
    authDomain: 'med4free-65f22.firebaseapp.com',
    databaseURL: 'https://med4free-65f22-default-rtdb.firebaseio.com',
    storageBucket: 'med4free-65f22.firebasestorage.app',
    measurementId: 'G-KEDBJXX4JY',
  );

}