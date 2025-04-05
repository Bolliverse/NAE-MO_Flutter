import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_project/firebase_options.dart';

class FirebaseUtil {

  factory FirebaseUtil() {
    return _instance;
  }
  FirebaseUtil._privateConstructor();
  static final FirebaseUtil _instance = FirebaseUtil._privateConstructor();

  late FirebaseFirestore _firestoreDB;
  bool _authListenerSet = false;

  Future<void> initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    _firestoreDB = FirebaseFirestore.instance;
  }

  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<UserCredential> signInWithGoogle() async {
    var googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception("google user is null");
    }
    var googleAuth = await googleUser.authentication;
    var credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void listenAuthStateChanges(GlobalKey<NavigatorState> navigatorKey) {
    if (_authListenerSet) return;
    _authListenerSet = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        var nav = navigatorKey.currentState;
        if (nav == null) return;

        if (user == null) {
          nav.pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          nav.pushNamedAndRemoveUntil('/main', (route) => false);
        }
      });
    });
  }
}