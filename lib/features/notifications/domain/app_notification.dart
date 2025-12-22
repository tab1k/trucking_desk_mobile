import 'package:flutter/foundation.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.entityId,
    this.type,
    this.role,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? entityId;
  final String? type;
  final String? role;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? entityId,
    String? type,
    String? role,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      entityId: entityId ?? this.entityId,
      type: type ?? this.type,
      role: role ?? this.role,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] ?? json['createdAt'];
    final created =
        createdRaw is String
            ? DateTime.tryParse(createdRaw)
            : createdRaw is int
                ? DateTime.fromMillisecondsSinceEpoch(createdRaw)
                : null;

    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?)?.trim() ?? '',
      body: (json['body'] as String?)?.trim() ?? '',
      createdAt: created ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      entityId: json['entity_id']?.toString(),
      type: (json['type'] as String?)?.trim(),
      role: (json['role'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      if (entityId != null) 'entity_id': entityId,
      if (type != null) 'type': type,
      if (role != null) 'role': role,
    };
  }
}
