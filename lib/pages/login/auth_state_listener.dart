import 'package:flutter/material.dart';
import 'package:todo_project/util/firebase_util.dart';

class AuthStateListener extends StatefulWidget {

  const AuthStateListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<StatefulWidget> createState() => _AuthStateListenerState();
}

class _AuthStateListenerState extends State<AuthStateListener> {
  @override
  void initState() {
    super.initState();
    FirebaseUtil().listenAuthStateChanges(widget.navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}