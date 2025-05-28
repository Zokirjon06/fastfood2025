import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

extension NumberToMoney on num? {
  toMoney() {
    if (this == null) {
      return 0;
    }
    return NumberFormat('#,###').format(this);
  }
}

extension StringToMoney on String {
  String toMoney() {
    return NumberFormat('#,###.00').format(pickOnlyNumber());
  }
}

extension TimeOfDayToString on TimeOfDay {
  String toFormat24() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

extension DateFormateToYYMMDD on DateTime? {
  String toYYMMDD() {
    if (this == null) {
      return '';
    }
    return DateFormat('yyyy-MM-dd').format(this!);
  }
}

extension TimeOfDayFromString on TimeOfDay {
  static TimeOfDay fromString(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }
}

extension FindFrequency on String {
  String findFrequency() {
    switch (this) {
      case 'daily':
        return 'Har kuni';
      case 'Daily':
        return 'Har hafta';
      case 'monthly':
        return 'Har oy';
      default:
        return 'Har kuni';
    }
  }
}

extension PickOnlyNumber on String? {
  String pickOnlyNumber() {
    String result = '';
    if (this == null) {
      return '';
    }
    final payload = this!;
    for (var i = 0; i < payload.length; i++) {
      if (payload[i] == '0' ||
          payload[i] == '1' ||
          payload[i] == '2' ||
          payload[i] == '3' ||
          payload[i] == '4' ||
          payload[i] == '5' ||
          payload[i] == '6' ||
          payload[i] == '7' ||
          payload[i] == '8' ||
          payload[i] == '9') {
        result += payload[i];
      }
    }

    return result;
  }
}

extension FomratNumberToReadable on num {
  String toReadable() {
    if (this >= 1000000) {
      // Convert to millions
      final millions = this / 1000000;
      if (millions % 1 == 0) {
        return '${millions.toInt()} mln so\'m';
      }
      return '${millions.toStringAsFixed(1)} mln so\'m';
    } else if (this >= 1000) {
      // Convert to thousands
      final thousands = this / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()} ming so\'m';
      }
      return '${thousands.toStringAsFixed(1)} ming so\'m';
    }
    // For numbers less than a thousand
    return '${toInt()} so\'m';
  }
}
