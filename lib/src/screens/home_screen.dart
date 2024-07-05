import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';
import 'package:yty_claim_app/src/screens/add_claim_screen.dart';
import 'package:yty_claim_app/src/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  static const routeName = '/';
  final ClaimController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    widget.controller.addListener(_updateState);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/YTY.png',
          height: 32,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send),
          ),
          IconButton(
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsScreen.routeName);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: widget.controller.claims.isEmpty
          ? const Center(child: Text('No Claims Added'))
          : ListView.builder(
              itemCount: widget.controller.claims.length,
              itemBuilder: (BuildContext context, int index) {
                ClaimItem claim = widget.controller.claims[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${claim.claimTypeName} | MYR ${claim.total.toStringAsFixed(2)}',
                    ),
                    subtitle: Flexible(
                      child: Text(
                        claim.description,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        widget.controller.removeClaim(claim);
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.restorablePushNamed(context, AddClaimScreen.routeName);
        },
        label: const Text('Add Claim'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
