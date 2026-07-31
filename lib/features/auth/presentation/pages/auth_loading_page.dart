import 'package:flutter/material.dart';

class AuthLoadingPage extends StatelessWidget {
  const AuthLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: '로그인 정보 확인 중',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
