import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  DateTime? _selectedDate;
  bool _dateErrorFlag = false;

  final TextEditingController _descriptionController = TextEditingController();

  List<String> _currencies = [];
  String? _selectedCurrency = 'MYR';

  String? _exchangeRate = '1';

  final TextEditingController _billAmountController = TextEditingController();
  bool _billAmountErrorFlag = false;

  final TextEditingController _taxController = TextEditingController();
  bool _taxErrorFlag = false;

  double _total = 0;

  File? _attachment;

  @override
  void initState() {
    _getClaimTypesSync();
    _getCurrenciesSync();
    _billAmountController.addListener(_getTotal);
    _taxController.addListener(_getTotal);
    super.initState();
  }

  @override
  void dispose() {
    _billAmountController.removeListener(_getTotal);
    _taxController.removeListener(_getTotal);
    _billAmountController.dispose();
    _taxController.dispose();
    super.dispose();
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
        _selectedClaimType = _claimTypes.first;
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

  void _getCurrenciesSync() => _getCurrencies();

  Future<void> _getCurrencies() async {
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/getCurrencyList.php'),
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJZVFkiLCJuYW1lIjoiWVRZIENsYWltIFBvcnRhbCIsImFkbWluIjp0cnVlfQ.0rUmUcY752J_4dXYMr4Tfo1_BuZnXt7Uv4IpshDbwEI',
        'Content-Type': 'application/json'
      },
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _currencies = responseData[0]['data']
            .map<String>(
              (dynamic currency) => currency['FROM_CURRENCY'] as String,
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

  void _getExchangeRateSync(String currency) => _getExchangeRate(currency);

  Future<void> _getExchangeRate(String currency) async {
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/getExchangeRate.php'),
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJZVFkiLCJuYW1lIjoiWVRZIENsYWltIFBvcnRhbCIsImFkbWluIjp0cnVlfQ.0rUmUcY752J_4dXYMr4Tfo1_BuZnXt7Uv4IpshDbwEI',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(
        {
          'DT': DateTime.now().toIso8601String().substring(0, 10),
          'CURR': currency
        },
      ),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _exchangeRate = responseData[0]['data'][0]['RATE'];
        _getTotal();
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

  void _getTotal() {
    final double billAmount = double.tryParse(_billAmountController.text) ?? 0;
    final double taxAmount = double.tryParse(_taxController.text) ?? 0;
    final double exchangeRate = double.tryParse(_exchangeRate ?? '1') ?? 1;

    setState(() {
      _total = (billAmount + taxAmount) * exchangeRate;
    });
  }

  void _addTask() {
    bool generalFlag = true;
    if (_selectedDate == null) {
      setState(() {
        _dateErrorFlag = true;
      });
      generalFlag = false;
    }

    if (double.tryParse(_billAmountController.text) == null) {
      setState(() {
        _billAmountErrorFlag = true;
      });
      generalFlag = false;
    }

    if (double.tryParse(_taxController.text) == null) {
      setState(() {
        _taxErrorFlag = true;
      });
      generalFlag = false;
    }

    if (generalFlag) {
      setState(() {
        _dateErrorFlag = false;
        _billAmountErrorFlag = false;
        _taxErrorFlag = false;
      });

      widget.controller.addClaim(
        ClaimItem(
          claimTypeId: _selectedClaimType!.code,
          claimTypeName: _selectedClaimType!.name,
          billDate: _selectedDate!,
          description: _descriptionController.text,
          billAmount: double.parse(_billAmountController.text),
          tax: double.parse(_taxController.text),
          currency: _selectedCurrency!,
          total: _total,
        ),
      );

      Navigator.pop(context);
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 16),
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
                          _claimTypes.isEmpty ? 'Claim Type Required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date
                  FilledButton.tonalIcon(
                    onPressed: () => _selectDate(context),
                    label: Text(
                      _selectedDate == null
                          ? (_dateErrorFlag ? 'Date Required' : 'Bill Date')
                          : '${_selectedDate?.toIso8601String().substring(0, 10)}',
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
                  ),
                  const SizedBox(height: 24),
                  // Currency
                  DropdownButtonFormField<String>(
                    items: _currencies
                        .map<DropdownMenuItem<String>>(
                          (String currency) => DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          ),
                        )
                        .toList(),
                    value: _selectedCurrency,
                    onChanged: (String? currency) {
                      setState(() {
                        _selectedCurrency = currency;
                        _exchangeRate = null;
                      });
                      _getExchangeRateSync(currency ?? 'MYR');
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Currency',
                      errorText:
                          _currencies.isEmpty ? 'Currency Required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // exchange rate
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Exchange Rate: ${_exchangeRate ?? 'Loading exchange rate'}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // bill ammount
                  TextField(
                    controller: _billAmountController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Bill Amount',
                      errorText:
                          _billAmountErrorFlag ? 'Bill Amount Required' : null,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // tax ammount
                  TextField(
                    controller: _taxController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Tax Amount',
                      errorText: _taxErrorFlag ? 'Tax Amount Required' : null,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // total
                  TextButton.icon(
                    onPressed: () {},
                    label: Text(
                      'Total (MYR): ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    icon: const Icon(Icons.wallet),
                  ),
                  const SizedBox(height: 16),
                  // attachment
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(allowMultiple: false);
                      if (result != null) {
                        setState(() {
                          _attachment = File(result.files.single.path!);
                        });
                      }
                    },
                    label: Text(
                      _attachment == null
                          ? 'Attach'
                          : _attachment!.path.length > 15
                              ? ('...${_attachment!.path.substring(_attachment!.path.length - 12)}')
                              : _attachment!.path,
                    ),
                    icon: const Icon(Icons.attach_file),
                  ),
                  const SizedBox(height: 16),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (_currencies.isEmpty || _claimTypes.isEmpty)
                            ? null
                            : _addTask,
                        label: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Add Claim'),
                        ),
                        icon: const Icon(Icons.add),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
