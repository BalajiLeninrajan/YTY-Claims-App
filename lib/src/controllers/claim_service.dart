import 'package:shared_preferences/shared_preferences.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';
import 'package:yty_claim_app/src/controllers/claim_type.dart';

/// A service that stores and retrieves claims.
class ClaimService {
  static const String prefKeyThemeMode = 'ThemeMode';
  static const String prefKeyLoginFlag = 'LoginFlag';
  static const String prefKeyClaims = 'Claims';
  static const String prefKeyClaimTypes = 'Claim Types';

  Future<List<ClaimItem>> getClaims() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? claimsJson = prefs.getString(prefKeyClaims);
    if (claimsJson == null) {
      return [];
    }
    return ClaimItem.jsonDecode(claimsJson);
  }

  Future<void> updateClaims(List<ClaimItem> claims) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = ClaimItem.jsonEncode(claims);
    await prefs.setString(prefKeyClaims, encodedData);
  }

  Future<List<ClaimType>> getClaimTypes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? claimsJson = prefs.getString(prefKeyClaimTypes);
    if (claimsJson == null) {
      return [];
    }
    return ClaimType.jsonDecode(claimsJson);
  }

  Future<void> updateClaimTypes(List<ClaimType> types) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = ClaimType.jsonEncode(types);
    await prefs.setString(prefKeyClaimTypes, encodedData);
  }
}
