import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yty_claim_app/api_constants.dart';
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
  final ImagePicker _picker = ImagePicker();

  ClaimType? _selectedClaimType;

  DateTime? _selectedDate = DateTime.now();
  bool _dateErrorFlag = false;

  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCurrency = 'MYR';

  final TextEditingController _billAmountController =
      TextEditingController.fromValue(
    const TextEditingValue(text: '0'),
  );
  bool _billAmountErrorFlag = false;

  final TextEditingController _taxController = TextEditingController.fromValue(
    const TextEditingValue(text: '0'),
  );
  bool _taxErrorFlag = false;

  double _total = 0;

  File? _attachment;
  bool _attachErrorFlag = false;

  final TextEditingController _distanceController =
      TextEditingController.fromValue(
    const TextEditingValue(text: '0'),
  );
  bool _distanceErrorFlag = false;

  bool _isLoading = false;

  @override
  void initState() {
    setState(() {
      _selectedClaimType = widget.controller.claimTypes.first;
    });
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
      lastDate: DateTime.now(),
    );
    if (newDate != null && newDate != _selectedDate) {
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  void _getTotal() {
    final double billAmount = double.tryParse(_billAmountController.text) ?? 0;
    final double taxAmount = double.tryParse(_taxController.text) ?? 0;

    setState(() {
      _total = (billAmount + taxAmount);
    });
  }

  Future<Response> _sendClaim(ClaimItem claim) async {
    setState(() {
      _isLoading = true;
    });
    late final Response response;
    try {
      late String exchangeRate;
      if (claim.claimTypeId != '002') {
        exchangeRate = await widget.controller.getExchangeRate(
          claim.currency ?? 'MYR',
        );
      } else {
        exchangeRate = '1';
      }
      response = await post(
        Uri.parse('$apiUrl/saveClaim.php'),
        headers: {
          'Authorization': bearerToken,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'EMP_ID': widget.settingsController.loginFlag,
          'CLAIM_TYPE': claim.claimTypeId,
          'DT': claim.billDate.toIso8601String().substring(0, 10),
          'CLAIM_DESCRIPTION': claim.description,
          'CLAIM_BILL_AMT': claim.billAmount?.toString() ?? '0',
          'CLAIM_TAX_AMT': claim.tax?.toString() ?? '0',
          'CLAIM_CURRENCY_TYPE': claim.currency ?? 'MYR',
          'CLAIM_EXCHANGE_RATE': exchangeRate,
          'TOTAL_CLAIM_AMT_MYR': claim.total == null
              ? '0'
              : (claim.total! * double.parse(exchangeRate)).toString(),
          'REMARK': '',
          'CLAIM_FILE_EXTENSION': claim.attachment?.uri.pathSegments.last ?? '',
          'KILOMETER': claim.distance?.toString() ?? '',
          'RATE_PER_KILOMETER': '',
          'CLAIM_URL': '',
          'ATTACHMENT': await getBase64(claim.attachment),
        }),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to Save Claim, Saved to device'),
          ),
        );
      }
      response = Response('', 404);
    }
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

    if ((double.tryParse(_billAmountController.text) == null ||
            double.tryParse(_billAmountController.text)! <= 0) &&
        _selectedClaimType?.code != '002') {
      setState(() {
        _billAmountErrorFlag = true;
      });
      generalFlag = false;
    }

    if (double.tryParse(_taxController.text) == null &&
        _selectedClaimType?.code != '002') {
      setState(() {
        _taxErrorFlag = true;
      });
      generalFlag = false;
    }

    if ((double.tryParse(_distanceController.text) == null ||
            double.tryParse(_distanceController.text)! <= 0) &&
        _selectedClaimType?.code == '002') {
      setState(() {
        _distanceErrorFlag = true;
      });
      generalFlag = false;
    }

    if (_attachment == null) {
      setState(() {
        _attachErrorFlag = true;
      });
      generalFlag = false;
    }

    if (generalFlag) {
      setState(() {
        _dateErrorFlag = false;
        _billAmountErrorFlag = false;
        _taxErrorFlag = false;
        _distanceErrorFlag = false;
      });

      final newClaim = ClaimItem(
        claimTypeId: _selectedClaimType!.code,
        claimTypeName: _selectedClaimType!.name,
        billDate: _selectedDate!,
        description: _descriptionController.text,
        billAmount: _selectedClaimType!.code == '002'
            ? null
            : double.parse(_billAmountController.text),
        tax: _selectedClaimType!.code == '002'
            ? null
            : double.parse(_taxController.text),
        currency: _selectedClaimType!.code == '002' ? null : _selectedCurrency,
        total: _selectedClaimType!.code == '002' ? null : _total,
        attachment: _attachment,
        distance: _selectedClaimType!.code == '002'
            ? double.parse(_distanceController.text)
            : null,
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

      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> getFilePicker() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(allowMultiple: false);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
    if (result != null) {
      setState(() {
        _attachment = File(result!.files.single.path!);
        _attachErrorFlag = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: no file selected'),
          ),
        );
      }
    }
  }

  Future<void> getCameraOutput() async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(source: ImageSource.camera);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
    if (photo != null) {
      setState(() {
        _attachment = File(photo!.path);
        _attachErrorFlag = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No image taken'),
          ),
        );
      }
    }
  }

  Future<void> getGalleryOutput() async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(source: ImageSource.gallery);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
    if (photo != null) {
      setState(() {
        _attachment = File(photo!.path);
        _attachErrorFlag = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No image selected'),
          ),
        );
      }
    }
  }

  Widget get _priceFromFields => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency
          DropdownButtonFormField<String>(
            items: widget.controller.currencies
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
              });
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Currency',
              errorText: _selectedCurrency == null ? 'Currency Required' : null,
            ),
          ),
          const SizedBox(height: 24),
          // bill ammount
          TextField(
            controller: _billAmountController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Bill Amount',
              errorText: _billAmountErrorFlag ? 'Bill Amount Required' : null,
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
            ],
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (String? value) => setState(() {
              _billAmountErrorFlag = false;
            }),
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
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
            ],
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (String? value) => setState(() {
              _taxErrorFlag = false;
            }),
          ),
          const SizedBox(height: 16),
          // total
          TextButton.icon(
            onPressed: () {},
            label: Text(
              'Total ($_selectedCurrency): ${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.wallet),
          ),
        ],
      );

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
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                iconColor: Theme.of(context).colorScheme.error,
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
                      if (_selectedClaimType?.code != '002') _priceFromFields,
                      if (_selectedClaimType?.code == '002')
                        TextField(
                          controller: _distanceController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: 'Distance (KM)',
                            errorText:
                                _distanceErrorFlag ? 'Distance Required' : null,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (String? value) => setState(() {
                            _distanceErrorFlag = false;
                          }),
                        ),
                      const SizedBox(height: 16),
                      // attachment
                      FilledButton.tonalIcon(
                        onPressed: () {
                          if (_attachment == null) {
                            showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 200,
                                            child: FilledButton.icon(
                                              label: const Text('From File'),
                                              onPressed: () {
                                                getFilePicker();
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(
                                                Icons.file_open,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          SizedBox(
                                            width: 200,
                                            child: FilledButton.icon(
                                              label: const Text('From Gallery'),
                                              onPressed: () {
                                                getGalleryOutput();
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(
                                                Icons.browse_gallery,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          SizedBox(
                                            width: 200,
                                            child: FilledButton.icon(
                                              label: const Text('From Camera'),
                                              onPressed: () {
                                                getCameraOutput();
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(
                                                Icons.camera_alt,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            setState(() {
                              _attachment = null;
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
                        style: _attachErrorFlag
                            ? FilledButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                iconColor: Theme.of(context).colorScheme.error,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addTask,
                            label: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('SYNC'),
                            ),
                            icon: const Icon(Icons.move_up),
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
