import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  // String userId;
  String email;
  String password;
  DateTime lastSyncTime;
  String? pin;

  User({
    required this.id,
    // required this.userId,
    required this.email,
    required this.password,
    required this.lastSyncTime,
    this.pin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // 'userId': userId,
      'email': email,
      'password': password,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'pin': pin,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      // userId: map['userId'],
      email: map['email'],
      password: map['password'],
      lastSyncTime: DateTime.parse(map['lastSyncTime']),
      pin: map['pin'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      // 'userId': userId,
      'email': email,
      'password': password,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'pin': pin,
    };
  }

  factory User.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return User(
      id: data['id'],
      // userId: data['userId'],
      email: data['email'],
      password: data['password'],
      lastSyncTime: DateTime.parse(data['lastSyncTime']),
      pin: data['pin'],
    );
  }
}
