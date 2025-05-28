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

  // Cập nhật tỉ giá nếu có mạng
  updateExchangeRates();
}

// Cập nhật tỉ giá từ API
Future<void> updateExchangeRates() async {
  try {
    // Sử dụng API miễn phí để lấy tỉ giá
    final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/VND')
    ).timeout(Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('rates')) {
        final Map<String, dynamic> rates = data['rates'];

        // Cập nhật tỉ giá VND sang các loại tiền khác
        for (String code in _exchangeRates.keys) {
          if (rates.containsKey(code) && code != 'VND') {
            // Tỉ giá từ VND sang đồng tiền khác
            _exchangeRates[code] = rates[code];
          }
        }

        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('exchangeRates', jsonEncode(_exchangeRates));

        // Cập nhật tỉ giá hiện tại
        _exchangeRate = _exchangeRates[_currencyCode] ?? 1.0;
        await prefs.setDouble('exchangeRate', _exchangeRate);
      }
    }
  } catch (e) {
    print("Error updating exchange rates: $e");
    // Sử dụng giá trị sẵn có nếu không thể cập nhật
  }
}

// Phương thức cập nhật đơn vị tiền tệ
Future<void> updateCurrency(String code, String symbol) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('currencySymbol', symbol);
  await prefs.setString('currencyCode', code);

  // Cập nhật tỉ giá cho đồng tiền mới
  _exchangeRate = _exchangeRates[code] ?? 1.0;
  await prefs.setDouble('exchangeRate', _exchangeRate);

  _currencySymbol = symbol;
  _currencyCode = code;
}

// Lấy symbol hiện tại
String getCurrentSymbol() {
  return _currencySymbol;
}

// Lấy mã tiền tệ hiện tại
String getCurrentCode() {
  return _currencyCode;
}

// Chuyển đổi giá trị từ VND sang đơn vị tiền tệ hiện tại
double convertFromVND(double amountInVND) {
  if (_currencyCode == 'VND') return amountInVND;
  return amountInVND * _exchangeRate;
}

// Chuyển đổi giá trị từ đơn vị tiền tệ hiện tại sang VND
double convertToVND(double amountInCurrentCurrency) {
  if (_currencyCode == 'VND') return amountInCurrentCurrency; // Không cần chuyển đổi nếu là VND
  return amountInCurrentCurrency / _exchangeRate;
}

// 2. Tạo widget định dạng input tiền tệ với tỉ giá hiện tại
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    bool useDecimals = _currencyCode == 'USD' || _currencyCode == 'EUR' ||
        _currencyCode == 'GBP' || _currencyCode == 'SGD' ||
        _currencyCode == 'MYR';

    String digitsOnly;
    if (useDecimals) {
      digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
      int decimalCount = '.'.allMatches(digitsOnly).length;
      if (decimalCount > 1) {
        int firstDecimalIndex = digitsOnly.indexOf('.');
        digitsOnly = digitsOnly.substring(0, firstDecimalIndex + 1) +
            digitsOnly.substring(firstDecimalIndex + 1).replaceAll('.', '');
      }
    } else {
      digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    }

    if (digitsOnly.isEmpty) {
      return TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    double value;
    try {
      value = double.parse(digitsOnly);
    } catch (e) {
      return oldValue; // Trả về giá trị cũ nếu không phân tích được
    }

    // Giới hạn tối đa
    const double maxValue = 1000000000000; // 1 nghìn tỷ
    if (value > maxValue) {
      value = maxValue;
    }

    String formattedValue;
    if (useDecimals) {
      if (digitsOnly.contains('.')) {
        List<String> parts = digitsOnly.split('.');
        String wholePart = parts[0];
        String decimalPart = parts.length > 1 ? parts[1] : '';
        if (decimalPart.length > 2) {
          decimalPart = decimalPart.substring(0, 2);
        }
        wholePart = NumberFormat('#,###', 'en_US').format(double.parse(wholePart));
        formattedValue = '$wholePart.$decimalPart';
      } else {
        formattedValue = NumberFormat('#,###', 'en_US').format(value);
      }
    } else {
      formattedValue = formatCurrency.format(value);
    }

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

}

// 3. Hàm chuyển đổi từ chuỗi định dạng tiền tệ sang số
double parseFormattedCurrency(String formattedAmount) {
  if (formattedAmount.isEmpty) return 0;

  // Xác định xem đồng tiền có dùng số thập phân không
  bool useDecimals = _currencyCode == 'USD' || _currencyCode == 'EUR' ||
      _currencyCode == 'GBP' || _currencyCode == 'SGD' ||
      _currencyCode == 'MYR';

  String cleanedAmount;
  if (useDecimals) {
    // Giữ lại số và dấu thập phân cho đồng tiền có số thập phân
    cleanedAmount = formattedAmount.replaceAll(RegExp(r'[^\d.]'), '');
  } else {
    // Chỉ giữ lại số cho đồng tiền không dùng số thập phân
    cleanedAmount = formattedAmount.replaceAll(RegExp(r'[^\d]'), '');
  }

  return cleanedAmount.isEmpty ? 0 : double.parse(cleanedAmount);
}

// 4. Hàm định dạng số thành chuỗi tiền tệ có đơn vị
String formatCurrencyWithSymbol(double amountInVND) {
  try {
    // Chuyển đổi giá trị từ VND sang đơn vị tiền tệ hiện tại
    double convertedAmount = convertFromVND(amountInVND);

    // Định dạng khác nhau cho các loại tiền tệ
    String formattedAmount;

    // Kiểm tra loại tiền tệ để định dạng phù hợp
    if (_currencyCode == 'USD' || _currencyCode == 'EUR' ||
        _currencyCode == 'GBP' || _currencyCode == 'SGD' ||
        _currencyCode == 'MYR') {
      // Dùng hai chữ số thập phân cho USD, EUR, GBP, SGD, MYR
      formattedAmount = NumberFormat('#,##0.00', 'en_US').format(convertedAmount);
    } else if (_currencyCode == 'JPY' || _currencyCode == 'KRW') {
      // Không dùng chữ số thập phân cho JPY, KRW
      formattedAmount = formatCurrency.format(convertedAmount.round());
    } else {
      // Mặc định cho các loại tiền tệ khác (VND)
      formattedAmount = formatCurrency.format(convertedAmount.round());
    }

    // Trả về chuỗi tiền tệ với đơn vị
    // Định dạng ký hiệu tiền tệ theo vị trí thích hợp
    if (_currencyCode == 'USD') {
      return '$_currencySymbol$formattedAmount'; // $1,234.56
    } else {
      // Mặc định cho các loại tiền tệ khác
      return '$formattedAmount $_currencySymbol'; // 1,234 đ
    }
  } catch (e) {
    print("Lỗi khi định dạng tiền tệ: $e");
    // Trả về một giá trị mặc định nếu có lỗi
    return '0 $_currencySymbol';
  }
}

NumberFormat getCurrentCurrencyFormatter() {
  if (_currencyCode == 'USD' || _currencyCode == 'EUR' || _currencyCode == 'GBP' || _currencyCode == 'SGD' || _currencyCode == 'MYR') {
    return NumberFormat('#,##0.00', 'en_US');
  } else {
    return NumberFormat('#,###', 'vi_VN');
  }
}


// 5. Phiên bản bổ sung hỗ trợ định dạng số âm
String formatCurrencyWithSign(double amountInVND) {
  String sign = amountInVND >= 0 ? "+" : "-";
  return '$sign${formatCurrencyWithSymbol(amountInVND.abs())}';
}

// 6. Danh sách các đơn vị tiền tệ phổ biến để người dùng lựa chọn
List<Map<String, String>> commonCurrencies = [
  {'code': 'VND', 'symbol': 'đ', 'name': 'Việt Nam Đồng'},
  {'code': 'USD', 'symbol': '\$', 'name': 'Đô la Mỹ'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'Bảng Anh'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Yên Nhật'},
  {'code': 'CNY', 'symbol': '¥', 'name': 'Nhân dân tệ'},
  {'code': 'KRW', 'symbol': '₩', 'name': 'Won Hàn Quốc'},
  {'code': 'SGD', 'symbol': 'S\$', 'name': 'Đô la Singapore'},
  {'code': 'THB', 'symbol': '฿', 'name': 'Baht Thái'},
  {'code': 'MYR', 'symbol': 'RM', 'name': 'Ringgit Malaysia'},
];
