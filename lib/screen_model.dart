import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'screen_model.g.dart';

enum TargetPlatformType {
  mobile(Icons.phone_android, 'Mobile'),
  tablet(Icons.tablet_android, 'Tablet'),
  desktop(Icons.desktop_windows_rounded, 'Desktop');

  const TargetPlatformType(this.icon, this.name);

  final IconData icon;
  final String name;
}

@JsonSerializable()
class ScreenConfig {
  final double width, height;
  final String name;
  double scale;
  String? identifier;
  final TargetPlatformType type;

  // double get calculatedWidth => width * (2 - scale);

  // double get calculatedHeight => height * (2 - scale);

  ScreenConfig(this.name, this.width, this.height, this.type, {this.scale = 1});

  toJson() => _$ScreenConfigToJson(this);

  factory ScreenConfig.fromJson(Map<String, dynamic> json) =>
      _$ScreenConfigFromJson(json);

  @override
  String toString() => '$name($width x $height)';
}
