import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 1. Tạo định dạng tiền tệ dùng chung
final NumberFormat formatCurrency = NumberFormat('#,###', 'vi_VN');

// Biến lưu đơn vị tiền tệ hiện tại
String _currencySymbol = 'đ';
String _currencyCode = 'VND';
double _exchangeRate = 1.0; // Tỉ giá so với VND

// Mapping tỉ giá (tỉ giá chuyển đổi từ VND sang đồng tiền khác)
// Các tỉ giá này đã được sửa lại để đúng chiều chuyển đổi
Map<String, double> _exchangeRates = {
  'VND': 1.0,
  'USD': 0.000040, // 1 VND = 0.000040 USD (hay 25,000 VND = 1 USD)
  'EUR': 0.000037, // 1 VND = 0.000037 EUR (hay 27,000 VND = 1 EUR)
  'GBP': 0.000032, // 1 VND = 0.000032 GBP (hay 31,250 VND = 1 GBP)
  'JPY': 0.0061,   // 1 VND = 0.0061 JPY (hay 1 VND = 0.0061 JPY)
  'CNY': 0.00029,  // 1 VND = 0.00029 CNY (hay 3,448 VND = 1 CNY)
  'KRW': 0.055,    // 1 VND = 0.055 KRW (hay 18.18 VND = 1 KRW)
  'SGD': 0.000054, // 1 VND = 0.000054 SGD (hay 18,500 VND = 1 SGD)
  'THB': 0.0014,   // 1 VND = 0.0014 THB (hay 714 VND = 1 THB)
  'MYR': 0.00019,  // 1 VND = 0.00019 MYR (hay 5,263 VND = 1 MYR)
};

// Phương thức khởi tạo tiền tệ
Future<void> initCurrency() async {
  final prefs = await SharedPreferences.getInstance();
  _currencySymbol = prefs.getString('currencySymbol') ?? 'đ';
  _currencyCode = prefs.getString('currencyCode') ?? 'VND';
  _exchangeRate = prefs.getDouble('exchangeRate') ?? 1.0;

  // Load các tỉ giá đã lưu trước đó
  String? ratesJson = prefs.getString('exchangeRates');
  if (ratesJson != null) {
    try {
      Map<String, dynamic> savedRates = jsonDecode(ratesJson);
      savedRates.forEach((key, value) {
        _exchangeRates[key] = value;
      });
    } catch (e) {
      print("Error loading exchange rates: $e");
    }
  }
