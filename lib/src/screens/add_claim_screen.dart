import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yty_claim_app/bearer_token.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:http/http.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';
import 'package:yty_claim_app/src/controllers/claim_type.dart';
import 'package:yty_claim_app/src/controllers/settings_controller.dart';

class AddClaimScreen extends StatefulWidget {
  const AddClaimScreen({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  static const routeName = '/add';
  final ClaimController controller;
  final SettingsController settingsController;

  @override
  State<AddClaimScreen> createState() => _AddClaimScreenState();
}

class _AddClaimScreenState extends State<AddClaimScreen> {
  ClaimType? _selectedClaimType;

  DateTime? _selectedDate;
  bool _dateErrorFlag = false;

  final TextEditingController _descriptionController = TextEditingController();

  List<String> _currencies = [];
  String? _selectedCurrency = 'MYR';

  String? _exchangeRate = '1';

  final TextEditingController _billAmountController = TextEditingController();
  bool _billAmountErrorFlag = false;

  final TextEditingController _taxController = TextEditingController.fromValue(
    const TextEditingValue(text: '0'),
  );
  bool _taxErrorFlag = false;

  double _total = 0;

  File? _attachment;

  bool _isLoading = false;

  @override
  void initState() {
    setState(() {
      _selectedClaimType = widget.controller.claimTypes.first;
    });
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

  void _getCurrenciesSync() => _getCurrencies();

  Future<void> _getCurrencies() async {
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/getCurrencyList.php'),
      headers: {
        'Authorization': bearerToken,
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
        'Authorization': bearerToken,
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

  Future<Response> _sendClaim(ClaimItem claim) async {
    setState(() {
      _isLoading = true;
    });
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/saveClaim.php'),
      headers: {
        'Authorization': bearerToken,
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'EMP_ID': widget.settingsController.loginFlag,
        'CLAIM_TYPE': claim.claimTypeId,
        'CLAIM_DESCRIPTION': claim.description,
        'CLAIM_BILL_AMT': claim.billAmount.toString(),
        'CLAIM_TAX_AMT': claim.tax.toString(),
        'CLAIM_CURRENCY_TYPE': claim.currency,
        'CLAIM_EXCHANGE_RATE': claim.exchangeRate,
        'TOTAL_CLAIM_AMT_MYR': claim.total.toString(),
        'REMARK': '',
        'CLAIM_FILE_EXTENSION': claim.attachment?.uri.pathSegments.last ?? '',
        'KILOMETER': '',
        'RATE_PER_KILOMETER': '',
        'CLAIM_URL': '',
        'Attachment': await getBase64(claim.attachment),
      }),
    );
    setState(() {
      _isLoading = false;
    });
    return response;
  }

  Future<String> getBase64(File? file) async {
    if (file == null) return '';
    final uInt8List = await file.readAsBytes();
    return base64Encode(uInt8List);
  }

  void _addTask() async {
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

      final newClaim = ClaimItem(
        claimTypeId: _selectedClaimType!.code,
        claimTypeName: _selectedClaimType!.name,
        billDate: _selectedDate!,
        description: _descriptionController.text,
        billAmount: double.parse(_billAmountController.text),
        tax: double.parse(_taxController.text),
        currency: _selectedCurrency!,
        exchangeRate: _exchangeRate!,
        total: _total,
        attachment: _attachment,
      );

      Response response = await _sendClaim(newClaim);

      if (response.statusCode != 200 ||
          jsonDecode(response.body)[0]['data'] != 'Save Success') {
        widget.controller.addClaim(newClaim);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sent claim successfully'),
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Claim')),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                        items: widget.controller.claimTypes
                            .map<DropdownMenuItem<ClaimType>>(
                              (ClaimType claimType) =>
                                  DropdownMenuItem<ClaimType>(
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
                          errorText: _selectedClaimType == null
                              ? 'Claim Type Required'
                              : null,
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
                        maxLength: 500,
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
                          errorText: _billAmountErrorFlag
                              ? 'Bill Amount Required'
                              : null,
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
                          errorText:
                              _taxErrorFlag ? 'Tax Amount Required' : null,
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
                            onPressed: _addTask,
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
