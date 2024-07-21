import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yty_claim_app/bearer_token.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';

import 'package:yty_claim_app/src/controllers/settings_controller.dart';
import 'package:yty_claim_app/src/screens/home_screen.dart';

class UserItem {
  final String username;
  final String empid;

  UserItem({required this.username, required this.empid});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.claimController,
  });

  static const routeName = '/login';
  final SettingsController controller;
  final ClaimController claimController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePasswordText = true;
  List<UserItem> _users = [];
  UserItem? _selectedUser;
  bool _userIDErrorFlag = false;
  bool _loginErrorFlag = false;
  bool _isLoading = false;

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    final String userId = _userIDController.text;
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/getEmployee.php'),
      headers: {
        'Authorization': bearerToken,
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'USERID': userId}),
    );

    _passwordController.clear();
    setState(() {
      _loginErrorFlag = false;
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _users = responseData[0]['data']
            .map<UserItem>(
              (dynamic user) => UserItem(
                username: user['EMPLOYEE_NAME'],
                empid: user['EMP_ID'],
              ),
            )
            .toList();
      });

      if (_users.isEmpty) {
        setState(() {
          _userIDErrorFlag = true;
          _selectedUser = null;
        });
      } else {
        setState(() {
          _selectedUser = _users.first;
          _userIDErrorFlag = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch users'),
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _loginErrorFlag = false;
    });

    final String password = _passwordController.text;
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/signIn.php'),
      headers: {
        'Authorization': bearerToken,
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'FULLID': _selectedUser!.empid, 'PASSWORD': password}),
    );

    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)[0]['message'];
      if (message == 'OK') {
        widget.claimController.loadClaimTypesFromAPI(
          jsonDecode(response.body)[0]['data']['CLAIM_GROUP'],
        );
        if (!mounted) return;
        widget.controller.updateLoginFlag(_selectedUser!.empid);
        Navigator.popAndPushNamed(context, HomeScreen.routeName);
      } else {
        setState(() {
          _loginErrorFlag = true;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to server'),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 768,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
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
                          onChanged: (UserItem? user) {
                            setState(() {
                              _selectedUser = user;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePasswordText,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              errorText:
                                  _loginErrorFlag ? 'Invalid Password' : null,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePasswordText =
                                        !_obscurePasswordText;
                                  });
                                },
                                icon: Icon(
                                  _obscurePasswordText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              )),
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
            if (_isLoading)
              Container(
                color: Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
                child: const Center(
                  child: RefreshProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
