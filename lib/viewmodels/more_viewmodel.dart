import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_formatter.dart' as currency_util;
import '/services/database_service.dart';
import '/utils/currency_formatter.dart';

class MoreViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  String _appVersion = '1.0.0';
  String _userJoinDate = '';
  String _profileImageUrl = '';

  // User statistics
  int _totalTransactions = 0;
  int _monthTransactions = 0;
  double _totalBalance = 0;

  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get appVersion => _appVersion;
  String get userJoinDate => _userJoinDate;
  String get profileImageUrl => _profileImageUrl;
  int get totalTransactions => _totalTransactions;
  int get monthTransactions => _monthTransactions;
  double get totalBalance => _totalBalance;

  // Initialize the view model
  Future<void> initialize() async {
    await Future.wait([
      _loadUserInfo(),
      _loadAppInfo(),
      _loadUserStats()
    ]);
  }

  // Load app information (version)
  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      notifyListeners();
    } catch (e) {
      // Silent error handling
    }
  }

  // Load user information (name, email, join date, profile image)
  Future<void> _loadUserInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            DateTime? createdAt;

            if (userData.containsKey('createdAt')) {
              if (userData['createdAt'] is Timestamp) {
                createdAt = (userData['createdAt'] as Timestamp).toDate();
              }
            }

            _userName = userData['name'] ?? user.displayName ?? 'Người dùng';
            _userJoinDate = createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                : '';
            _profileImageUrl = userData['profileImageUrl'] ?? '';
          }
        } catch (e) {
          // Silent error handling
        }

        // Use Firebase Auth data as fallback
        if (_userName.isEmpty) {
          _userName = user.displayName ?? 'Người dùng';
        }
        _userEmail = user.email ?? '';
        if (_userJoinDate.isEmpty && user.metadata.creationTime != null) {
          DateTime creationTime = user.metadata.creationTime!;
          _userJoinDate = '${creationTime.day}/${creationTime.month}/${creationTime.year}';
        }
        if (_profileImageUrl.isEmpty) {
          _profileImageUrl = user.photoURL ?? '';
        }
      }
    } catch (e) {
      // Silent error handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user statistics (transactions count, monthly transactions, total balance)
  Future<void> _loadUserStats() async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      final allTransactions = await _databaseService.getUserExpenses().first;
      final monthTransactions = await _databaseService.getExpensesByMonthFuture(currentMonth, currentYear);

      double totalIncome = 0;
      double totalExpense = 0;

      for (var tx in allTransactions) {
        if (tx.isExpense) {
          totalExpense += tx.amount;
        } else {
          totalIncome += tx.amount;
        }
      }

      _totalTransactions = allTransactions.length;
      _monthTransactions = monthTransactions.length;
      _totalBalance = totalIncome - totalExpense;
      notifyListeners();
    } catch (e) {
      // Silent error handling
    }
  }

  // Sign out user
  Future<bool> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await _auth.signOut();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset app data
  Future<bool> resetApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot expensesSnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .get();

        WriteBatch batch = _firestore.batch();
        for (var doc in expensesSnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        _totalTransactions = 0;
        _monthTransactions = 0;
        _totalBalance = 0;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update currency
  Future<bool> updateCurrency(String code, String symbol, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Update the currency
      await currency_util.updateCurrency(code, symbol);
      // Save to Firestore
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'currency': {
            'code': code,
            'symbol': symbol,
            'name': name,
          }
        });
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile image
  Future<bool> updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        _isLoading = true;
        notifyListeners();

        File imageFile = File(image.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        User? user = _auth.currentUser;
        if (user != null) {
          String imageId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

          await _firestore
              .collection('user_images')
              .doc(imageId)
              .set({
            'userId': user.uid,
            'imageData': base64Image,
            'timestamp': FieldValue.serverTimestamp(),
          });

          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': imageId});

          _profileImageUrl = imageId;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile (name)
  Future<bool> updateUserProfile(String newName) async {
    if (newName.trim().isEmpty || newName == _userName) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'name': newName});

        _userName = newName;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Submit user feedback
  Future<bool> submitFeedback(String feedback) async {
    if (feedback.trim().isEmpty) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      User? user = _auth.currentUser;
      await _firestore.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'userName': _userName,
        'userEmail': _userEmail,
        'feedback': feedback.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': _appVersion
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get profile image data
  Future<String?> getProfileImage(String imageId) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('user_images')
          .doc(imageId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        return data?['imageData'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper to convert base64 to image
  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
}
