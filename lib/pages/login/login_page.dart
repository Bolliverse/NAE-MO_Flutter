import 'package:flutter/material.dart';
import 'package:todo_project/util/firebase_util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseUtil().signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login"),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popAndPushNamed('/main');
              },
              child: const Text("Go to main")
            ),
            OutlinedButton(
              onPressed: _isLoading ? null : _loginWithGoogle,
              child: _isLoading
                ? const CircularProgressIndicator()
                : const Text("Login with Google"),
            )
          ],
        )
      )
    );
  }
}
