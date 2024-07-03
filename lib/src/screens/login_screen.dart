import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIDController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loginErrorFlag = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: 768,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/image/YTY.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _userIDController,
                  decoration: InputDecoration(
                    labelText: '6-digit ID',
                    border: const OutlineInputBorder(),
                    errorText: _loginErrorFlag ? 'Invalid ID' : null,
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.get_app),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
