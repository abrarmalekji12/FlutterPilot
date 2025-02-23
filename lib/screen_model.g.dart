// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScreenConfig _$ScreenConfigFromJson(Map<String, dynamic> json) => ScreenConfig(
      json['name'] as String,
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
      $enumDecode(_$TargetPlatformTypeEnumMap, json['type']),
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
    )..identifier = json['identifier'] as String?;

Map<String, dynamic> _$ScreenConfigToJson(ScreenConfig instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'name': instance.name,
      'scale': instance.scale,
      'identifier': instance.identifier,
      'type': _$TargetPlatformTypeEnumMap[instance.type]!,
    };

const _$TargetPlatformTypeEnumMap = {
  TargetPlatformType.mobile: 'mobile',
  TargetPlatformType.tablet: 'tablet',
  TargetPlatformType.desktop: 'desktop',
};
