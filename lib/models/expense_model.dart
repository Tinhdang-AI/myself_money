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
  
    factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      note: data['note'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      categoryIcon: data['categoryIcon'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isExpense: data['isExpense'] ?? true,
    );
  }

 Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'note': note,
      'amount': amount,
      'category': category,
      'categoryIcon': categoryIcon,
      'date': Timestamp.fromDate(date),
      'isExpense': isExpense,
    };
  }
  
ExpenseModel copyWith({
    String? id,
    String? userId,
    String? note,
    double? amount,
    String? category,
    String? categoryIcon,
    DateTime? date,
    bool? isExpense,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
    );
  }
}