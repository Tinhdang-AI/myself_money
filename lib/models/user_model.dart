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