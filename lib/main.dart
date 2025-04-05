import "package:flutter/material.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:todo_project/pages/login/auth_state_listener.dart";
import "package:todo_project/pages/login/login_page.dart";
import "package:todo_project/pages/main/main_page.dart";
import "package:todo_project/pages/setting/setting_page.dart";
import "package:todo_project/util/firebase_util.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  var widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await FirebaseUtil().initFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    return AuthStateListener(
      navigatorKey: navigatorKey,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: "Flutter Demo",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/main': (context) => const MainPage(title: "Flutter Demo Home Page"),
          '/login': (context) => const LoginPage(title: "Login Page"),
          '/setting': (context) => const SettingPage(title: "Setting Page"),
        },
      )
    );
  }
}