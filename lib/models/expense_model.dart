import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String note;
  final double amount;
  final String category;
  final String categoryIcon;
  final DateTime date;
  final bool isExpense;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.note,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.date,
    required this.isExpense,
  });