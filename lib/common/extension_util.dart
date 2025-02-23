import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constant/string_constant.dart';
import '../injector.dart';

final numberFormat = NumberFormat(
  '#.##',
  'en_US',
);

extension KeyHelper on GlobalKey {
  Offset? get position => (currentContext?.findRenderObject() as RenderBox)
      .localToGlobal(Offset.zero);
  Size? get size => (currentContext?.findRenderObject() as RenderBox?)?.size;
}

extension DNum on num {
  EdgeInsets get insetsAll => EdgeInsets.all(w);
  EdgeInsets get insetsAllAbs => EdgeInsets.all(toDouble());

  EdgeInsets get insetsVertical => EdgeInsets.symmetric(vertical: h);

  EdgeInsets get insetsHorizontal => EdgeInsets.symmetric(horizontal: w);

  double get h => platform == PlatformType.tablet
      ? this * 0.82
      : (platform == PlatformType.desktop
          ? this * 0.82
          : toDouble()); //toDouble();//ScreenUtil().setHeight(this);

  double get w => platform == PlatformType.tablet
      ? this * 0.87
      : (platform == PlatformType.desktop
          ? (this * 0.87)
          : toDouble()); //toDouble();//ScreenUtil().setWidth(this);

  double get r =>
      deviceWidth > 1250 ? toDouble() : this * 0.8; //ScreenUtil().radius(this);

  double get sp => platform == PlatformType.tablet
      ? 0.85 * this
      : (platform == PlatformType.desktop
          ? (!isLandscapeTab ? this * 0.87 : this * 0.80)
          : toDouble()); //ScreenUtil().setSp(this);

  BorderRadius get borderRadius => BorderRadius.circular(r);

  Radius get radius => Radius.circular(toDouble());

  SizedBox get hBox => SizedBox(height: h);

  Divider get hDivider => Divider(height: h);

  SizedBox get wBox => SizedBox(width: w);

  String get formatCurrency => '\$${numberFormat.format(this)}';
  String get formatTime => '$this min';
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    return Color(int.parse('FF$hexString', radix: 16));
  }
}

extension DateOnlyCompare on DateTime {
  bool isBeforeOrSame(DateTime datetime) {
    return isBefore(datetime) || (datetime.difference(this).inMinutes == 0);
  }

  bool isAfterOrSame(DateTime datetime) {
    return isAfter(datetime) || (datetime.difference(this).inMinutes == 0);
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime get todayDate {
    return DateTime(
      year,
      month,
      day,
    );
  }

  bool isInBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }
}

extension AppString on String {
  String truncateAfter([int? len = 20]) {
    if (len == null) {
      return this;
    }
    if (length <= len) {
      return this;
    }
    return '${substring(0, len - 3)}...';
  }
}

extension ValueNotifierAnimation on ValueNotifier {
  Future<void> animateTo(Offset offset, Duration duration) async {
    final Offset last = value;
    const step = 0.01;
    final l = (duration.inMilliseconds * step).toInt();
    for (double i = 0; i < 1; i += step) {
      value = Offset(lerpDouble(last.dx, offset.dx, i)!,
          lerpDouble(last.dy, offset.dy, i)!);
      await Future.delayed(Duration(milliseconds: l));
    }
  }
}

extension StringEmailValidation on String {
  bool isValidEmail() {
    return StringEmptyValidation(this).hasValidData() &&
        RegExp(wEmailRegex).hasMatch(this);
  }

  bool isValidPassword() {
    return StringEmptyValidation(this).hasValidData() &&
        trim().length >= minPasswordLength;
  }
}

extension DurationExt on Duration {
  String get formatHHMM {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    final h = inHours;
    return "${h > 0 ? '${twoDigits(inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  String showInHHMM(bool big) {
    final days = inDays;
    if (days >= 7) {
      final w = days ~/ 7;
      return '$w ${big ? 'week${w > 1 ? 's' : ''}' : 'w'}';
    }
    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}';
    }
    final minutes = inMinutes;
    if (minutes == 0) {
      return '$inSeconds ${big ? 'seconds' : 's'}';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h > 0 ? '$h ${big ? (h > 1 ? 'hours' : 'hour') : 'h'}' : ''}${m > 0 ? ('${h > 0 ? ' ' : ''}$m ${big ? (m > 1 ? 'minutes' : 'minute') : 'm'}') : ''}';
  }
}

extension myMath on num {
  double get toDegree => 180 * this / pi;
  double get toRadian => this * pi / 180;
}

extension MyRect on Rect {
  double get area => width * height;
  bool containsRect(Rect rect) =>
      contains(rect.topLeft) && contains(rect.bottomRight);
}

extension ListEmptyValidation on List<dynamic> {
  bool hasData() {
    return isNotEmpty;
  }
}

extension StringEmptyValidation on String {
  bool hasValidData() {
    return trim().isNotEmpty;
  }
}
