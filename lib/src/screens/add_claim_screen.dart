import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';

class AddClaimScreen extends StatefulWidget {
  const AddClaimScreen({super.key, required this.controller});

  static const routeName = '/add';
  final ClaimController controller;

  @override
  State<AddClaimScreen> createState() => _AddClaimScreenState();
}

class _AddClaimScreenState extends State<AddClaimScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Claim')),
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[],
          ),
        ),
      ),
    );
  }
}
