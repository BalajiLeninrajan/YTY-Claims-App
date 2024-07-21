import 'dart:convert';

class ClaimType {
  final String code;
  final String name;

  ClaimType({required this.code, required this.name});

  Map<String, String> _toJson() {
    return {
      'code': code,
      'name': name,
    };
  }

  static String jsonEncode(List<ClaimType> types) {
    return json.encode(
      types
          .map<Map<String, String>>((ClaimType type) => type._toJson())
          .toList(),
    );
  }

  static ClaimType _fromJson(Map<String, String> json) {
    return ClaimType(
      code: json['code']!,
      name: json['name']!,
    );
  }

  static List<ClaimType> jsonDecode(String jsonString) {
    return json
        .decode(jsonString)
        .map<ClaimType>(
          (dynamic json) => ClaimType._fromJson(json),
        )
        .toList();
  }
}
