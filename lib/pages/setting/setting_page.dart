import 'package:flutter/material.dart';
import 'package:todo_project/util/firebase_util.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, required this.title});

  final String title;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Setting"),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Go to main")
            ),
            TextButton(
              onPressed: () async {
                await FirebaseUtil().signOut();

                if (FirebaseUtil().isUserLoggedIn()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to logout. Try again.")),
                  );
                }
              },
              child: const Text("Logout")
            ),
          ],
        )
      )
    );
  }
}
