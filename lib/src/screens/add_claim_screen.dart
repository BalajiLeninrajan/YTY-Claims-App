import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';

class AddClaimScreen extends StatefulWidget {
  const AddClaimScreen({super.key, required this.controller});

  static const routeName = '/add';
  final ClaimController controller;

  @override
  State<AddClaimScreen> createState() => _AddClaimScreenState();
}

class ClaimType {
  final String code;
  final String name;

  ClaimType({required this.code, required this.name});
}

class _AddClaimScreenState extends State<AddClaimScreen> {
  DateTime? _selectedDate;
  bool _dateErrorFlag = false;

  final TextEditingController _descriptionController = TextEditingController();

  void _selectDate(BuildContext context) async {
    setState(() {
      _dateErrorFlag = false;
    });
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (newDate != null && newDate != _selectedDate) {
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Claim')),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 768,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: <Widget>[
                // Claim type
                // Date
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  label: Text(
                    _selectedDate == null
                        ? (_dateErrorFlag ? 'Date Required' : 'Bill Date')
                        : '${_selectedDate?.toString().substring(0, 10)}',
                  ),
                  icon: const Icon(Icons.date_range),
                  style: _dateErrorFlag
                      ? TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          iconColor: Colors.red,
                        )
                      : null,
                ),
                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                )
                // Currency and exchange rate
                // bill ammount
                // tax ammount
                // total and attachment
              ],
            ),
          ),
        ),
      ),
    );
  }
}
