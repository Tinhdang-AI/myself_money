import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? currency;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.profileImageUrl,
    this.currency,
  });
  
    factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      profileImageUrl: data['profileImageUrl'],
      currency: data['currency'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (currency != null) 'currency': currency,
    };
  }
  
// Create a copy with changes
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    String? profileImageUrl,
    Map<String, dynamic>? currency,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currency: currency ?? this.currency,
    );
  }
}