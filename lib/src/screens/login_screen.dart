import 'package:flutter/material.dart';

class UserItem {
  final String username;
  final String empid;

  UserItem({required this.username, required this.empid});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

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
