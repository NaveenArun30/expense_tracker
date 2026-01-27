import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final String? inviteCode;

  const GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.inviteCode,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      inviteCode: json['invite_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'invite_code': inviteCode,
    };
  }

  @override
  List<Object?> get props => [id, name, createdBy, createdAt, inviteCode];
}

class GroupMember extends Equatable {
  final String groupId;
  final String userId;
  final String role; // 'admin', 'member', 'viewer'
  final DateTime joinedAt;

  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      groupId: json['group_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  @override
  List<Object?> get props => [groupId, userId, role, joinedAt];
}
