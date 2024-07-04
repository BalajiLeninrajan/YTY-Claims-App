import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/sample_feature/sample_item_list_view.dart';
import 'package:yty_claim_app/src/controllers/settings_controller.dart';

class UserItem {
  final String username;
  final String empid;

  UserItem({required this.username, required this.empid});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  static const routeName = '/login';
  final SettingsController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIDController = TextEditingController();
  final _passwordController = TextEditingController();
  List<UserItem> _users = [];
  UserItem? _selectedUser;
  bool _userIDErrorFlag = false;
  bool _loginErrorFlag = false;

  void _fetchUsers() {
    final userId = _userIDController.text;
    if (userId == '100223') {
      setState(() {
        _userIDErrorFlag = false;
        _loginErrorFlag = false;
      });
      _passwordController.clear();
      _users = [
        UserItem(username: 'Reyndo', empid: '1'),
        UserItem(username: 'Balaji', empid: '2'),
      ];
      _selectedUser = _users.first;
    } else {
      setState(() {
        _userIDErrorFlag = true;
      });
      _users = <UserItem>[];
      _selectedUser = null;
    }
  }

  void _loginUser() {
    final password = _passwordController.text;
    if (password != '1234') {
      setState(() {
        _loginErrorFlag = true;
      });
      return;
    }

    widget.controller.updateLoginFlag();
    Navigator.restorablePopAndPushNamed(context, SampleItemListView.routeName);
  }

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
                  'assets/images/YTY.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                // 6 digit id
                TextField(
                  controller: _userIDController,
                  decoration: InputDecoration(
                    labelText: '6-digit ID',
                    border: const OutlineInputBorder(),
                    errorText: _userIDErrorFlag ? 'Invalid ID' : null,
                    suffixIcon: TextButton.icon(
                      onPressed: _fetchUsers,
                      label: const Text('Fetch Users'),
                      icon: const Icon(Icons.get_app),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                if (_users.isNotEmpty) ...[
                  // Selected user
                  DropdownButtonFormField<UserItem>(
                    items: _users.map<DropdownMenuItem<UserItem>>(
                      (UserItem user) {
                        return DropdownMenuItem(
                          value: user,
                          child: Text(user.username),
                        );
                      },
                    ).toList(),
                    value: _selectedUser,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Name',
                    ),
                    onChanged: (UserItem? user) {},
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      errorText: _loginErrorFlag ? 'Invalid Password' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: _loginUser,
                        label: const Text('Login'),
                        icon: const Icon(Icons.login),
                      )
                    ],
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
