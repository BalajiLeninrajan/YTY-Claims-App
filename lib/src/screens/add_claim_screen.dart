import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:http/http.dart';
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
  List<ClaimType> _claimTypes = [];
  ClaimType? _selectedClaimType;
  bool _claimTypeErrorFlag = false;

  DateTime? _selectedDate;
  bool _dateErrorFlag = false;

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    _getClaimTypesSync();
    super.initState();
  }

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

  void _getClaimTypesSync() => _getClaimTypes();

  Future<void> _getClaimTypes() async {
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/getClaimList.php'),
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJZVFkiLCJuYW1lIjoiWVRZIENsYWltIFBvcnRhbCIsImFkbWluIjp0cnVlfQ.0rUmUcY752J_4dXYMr4Tfo1_BuZnXt7Uv4IpshDbwEI',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'CLAIMGROUP': 'YTY_CL_A'}),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _claimTypes = responseData[0]['data']
            .map<ClaimType>(
              (dynamic type) => ClaimType(
                code: type['CLAIM_TYPE_CODE'],
                name: type['CLAIM_TYPE_NAME'],
              ),
            )
            .toList();
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reach server'),
        ),
      );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 32),
                // Claim type
                DropdownButtonFormField<ClaimType>(
                  items: _claimTypes
                      .map<DropdownMenuItem<ClaimType>>(
                        (ClaimType claimType) => DropdownMenuItem<ClaimType>(
                          value: claimType,
                          child: Text(claimType.name),
                        ),
                      )
                      .toList(),
                  value: _selectedClaimType,
                  onChanged: (ClaimType? claimType) {
                    setState(() {
                      _selectedClaimType = claimType;
                    });
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Claim Type',
                    errorText:
                        _claimTypeErrorFlag ? 'Claim Type Required' : null,
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Description',
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
