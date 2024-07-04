import 'dart:convert';
import 'dart:io';

class ClaimItem {
  final String claimType;
  final DateTime billDate;
  final String description;
  final double billAmount;
  final double tax;
  final String currency;
  final File? attachment;

  ClaimItem({
    required this.claimType,
    required this.billDate,
    required this.description,
    required this.billAmount,
    required this.tax,
    required this.currency,
    this.attachment,
  });

  Map<String, dynamic> _toJson() {
    return {
      'claimType': claimType,
      'billDate': billDate.toIso8601String(),
      'description': description,
      'billAmount': billAmount,
      'tax': tax,
      'currency': currency,
      'attachment': attachment?.path,
    };
  }

  static String jsonEncode(List<ClaimItem> claims) {
    return json.encode(
      claims
          .map<Map<String, dynamic>>((ClaimItem claim) => claim._toJson())
          .toList(),
    );
  }

  static Future<ClaimItem> _fromJson(Map<String, dynamic> json) async {
    final attachmentPath = json['attachment'];
    File? attachment;
    if (attachmentPath != null) {
      attachment = File(attachmentPath);
      if (!await attachment.exists()) {
        attachment = null;
      }
    }
    return ClaimItem(
      claimType: json['claimType'],
      billDate: DateTime.parse(json['billDate']),
      description: json['description'],
      billAmount: json['billAmount'],
      tax: json['tax'],
      currency: json['currency'],
      attachment: attachment,
    );
  }

  static Future<List<ClaimItem>> jsonDecode(String claims) async {
    final List<Map<String, dynamic>> jsonList = json.decode(claims);
    return Future.wait(
      jsonList
          .map<Future<ClaimItem>>(
            (Map<String, dynamic> json) => ClaimItem._fromJson(json),
          )
          .toList(),
    );
  }
}
