import 'dart:convert';

enum ConnectionRequestStatus {
  pending,
  accepted,
  declined,
  expired
}

class ConnectionRequest {
  final String requestId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String toUserId;
  final String toUserName;
  final String toUserEmail;
  final ConnectionRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  ConnectionRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    required this.toUserId,
    required this.toUserName,
    required this.toUserEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'toUserEmail': toUserEmail,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'message': message,
    };
  }

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      requestId: json['requestId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      fromUserEmail: json['fromUserEmail'] ?? '',
      toUserId: json['toUserId'] ?? '',
      toUserName: json['toUserName'] ?? '',
      toUserEmail: json['toUserEmail'] ?? '',
      status: ConnectionRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => ConnectionRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      message: json['message'],
    );
  }

  ConnectionRequest copyWith({
    String? requestId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserEmail,
    String? toUserId,
    String? toUserName,
    String? toUserEmail,
    ConnectionRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return ConnectionRequest(
      requestId: requestId ?? this.requestId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserEmail: fromUserEmail ?? this.fromUserEmail,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      toUserEmail: toUserEmail ?? this.toUserEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  bool get isPending => status == ConnectionRequestStatus.pending;
  bool get isAccepted => status == ConnectionRequestStatus.accepted;
  bool get isDeclined => status == ConnectionRequestStatus.declined;
  bool get isExpired => status == ConnectionRequestStatus.expired;

  bool get isExpiredByTime {
    final expiryTime = createdAt.add(const Duration(days: 7)); // Requests expire after 7 days
    return DateTime.now().isAfter(expiryTime);
  }
}
