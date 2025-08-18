import 'dart:convert';

class Contact {
  final String userId;
  final String email;
  final String displayName;
  final DateTime addedAt;

  Contact({
    required this.userId,
    required this.email,
    required this.displayName,

    
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
