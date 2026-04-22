import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyDDi5R3kPOYdHEwBXvrcumg2HGsodRhtdA',
    appId: '1:632197672939:web:c957d23c4880e33ae0f3ae',
    messagingSenderId: '632197672939',
    projectId: 'summit-stories-b4293',
    authDomain: 'summit-stories-b4293.firebaseapp.com',
    storageBucket: 'summit-stories-b4293.firebasestorage.app',
    measurementId: 'G-PFZVC2G92W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCn2EE89RBEjMgDuTdB1AxyNHew7M4n0mU',
    appId: '1:632197672939:android:c041e509c9b9572ce0f3ae',
    messagingSenderId: '632197672939',
    projectId: 'summit-stories-b4293',
    storageBucket: 'summit-stories-b4293.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRrpmnvICHV8IAmspUtwEmfyJJlBEuzTY',
    appId: '1:632197672939:ios:cb52bb1816101f65e0f3ae',
    messagingSenderId: '632197672939',
    projectId: 'summit-stories-b4293',
    storageBucket: 'summit-stories-b4293.firebasestorage.app',
    iosBundleId: 'com.example.summitStories',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCRrpmnvICHV8IAmspUtwEmfyJJlBEuzTY',
    appId: '1:632197672939:ios:cb52bb1816101f65e0f3ae',
    messagingSenderId: '632197672939',
    projectId: 'summit-stories-b4293',
    storageBucket: 'summit-stories-b4293.firebasestorage.app',
    iosBundleId: 'com.example.summitStories',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDDi5R3kPOYdHEwBXvrcumg2HGsodRhtdA',
    appId: '1:632197672939:web:59c4912a23bbbb2de0f3ae',
    messagingSenderId: '632197672939',
    projectId: 'summit-stories-b4293',
    authDomain: 'summit-stories-b4293.firebaseapp.com',
    storageBucket: 'summit-stories-b4293.firebasestorage.app',
    measurementId: 'G-CW4BBLKHD3',
  );
}
