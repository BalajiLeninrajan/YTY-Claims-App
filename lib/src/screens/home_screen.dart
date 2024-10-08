import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yty_claim_app/api_constants.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';
import 'package:yty_claim_app/src/controllers/settings_controller.dart';
import 'package:yty_claim_app/src/screens/add_claim_screen.dart';
import 'package:yty_claim_app/src/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.claimController,
    required this.settingsController,
  });

  static const routeName = '/';
  final ClaimController claimController;
  final SettingsController settingsController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    widget.claimController.addListener(_updateState);
    super.initState();
  }

  @override
  void dispose() {
    widget.claimController.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  void _showConfirmDialog(BuildContext context, ClaimItem claim) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete the claim?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  widget.claimController.removeClaim(claim);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          );
        });
  }

  Future<void> _sendClaims() async {
    setState(() {
      _isLoading = true;
    });
    late final Response response;
    for (ClaimItem claim in widget.claimController.claims) {
      try {
        late String exchangeRate;
        if (claim.claimTypeId != '002') {
          exchangeRate = await widget.claimController.getExchangeRate(
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
            'CLAIM_FILE_EXTENSION':
                claim.attachment?.uri.pathSegments.last ?? '',
            'KILOMETER': claim.distance?.toString() ?? '',
            'RATE_PER_KILOMETER': '',
            'CLAIM_URL': '',
            'ATTACHMENT': await getBase64(claim.attachment),
          }),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData[0]['data'] != 'Save Success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData[0]['data'] as String)),
          );
          return;
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode.toString()),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sent claims successfully'),
      ),
    );
    widget.claimController.clearClaims();
  }

  Future<String> getBase64(File? file) async {
    if (file == null) return '';
    final uInt8List = await file.readAsBytes();
    return base64Encode(uInt8List);
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
            onPressed:
                widget.claimController.claims.isEmpty ? null : _sendClaims,
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
      body: widget.claimController.claims.isEmpty
          ? const Center(child: Text('No Failed Claims'))
          : Stack(
              children: [
                ListView.builder(
                  itemCount: widget.claimController.claims.length,
                  itemBuilder: (BuildContext context, int index) {
                    ClaimItem claim = widget.claimController.claims[index];
                    return Card(
                      child: ListTile(
                        title: claim.claimTypeId == '002'
                            ? Text(
                                '${claim.claimTypeName} | KM ${claim.distance!}',
                              )
                            : Text(
                                '${claim.claimTypeName} | ${claim.currency} ${claim.total!.toStringAsFixed(2)}',
                              ),
                        subtitle: Text(
                          claim.description,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          onPressed: () => _showConfirmDialog(context, claim),
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Theme.of(context)
                        .dialogBackgroundColor
                        .withOpacity(0.5),
                    child: const Center(
                      child: RefreshProgressIndicator(),
                    ),
                  )
              ],
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
