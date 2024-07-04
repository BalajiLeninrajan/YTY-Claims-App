import 'package:shared_preferences/shared_preferences.dart';
import 'package:yty_claim_app/src/controllers/claim_item.dart';

/// A service that stores and retrieves claims.
class ClaimService {
  static const String prefKeyThemeMode = 'ThemeMode';
  static const String prefKeyLoginFlag = 'LoginFlag';
  static const String prefKeyClaims = 'Claims';

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
}
