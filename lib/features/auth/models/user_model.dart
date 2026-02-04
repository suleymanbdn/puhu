import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

/// Kullanıcı modeli
@HiveType(typeId: 10)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String password; // Gerçek uygulamada hash'lenmiş olmalı

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? username,
    String? password,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}





