import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get expensesCollection => _firestore.collection('expenses');

  // Save user info
  Future<void> saveUserInfo(String name, String email, {String? profileImageUrl}) async {
    if (currentUserId == null) return;

    await usersCollection.doc(currentUserId).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    }, SetOptions(merge: true));
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    DocumentSnapshot doc = await usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Save categories to Firebase
  Future<void> saveCategories({
    required List<Map<String, Object>> expenseCategories,
    required List<Map<String, Object>> incomeCategories
  }) async {
    if (currentUserId == null) return;

    // Convert categories to serializable format
    List<Map<String, dynamic>> serializableExpenseCategories = expenseCategories.map((category) {
      return {
        "label": category["label"],
        "iconCode": (category["icon"] as IconData).codePoint,
        "fontFamily": "MaterialIcons"
      };
    }).toList();

    List<Map<String, dynamic>> serializableIncomeCategories = incomeCategories.map((category) {
      return {
        "label": category["label"],
        "iconCode": (category["icon"] as IconData).codePoint,
        "fontFamily": "MaterialIcons"
      };
    }).toList();

    // Save to Firestore
    await usersCollection.doc(currentUserId).set({
      'expenseCategories': serializableExpenseCategories,
      'incomeCategories': serializableIncomeCategories,
      'lastUpdated': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      // Lấy tài liệu người dùng
      DocumentSnapshot userDoc = await usersCollection.doc(currentUserId).get();

      if (!userDoc.exists) {
        return [];
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Lấy danh sách danh mục chi tiêu
      List<Map<String, dynamic>> expenseCategories = [];
      if (userData.containsKey('expenseCategories')) {
        for (var category in userData['expenseCategories']) {
          String label = category['label'] ?? '';

          expenseCategories.add({
            'name': label,
            'originalKey': label,
            'icon': category['iconCode'].toString(),
            'isExpense': true
          });
        }
      }

      // Lấy danh sách danh mục thu nhập
      List<Map<String, dynamic>> incomeCategories = [];
      if (userData.containsKey('incomeCategories')) {
        for (var category in userData['incomeCategories']) {
          String label = category['label'] ?? '';

          incomeCategories.add({
            'name': label,
            'originalKey': label,
            'icon': category['iconCode'].toString(),
            'isExpense': false
          });
        }
      }

      // Kết hợp hai danh sách
      return [...expenseCategories, ...incomeCategories];
    } catch (e) {
      print("Lỗi khi lấy danh mục: $e");
      return [];
    }
  }

  // Add expense/income transaction
  Future<String> addExpense({
    required String note,
    required double amount,
    required String category,
    required String categoryIcon,
    required DateTime date,
    required bool isExpense,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');

    ExpenseModel expense = ExpenseModel(
      id: '',
      userId: currentUserId!,
      note: note,
      amount: amount,
      category: category,
      categoryIcon: categoryIcon,
      date: date,
      isExpense: isExpense,
    );

    DocumentReference docRef = await expensesCollection.add(expense.toMap());
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  // Update an expense/income
  Future<void> updateExpense(ExpenseModel expense) async {
    await expensesCollection.doc(expense.id).update(expense.toMap());
  }

  // Delete an expense/income
  Future<void> deleteExpense(String expenseId) async {
    await expensesCollection.doc(expenseId).delete();
  }

  // Get all user expenses
  Stream<List<ExpenseModel>> getUserExpenses() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return expensesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    });
  }

  // Get expenses by date (Future)
  Future<List<ExpenseModel>> getExpensesByDateFuture(DateTime date) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DateTime startDate = DateTime(date.year, date.month, date.day);
      DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error in getExpensesByDateFuture: $e");

      // Fallback query
      try {
        QuerySnapshot snapshot = await expensesCollection
            .where('userId', isEqualTo: currentUserId)
            .get();

        List<ExpenseModel> expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();

        DateTime startDate = DateTime(date.year, date.month, date.day);
        DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

        return expenses.where((expense) {
          return expense.date.isAfter(startDate.subtract(Duration(seconds: 1))) &&
              expense.date.isBefore(endDate.add(Duration(seconds: 1)));
        }).toList();
      } catch (fallbackError) {
        print("Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  // Get expenses by month (Future)
  Future<List<ExpenseModel>> getExpensesByMonthFuture(int month, int year) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = month < 12
          ? DateTime(year, month + 1, 1).subtract(Duration(milliseconds: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error in getExpensesByMonthFuture: $e");

      // Fallback query
      try {
        QuerySnapshot snapshot = await expensesCollection
            .where('userId', isEqualTo: currentUserId)
            .get();

        List<ExpenseModel> expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();

        DateTime startDate = DateTime(year, month, 1);
        DateTime endDate = month < 12
            ? DateTime(year, month + 1, 1).subtract(Duration(milliseconds: 1))
            : DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

        return expenses.where((expense) {
          return expense.date.isAfter(startDate.subtract(Duration(seconds: 1))) &&
              expense.date.isBefore(endDate.add(Duration(seconds: 1)));
        }).toList();
      } catch (fallbackError) {
        print("Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  // Get expenses by year (Future)
  Future<List<ExpenseModel>> getExpensesByYearFuture(int year) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error in getExpensesByYearFuture: $e");

      // Fallback query
      try {
        QuerySnapshot snapshot = await expensesCollection
            .where('userId', isEqualTo: currentUserId)
            .get();

        List<ExpenseModel> expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();

        DateTime startDate = DateTime(year, 1, 1);
        DateTime endDate = DateTime(year + 1, 1, 1).subtract(Duration(milliseconds: 1));

        return expenses.where((expense) {
          return expense.date.isAfter(startDate.subtract(Duration(seconds: 1))) &&
              expense.date.isBefore(endDate.add(Duration(seconds: 1)));
        }).toList();
      } catch (fallbackError) {
        print("Fallback query also failed: $fallbackError");
        return [];
      }
    }
  }

  // Check if user has any data
  Future<bool> hasAnyData() async {
    if (currentUserId == null) return false;

    try {
      QuerySnapshot snapshot = await expensesCollection
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for data: $e");
      return false;
    }
  }

  // Submit user feedback
  Future<void> submitFeedback(String feedback, String appVersion) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('feedback').add({
        'userId': currentUserId,
        'userName': _auth.currentUser?.displayName ?? 'Unknown',
        'userEmail': _auth.currentUser?.email ?? 'Unknown',
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': appVersion
      });
    } catch (e) {
      print("Error submitting feedback: $e");
      throw e;
    }
  }
}