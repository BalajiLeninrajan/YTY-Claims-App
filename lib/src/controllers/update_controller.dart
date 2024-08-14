import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:yty_claim_app/api_constants.dart';

class UpdateController extends ChangeNotifier {
  static Future<bool> getUpdateStatus(String currentVersion) async {
    late final Response response;
    try {
      response = await post(
        Uri.parse('$apiUrl/checkUpdate.php'),
        headers: {
          'Authorization': bearerToken,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"current_version": currentVersion}),
      );
    } catch (e) {
      return false;
    }
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final String updateStatus = responseData[0]['data'][0]['NEWUPDATE'];
      return updateStatus == '0' ? false : true;
    }
    return false;
  }
}
