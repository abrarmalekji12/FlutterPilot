import 'dart:math';
import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'figma_file_response.g.dart';

enum TextAutoSize {
  HEIGHT,
  WIDTH_AND_HEIGHT,
  TRUNCATE,
}

enum FigmaPaint {
  SOLID,
  GRADIENT_LINEAR,
  GRADIENT_RADIAL,
  GRADIENT_ANGULAR,
  GRADIENT_DIAMOND,
  IMAGE,
  EMOJI,
  VIDEO,
}

enum FigmaNodeType {
  DOCUMENT,
  CANVAS,
  FRAME,
  GROUP,
  VECTOR,
  BOOLEAN_OPERATION,
  STAR,
  LINE,
  ELLIPSE,
  REGULAR_POLYGON,
  RECTANGLE,
  TABLE,
  TABLE_CELL,
  TEXT,
  SLICE,
  COMPONENT,
  COMPONENT_SET,
  INSTANCE,
  STICKY,
  SHAPE_WITH_TEXT,
  CONNECTOR,
  WASHI_TAPE
}

enum TextCase { UPPER, LOWER, TITLE, SMALL_CAPS, SMALL_CAPS_FORCED }

enum VerticalConstraint { TOP, BOTTOM, CENTER, TOP_BOTTOM, SCALE }

enum HorizontalConstraint { LEFT, RIGHT, CENTER, LEFT_RIGHT, SCALE }

@JsonSerializable()
class FigmaFileResponse {
  FigmaFileResponse({
    this.document,
    this.components,
    this.componentSets,
    this.schemaVersion,
    this.styles,
    this.name,
    this.lastModified,
    this.thumbnailUrl,
    this.version,
    this.role,
    this.editorType,
    this.linkAccess,
  });

  FigmaDocument? document;
  FigmaComponents? components;
  Map<String, ComponentSet>? componentSets;
  int? schemaVersion;
  Map<String, FigmaStyle>? styles;
  String? name;
  String? lastModified;
  String? thumbnailUrl;
  String? version;
  String? role;
  String? editorType;
  String? linkAccess;

  factory FigmaFileResponse.fromJson(Map<String, dynamic> json) =>
      _$FigmaFileResponseFromJson(json);

// Map<String, dynamic> toJson() {
//   final _data = <String, dynamic>{};
//   _data['document'] = document.toJson();
//   _data['components'] = components.toJson();
//   _data['componentSets'] = componentSets.toJson();
//   _data['schemaVersion'] = schemaVersion;
//   _data['styles'] = styles.toJson();
//   _data['name'] = name;
//   _data['lastModified'] = lastModified;
//   _data['thumbnailUrl'] = thumbnailUrl;
//   _data['version'] = version;
//   _data['role'] = role;
//   _data['editorType'] = editorType;
//   _data['linkAccess'] = linkAccess;
//   return _data;
// }
}

@JsonSerializable()
class FigmaDocument {
  FigmaDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.scrollBehavior,
    required this.children,
  });

  String? id;
  String? name;
  String? type;
  String? scrollBehavior;
  List<FigmaComponent>? children;

  factory FigmaDocument.fromJson(json) => _$FigmaDocumentFromJson(json);

  toJson() => _$FigmaDocumentToJson(this);
}

@JsonSerializable()
class GradientHandlePosition {
  double? x;
  double? y;

  GradientHandlePosition({this.x, this.y});

  factory GradientHandlePosition.fromJson(json) =>
      _$GradientHandlePositionFromJson(json);

  toJson() => _$GradientHandlePositionToJson(this);
}

@JsonSerializable()
class GradientStop {
  FigmaColor? color;
  double? position;

  GradientStop({this.color, this.position});

  factory GradientStop.fromJson(json) => _$GradientStopFromJson(json);

  toJson() => _$GradientStopToJson(this);
}

@JsonSerializable()
class FigmaFill {
  FigmaPaint? type;
  FigmaColor? color;
  double? opacity;
  bool? visible;
  String? blendMode;
  String? scaleMode;
  String? imageRef;
  List<GradientStop>? gradientStops;
  List<GradientHandlePosition>? gradientHandlePositions;

  FigmaFill({
    this.type,
    this.color,
    this.visible,
    this.opacity,
    this.scaleMode,
    this.blendMode,
    this.imageRef,
    this.gradientStops,
    this.gradientHandlePositions,
  });

  // String get begin {
  //  if(gradientHandlePositions![0])
  // }
  factory FigmaFill.fromJson(json) => _$FigmaFillFromJson(json);
  toJson() => _$FigmaFillToJson(this);
}

@JsonSerializable()
class LayoutConstraint {
  HorizontalConstraint? horizontal;
  VerticalConstraint? vertical;

  LayoutConstraint({
    this.horizontal,
    this.vertical,
  });

  factory LayoutConstraint.fromJson(json) => _$LayoutConstraintFromJson(json);
  toJson() => _$LayoutConstraintToJson(this);
}

@JsonSerializable()
class LayoutGrid {
  String? pattern;
  double? sectionSize;
  bool? visible;
  FigmaColor? color;
  String? alignment;
  double? gutterSize;
  double? offset;
  int? count;

  LayoutGrid(
    this.pattern,
    this.sectionSize,
    this.visible,
    this.color,
    this.alignment,
    this.gutterSize,
    this.offset,
    this.count,
  );

  factory LayoutGrid.fromJson(json) => _$LayoutGridFromJson(json);

  toJson() => _$LayoutGridToJson(this);
}

@JsonSerializable()
class FigmaComponent {
  FigmaComponent(
      {this.id,
      this.name,
      this.type,
      this.scrollBehavior,
      this.children,
      this.backgroundColor,
      this.prototypeStartNodeID,
      this.flowStartingPoints,
      this.prototypeDevice,
      this.absoluteRenderBounds,
      this.absoluteBoundingBox,
      this.characters,
      this.fills,
      this.background,
      this.strokeWeight,
      this.cornerRadius,
      this.strokes,
      this.visible,
      this.constraints,
      this.opacity,
      this.strokeAlign,
      this.layoutGrids,
      this.strokeDashes,
      this.isMask = false,
      this.style});

  @JsonKey(includeFromJson: false, includeToJson: false)
  List<FigmaComponent>? masking;
  String? id;
  bool? visible;
  String? name;
  FigmaNodeType? type;
  String? scrollBehavior;
  double? rotation;
  double? opacity;
  LayoutConstraint? constraints;
  List<FigmaFill>? fills = [];
  List<FigmaFill>? background = [];
  FigmaColor? backgroundColor;
  List<FigmaFill>? strokes = [];
  List<FigmaComponent>? children;
  bool isMask;

  List<LayoutGrid>? layoutGrids;
  String? prototypeStartNodeID;
  List<FlowStartingPoints>? flowStartingPoints;
  PrototypeDevice? prototypeDevice;
  AbsoluteBoundingBox? absoluteBoundingBox;
  AbsoluteRenderBounds? absoluteRenderBounds;
  String? characters;
  FigmaTextStyle? style;
  String? strokeAlign;
  double? strokeWeight;
  List<double>? strokeDashes;
  double? cornerRadius;

  bool get hasAnyChild {
    return children?.isNotEmpty ?? false;
  }

  Rect getClipped(Rect rect) {
    final box = absoluteRenderBounds ?? absoluteBoundingBox!;
    final overlap = box.overlaps(rect);
    if (overlap) {
      final cb = absoluteBoundingBox!;
      return Rect.fromLTRB(
        max(cb.left, rect.left),
        max(cb.top, rect.top),
        min(cb.right, rect.right),
        min(cb.bottom, rect.bottom),
      );
    }
    return rect;
  }

  factory FigmaComponent.fromJson(json) => _$FigmaComponentFromJson(json);

  bool get useImage =>
      type == FigmaNodeType.VECTOR ||
      type == FigmaNodeType.BOOLEAN_OPERATION ||
      ((type == FigmaNodeType.GROUP ||
              type == FigmaNodeType.FRAME ||
              type == FigmaNodeType.INSTANCE ||
              type == FigmaNodeType.COMPONENT) &&
          (children
                  ?.map((e) => e.useImage || (e.isDecorative && !e.hasAnyChild))
                  .every((element) => element) ??
              false));

  bool get isDecorative =>
      type == FigmaNodeType.RECTANGLE || type == FigmaNodeType.ELLIPSE;

  toJson() => _$FigmaComponentToJson(this);
}

@JsonSerializable()
class FigmaTextStyle {
  FigmaTextStyle(
      {this.fontFamily,
      this.fontPostScriptName,
      this.fontWeight,
      this.fontSize,
      this.textAlignHorizontal,
      this.textAlignVertical,
      this.letterSpacing,
      this.lineHeightPx,
      this.lineHeightPercent,
      this.lineHeightPercentFontSize,
      this.lineHeightUnit,
      this.textAutoResize,
      this.textCase});

  String? fontFamily;
  String? fontPostScriptName;
  int? fontWeight;
  double? fontSize;
  String? textAlignHorizontal;
  String? textAlignVertical;
  double? letterSpacing;
  double? lineHeightPx;
  double? lineHeightPercent;
  double? lineHeightPercentFontSize;
  String? lineHeightUnit;
  TextCase? textCase;
  TextAutoSize? textAutoResize;

  factory FigmaTextStyle.fromJson(Map<String, dynamic> json) =>
      _$FigmaTextStyleFromJson(json);
  toJson() => _$FigmaTextStyleToJson(this);
}

@JsonSerializable()
class AbsoluteBoundingBox extends Rect {
  AbsoluteBoundingBox({
    required double x,
    required double y,
    required double width,
    required double height,
  }) : super.fromLTWH(x, y, width, height);

  double get x => left;

  double get y => top;

  factory AbsoluteBoundingBox.fromJson(json) =>
      _$AbsoluteBoundingBoxFromJson(json);

  toJson() => _$AbsoluteBoundingBoxToJson(this);
  @override
  String toString() => '{"X": $x, "Y": $y,  "W": $width, "H": $height}';
}

@JsonSerializable()
class AbsoluteRenderBounds extends Rect {
  AbsoluteRenderBounds({
    required double? x,
    required double? y,
    required double? width,
    required double? height,
  }) : super.fromLTWH(x ?? 0, y ?? 0, width ?? 0, height ?? 0);

  double get x => left;
  double get y => top;

  factory AbsoluteRenderBounds.fromJson(json) =>
      _$AbsoluteRenderBoundsFromJson(json);
  toJson() => _$AbsoluteRenderBoundsToJson(this);
}

@JsonSerializable()
class FigmaColor {
  FigmaColor({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  double r;
  double g;
  double b;
  double a;

  factory FigmaColor.fromJson(json) => _$FigmaColorFromJson(json);

  toJson() => _$FigmaColorToJson(this);
}

@JsonSerializable()
class FlowStartingPoints {
  FlowStartingPoints({
    required this.nodeId,
    required this.name,
  });

  String? nodeId;
  String? name;

  factory FlowStartingPoints.fromJson(Map<String, dynamic> json) =>
      _$FlowStartingPointsFromJson(json);

  toJson() => _$FlowStartingPointsToJson(this);
}

@JsonSerializable()
class PrototypeDevice {
  PrototypeDevice({
    required this.type,
    required this.size,
    required this.presetIdentifier,
    required this.rotation,
  });

  String? type;
  FigmaSize? size;
  String? presetIdentifier;
  String? rotation;

  factory PrototypeDevice.fromJson(Map<String, dynamic> json) =>
      _$PrototypeDeviceFromJson(json);

  toJson() => _$PrototypeDeviceToJson(this);
}

@JsonSerializable()
class FigmaSize extends Size {
  FigmaSize({
    required double width,
    required double height,
  }) : super(width, height);

  factory FigmaSize.fromJson(Map<String, dynamic> json) =>
      _$FigmaSizeFromJson(json);

  toJson() => _$FigmaSizeToJson(this);
}

@JsonSerializable()
class FigmaComponents {
  final Map<String, ComponentStyle>? properties;

  FigmaComponents({this.properties});

  factory FigmaComponents.fromJson(json) => _$FigmaComponentsFromJson(json);

  toJson() => _$FigmaComponentsToJson(this);
}

@JsonSerializable()
class ComponentStyle {
  ComponentStyle({
    this.key,
    this.name,
    this.description,
    this.remote,
    this.documentationLinks,
  });

  String? key;
  String? name;
  String? description;
  bool? remote;
  List<dynamic>? documentationLinks;

  factory ComponentStyle.fromJson(Map<String, dynamic> json) =>
      _$ComponentStyleFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentStyleToJson(this);
}

@JsonSerializable()
class ComponentSet {
  String? key;
  String? fileKey;
  String? nodeId;
  String? thumbnailUrl;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;

  ComponentSet({
    this.key,
    this.fileKey,
    this.nodeId,
    this.thumbnailUrl,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ComponentSet.fromJson(json) => _$ComponentSetFromJson(json);

  toJson() => _$ComponentSetToJson(this);

// FrameInfo? containing_frame;
// PageInfo? containing_page;
}

@JsonSerializable()
class FigmaStyle {
  String? key;
  String? name;
  String? description;
  bool? remote;
  FigmaStyleType? styleType;

  FigmaStyle({
    this.key,
    this.name,
    this.description,
    this.remote,
    this.styleType,
  });

  factory FigmaStyle.fromJson(json) => _$FigmaStyleFromJson(json);

  toJson() => _$FigmaStyleToJson(this);
}

enum FigmaStyleType { FILL, TEXT, EFFECT, GRID }

enum FigmaFillType {
  SOLID,
  GRADIENT_LINEAR,
  GRADIENT_RADIAL,
  GRADIENT_ANGULAR,
  GRADIENT_DIAMOND,
  IMAGE,
  EMOJI,
  VIDEO
}
