import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yty_claim_app/bearer_token.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';

import 'package:yty_claim_app/src/controllers/claim_service.dart';
import 'package:yty_claim_app/src/controllers/claim_type.dart';

class ClaimController with ChangeNotifier {
  ClaimController(this._claimService);

  final ClaimService _claimService;

  late List<ClaimItem> _claims;
  List<ClaimItem> get claims => _claims;

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

  late List<ClaimType> _claimTypes;

  List<ClaimType> get claimTypes => _claimTypes;

  Future<void> loadClaimTypesFromAPI(String claimGroup) async {
    final Response response = await post(
      Uri.parse('https://ytygroup.app/claim-api/api/getClaimList.php'),
      headers: {
        'Authorization': bearerToken,
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'CLAIMGROUP': claimGroup}),
    );
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
      _claimTypes = [];
    }

    notifyListeners();
    _claimService.updateClaimTypes(_claimTypes);
  }

  Future<void> clearClaimTypes() async {
    _claimTypes = [];
    notifyListeners();
    _claimService.updateClaimTypes([]);
  }
}
