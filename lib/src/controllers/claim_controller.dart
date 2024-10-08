import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yty_claim_app/api_constants.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';

import 'package:yty_claim_app/src/controllers/claim_service.dart';
import 'package:yty_claim_app/src/controllers/claim_type.dart';

class ClaimController with ChangeNotifier {
  ClaimController(this._claimService);

  final ClaimService _claimService;

  late List<ClaimItem> _claims;
  List<ClaimItem> get claims => _claims;

  late List<ClaimType> _claimTypes;
  List<ClaimType> get claimTypes => _claimTypes;

  late List<String> _currencies;
  List<String> get currencies => _currencies;

  Future<void> loadClaims() async {
    _claims = await _claimService.getClaims();

    notifyListeners();
  }

  Future<void> addClaim(ClaimItem claim) async {
    _claims.add(claim);
    notifyListeners();
    await _claimService.updateClaims(_claims);
  }

  Future<void> removeClaim(ClaimItem claim) async {
    _claims.remove(claim);
    notifyListeners();
    await _claimService.updateClaims(_claims);
  }

  Future<void> clearClaims() async {
    _claims = [];
    notifyListeners();
    await _claimService.updateClaims(_claims);
  }

  Future<void> loadClaimTypes() async {
    _claimTypes = await _claimService.getClaimTypes();
    notifyListeners();
  }

  Future<void> loadClaimTypesFromAPI(String claimGroup) async {
    late final Response response;
    try {
      response = await post(
        Uri.parse('$apiUrl/getClaimList.php'),
        headers: {
          'Authorization': bearerToken,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'CLAIMGROUP': claimGroup}),
      );
    } catch (e) {
      rethrow; // TODO
    }
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _claimTypes = responseData[0]['data']
          .map<ClaimType>(
            (dynamic type) => ClaimType(
              code: type['CLAIM_TYPE_CODE'],
              name: type['CLAIM_TYPE_NAME'],
            ),
          )
          .toList();
    } else {
      throw Exception("Error: getClaimList.php ${response.statusCode}");
    }

    notifyListeners();
    _claimService.updateClaimTypes(_claimTypes);
  }

  Future<void> clearClaimTypes() async {
    _claimTypes = [];
    notifyListeners();
    _claimService.updateClaimTypes([]);
  }

  Future<void> loadCurrencies() async {
    _currencies = await _claimService.getCurrencies();
    notifyListeners();
  }

  Future<void> loadCurrenciesFromAPI() async {
    late final Response response;
    try {
      response = await post(
        Uri.parse('$apiUrl/getCurrencyList.php'),
        headers: {
          'Authorization': bearerToken,
          'Content-Type': 'application/json'
        },
      );
    } catch (e) {
      rethrow;
    }
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _currencies = responseData[0]['data']
          .map<String>(
            (dynamic currency) => currency['FROM_CURRENCY'] as String,
          )
          .toList();
    } else {
      throw Exception("Error: getCurrencyList.php  ${response.statusCode}");
    }

    notifyListeners();
    _claimService.updateCurrencies(_currencies);
  }

  Future<String> getExchangeRate(String currency) async {
    late final Response response;
    try {
      response = await post(
        Uri.parse('$apiUrl/getExchangeRate.php'),
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
    } catch (e) {
      rethrow;
    }
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData[0]['data'][0]['RATE'];
    } else {
      throw Exception("Error: getExchangeRate.php ${response.statusCode}");
    }
  }

  Future<void> clearCurrencies() async {
    _currencies = [];
    notifyListeners();
    _claimService.updateClaimTypes([]);
  }
}
