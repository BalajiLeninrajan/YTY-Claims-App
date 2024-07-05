import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';

import 'package:yty_claim_app/src/controllers/claim_service.dart';

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
}
