// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'figma_file_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FigmaFileResponse _$FigmaFileResponseFromJson(Map<String, dynamic> json) =>
    FigmaFileResponse(
      document: json['document'] == null
          ? null
          : FigmaDocument.fromJson(json['document']),
      components: json['components'] == null
          ? null
          : FigmaComponents.fromJson(json['components']),
      componentSets: (json['componentSets'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ComponentSet.fromJson(e)),
      ),
      schemaVersion: json['schemaVersion'] as int?,
      styles: (json['styles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, FigmaStyle.fromJson(e)),
      ),
      name: json['name'] as String?,
      lastModified: json['lastModified'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      version: json['version'] as String?,
      role: json['role'] as String?,
      editorType: json['editorType'] as String?,
      linkAccess: json['linkAccess'] as String?,
    );

Map<String, dynamic> _$FigmaFileResponseToJson(FigmaFileResponse instance) =>
    <String, dynamic>{
      'document': instance.document?.toJson(),
      'components': instance.components?.toJson(),
      'componentSets':
          instance.componentSets?.map((k, e) => MapEntry(k, e.toJson())),
      'schemaVersion': instance.schemaVersion,
      'styles': instance.styles?.map((k, e) => MapEntry(k, e.toJson())),
      'name': instance.name,
      'lastModified': instance.lastModified,
      'thumbnailUrl': instance.thumbnailUrl,
      'version': instance.version,
      'role': instance.role,
      'editorType': instance.editorType,
      'linkAccess': instance.linkAccess,
    };

FigmaDocument _$FigmaDocumentFromJson(Map<String, dynamic> json) =>
    FigmaDocument(
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      scrollBehavior: json['scrollBehavior'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map(FigmaComponent.fromJson)
          .toList(),
    );

Map<String, dynamic> _$FigmaDocumentToJson(FigmaDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'scrollBehavior': instance.scrollBehavior,
      'children': instance.children?.map((e) => e.toJson()).toList(),
    };

GradientHandlePosition _$GradientHandlePositionFromJson(
        Map<String, dynamic> json) =>
    GradientHandlePosition(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GradientHandlePositionToJson(
        GradientHandlePosition instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

GradientStop _$GradientStopFromJson(Map<String, dynamic> json) => GradientStop(
      color: json['color'] == null ? null : FigmaColor.fromJson(json['color']),
      position: (json['position'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GradientStopToJson(GradientStop instance) =>
    <String, dynamic>{
      'color': instance.color?.toJson(),
      'position': instance.position,
    };

FigmaFill _$FigmaFillFromJson(Map<String, dynamic> json) => FigmaFill(
      type: $enumDecodeNullable(_$FigmaPaintEnumMap, json['type']),
      color: json['color'] == null ? null : FigmaColor.fromJson(json['color']),
      visible: json['visible'] as bool?,
      opacity: (json['opacity'] as num?)?.toDouble(),
      scaleMode: json['scaleMode'] as String?,
      blendMode: json['blendMode'] as String?,
      imageRef: json['imageRef'] as String?,
      gradientStops: (json['gradientStops'] as List<dynamic>?)
          ?.map(GradientStop.fromJson)
          .toList(),
      gradientHandlePositions:
          (json['gradientHandlePositions'] as List<dynamic>?)
              ?.map(GradientHandlePosition.fromJson)
              .toList(),
    );

Map<String, dynamic> _$FigmaFillToJson(FigmaFill instance) => <String, dynamic>{
      'type': _$FigmaPaintEnumMap[instance.type],
      'color': instance.color?.toJson(),
      'opacity': instance.opacity,
      'visible': instance.visible,
      'blendMode': instance.blendMode,
      'scaleMode': instance.scaleMode,
      'imageRef': instance.imageRef,
      'gradientStops': instance.gradientStops?.map((e) => e.toJson()).toList(),
      'gradientHandlePositions':
          instance.gradientHandlePositions?.map((e) => e.toJson()).toList(),
    };

const _$FigmaPaintEnumMap = {
  FigmaPaint.SOLID: 'SOLID',
  FigmaPaint.GRADIENT_LINEAR: 'GRADIENT_LINEAR',
  FigmaPaint.GRADIENT_RADIAL: 'GRADIENT_RADIAL',
  FigmaPaint.GRADIENT_ANGULAR: 'GRADIENT_ANGULAR',
  FigmaPaint.GRADIENT_DIAMOND: 'GRADIENT_DIAMOND',
  FigmaPaint.IMAGE: 'IMAGE',
  FigmaPaint.EMOJI: 'EMOJI',
  FigmaPaint.VIDEO: 'VIDEO',
};

LayoutConstraint _$LayoutConstraintFromJson(Map<String, dynamic> json) =>
    LayoutConstraint(
      horizontal: $enumDecodeNullable(
          _$HorizontalConstraintEnumMap, json['horizontal']),
      vertical:
          $enumDecodeNullable(_$VerticalConstraintEnumMap, json['vertical']),
    );

Map<String, dynamic> _$LayoutConstraintToJson(LayoutConstraint instance) =>
    <String, dynamic>{
      'horizontal': _$HorizontalConstraintEnumMap[instance.horizontal],
      'vertical': _$VerticalConstraintEnumMap[instance.vertical],
    };

const _$HorizontalConstraintEnumMap = {
  HorizontalConstraint.LEFT: 'LEFT',
  HorizontalConstraint.RIGHT: 'RIGHT',
  HorizontalConstraint.CENTER: 'CENTER',
  HorizontalConstraint.LEFT_RIGHT: 'LEFT_RIGHT',
  HorizontalConstraint.SCALE: 'SCALE',
};

const _$VerticalConstraintEnumMap = {
  VerticalConstraint.TOP: 'TOP',
  VerticalConstraint.BOTTOM: 'BOTTOM',
  VerticalConstraint.CENTER: 'CENTER',
  VerticalConstraint.TOP_BOTTOM: 'TOP_BOTTOM',
  VerticalConstraint.SCALE: 'SCALE',
};

LayoutGrid _$LayoutGridFromJson(Map<String, dynamic> json) => LayoutGrid(
      json['pattern'] as String?,
      (json['sectionSize'] as num?)?.toDouble(),
      json['visible'] as bool?,
      json['color'] == null ? null : FigmaColor.fromJson(json['color']),
      json['alignment'] as String?,
      (json['gutterSize'] as num?)?.toDouble(),
      (json['offset'] as num?)?.toDouble(),
      json['count'] as int?,
    );

Map<String, dynamic> _$LayoutGridToJson(LayoutGrid instance) =>
    <String, dynamic>{
      'pattern': instance.pattern,
      'sectionSize': instance.sectionSize,
      'visible': instance.visible,
      'color': instance.color?.toJson(),
      'alignment': instance.alignment,
      'gutterSize': instance.gutterSize,
      'offset': instance.offset,
      'count': instance.count,
    };

FigmaComponent _$FigmaComponentFromJson(Map<String, dynamic> json) =>
    FigmaComponent(
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: $enumDecodeNullable(_$FigmaNodeTypeEnumMap, json['type']),
      scrollBehavior: json['scrollBehavior'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map(FigmaComponent.fromJson)
          .toList(),
      backgroundColor: json['backgroundColor'] == null
          ? null
          : FigmaColor.fromJson(json['backgroundColor']),
      prototypeStartNodeID: json['prototypeStartNodeID'] as String?,
      flowStartingPoints: (json['flowStartingPoints'] as List<dynamic>?)
          ?.map((e) => FlowStartingPoints.fromJson(e as Map<String, dynamic>))
          .toList(),
      prototypeDevice: json['prototypeDevice'] == null
          ? null
          : PrototypeDevice.fromJson(
              json['prototypeDevice'] as Map<String, dynamic>),
      absoluteRenderBounds: json['absoluteRenderBounds'] == null
          ? null
          : AbsoluteRenderBounds.fromJson(json['absoluteRenderBounds']),
      absoluteBoundingBox: json['absoluteBoundingBox'] == null
          ? null
          : AbsoluteBoundingBox.fromJson(json['absoluteBoundingBox']),
      characters: json['characters'] as String?,
      fills:
          (json['fills'] as List<dynamic>?)?.map(FigmaFill.fromJson).toList(),
      background: (json['background'] as List<dynamic>?)
          ?.map(FigmaFill.fromJson)
          .toList(),
      strokeWeight: (json['strokeWeight'] as num?)?.toDouble(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble(),
      strokes:
          (json['strokes'] as List<dynamic>?)?.map(FigmaFill.fromJson).toList(),
      visible: json['visible'] as bool?,
      constraints: json['constraints'] == null
          ? null
          : LayoutConstraint.fromJson(json['constraints']),
      opacity: (json['opacity'] as num?)?.toDouble(),
      strokeAlign: json['strokeAlign'] as String?,
      layoutGrids: (json['layoutGrids'] as List<dynamic>?)
          ?.map(LayoutGrid.fromJson)
          .toList(),
      strokeDashes: (json['strokeDashes'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      isMask: json['isMask'] as bool? ?? false,
      style: json['style'] == null
          ? null
          : FigmaTextStyle.fromJson(json['style'] as Map<String, dynamic>),
    )..rotation = (json['rotation'] as num?)?.toDouble();

Map<String, dynamic> _$FigmaComponentToJson(FigmaComponent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visible': instance.visible,
      'name': instance.name,
      'type': _$FigmaNodeTypeEnumMap[instance.type],
      'scrollBehavior': instance.scrollBehavior,
      'rotation': instance.rotation,
      'opacity': instance.opacity,
      'constraints': instance.constraints?.toJson(),
      'fills': instance.fills?.map((e) => e.toJson()).toList(),
      'background': instance.background?.map((e) => e.toJson()).toList(),
      'backgroundColor': instance.backgroundColor?.toJson(),
      'strokes': instance.strokes?.map((e) => e.toJson()).toList(),
      'children': instance.children?.map((e) => e.toJson()).toList(),
      'isMask': instance.isMask,
      'layoutGrids': instance.layoutGrids?.map((e) => e.toJson()).toList(),
      'prototypeStartNodeID': instance.prototypeStartNodeID,
      'flowStartingPoints':
          instance.flowStartingPoints?.map((e) => e.toJson()).toList(),
      'prototypeDevice': instance.prototypeDevice?.toJson(),
      'absoluteBoundingBox': instance.absoluteBoundingBox?.toJson(),
      'absoluteRenderBounds': instance.absoluteRenderBounds?.toJson(),
      'characters': instance.characters,
      'style': instance.style?.toJson(),
      'strokeAlign': instance.strokeAlign,
      'strokeWeight': instance.strokeWeight,
      'strokeDashes': instance.strokeDashes,
      'cornerRadius': instance.cornerRadius,
    };

const _$FigmaNodeTypeEnumMap = {
  FigmaNodeType.DOCUMENT: 'DOCUMENT',
  FigmaNodeType.CANVAS: 'CANVAS',
  FigmaNodeType.FRAME: 'FRAME',
  FigmaNodeType.GROUP: 'GROUP',
  FigmaNodeType.VECTOR: 'VECTOR',
  FigmaNodeType.BOOLEAN_OPERATION: 'BOOLEAN_OPERATION',
  FigmaNodeType.STAR: 'STAR',
  FigmaNodeType.LINE: 'LINE',
  FigmaNodeType.ELLIPSE: 'ELLIPSE',
  FigmaNodeType.REGULAR_POLYGON: 'REGULAR_POLYGON',
  FigmaNodeType.RECTANGLE: 'RECTANGLE',
  FigmaNodeType.TABLE: 'TABLE',
  FigmaNodeType.TABLE_CELL: 'TABLE_CELL',
  FigmaNodeType.TEXT: 'TEXT',
  FigmaNodeType.SLICE: 'SLICE',
  FigmaNodeType.COMPONENT: 'COMPONENT',
  FigmaNodeType.COMPONENT_SET: 'COMPONENT_SET',
  FigmaNodeType.INSTANCE: 'INSTANCE',
  FigmaNodeType.STICKY: 'STICKY',
  FigmaNodeType.SHAPE_WITH_TEXT: 'SHAPE_WITH_TEXT',
  FigmaNodeType.CONNECTOR: 'CONNECTOR',
  FigmaNodeType.WASHI_TAPE: 'WASHI_TAPE',
};

FigmaTextStyle _$FigmaTextStyleFromJson(Map<String, dynamic> json) =>
    FigmaTextStyle(
      fontFamily: json['fontFamily'] as String?,
      fontPostScriptName: json['fontPostScriptName'] as String?,
      fontWeight: json['fontWeight'] as int?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      textAlignHorizontal: json['textAlignHorizontal'] as String?,
      textAlignVertical: json['textAlignVertical'] as String?,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
      lineHeightPx: (json['lineHeightPx'] as num?)?.toDouble(),
      lineHeightPercent: (json['lineHeightPercent'] as num?)?.toDouble(),
      lineHeightPercentFontSize:
          (json['lineHeightPercentFontSize'] as num?)?.toDouble(),
      lineHeightUnit: json['lineHeightUnit'] as String?,
      textAutoResize:
          $enumDecodeNullable(_$TextAutoSizeEnumMap, json['textAutoResize']),
      textCase: $enumDecodeNullable(_$TextCaseEnumMap, json['textCase']),
    );

Map<String, dynamic> _$FigmaTextStyleToJson(FigmaTextStyle instance) =>
    <String, dynamic>{
      'fontFamily': instance.fontFamily,
      'fontPostScriptName': instance.fontPostScriptName,
      'fontWeight': instance.fontWeight,
      'fontSize': instance.fontSize,
      'textAlignHorizontal': instance.textAlignHorizontal,
      'textAlignVertical': instance.textAlignVertical,
      'letterSpacing': instance.letterSpacing,
      'lineHeightPx': instance.lineHeightPx,
      'lineHeightPercent': instance.lineHeightPercent,
      'lineHeightPercentFontSize': instance.lineHeightPercentFontSize,
      'lineHeightUnit': instance.lineHeightUnit,
      'textCase': _$TextCaseEnumMap[instance.textCase],
      'textAutoResize': _$TextAutoSizeEnumMap[instance.textAutoResize],
    };

const _$TextAutoSizeEnumMap = {
  TextAutoSize.HEIGHT: 'HEIGHT',
  TextAutoSize.WIDTH_AND_HEIGHT: 'WIDTH_AND_HEIGHT',
  TextAutoSize.TRUNCATE: 'TRUNCATE',
};

const _$TextCaseEnumMap = {
  TextCase.UPPER: 'UPPER',
  TextCase.LOWER: 'LOWER',
  TextCase.TITLE: 'TITLE',
  TextCase.SMALL_CAPS: 'SMALL_CAPS',
  TextCase.SMALL_CAPS_FORCED: 'SMALL_CAPS_FORCED',
};

AbsoluteBoundingBox _$AbsoluteBoundingBoxFromJson(Map<String, dynamic> json) =>
    AbsoluteBoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );

Map<String, dynamic> _$AbsoluteBoundingBoxToJson(
        AbsoluteBoundingBox instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'x': instance.x,
      'y': instance.y,
    };

AbsoluteRenderBounds _$AbsoluteRenderBoundsFromJson(
        Map<String, dynamic> json) =>
    AbsoluteRenderBounds(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AbsoluteRenderBoundsToJson(
        AbsoluteRenderBounds instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'x': instance.x,
      'y': instance.y,
    };

FigmaColor _$FigmaColorFromJson(Map<String, dynamic> json) => FigmaColor(
      r: (json['r'] as num).toDouble(),
      g: (json['g'] as num).toDouble(),
      b: (json['b'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
    );

Map<String, dynamic> _$FigmaColorToJson(FigmaColor instance) =>
    <String, dynamic>{
      'r': instance.r,
      'g': instance.g,
      'b': instance.b,
      'a': instance.a,
    };

FlowStartingPoints _$FlowStartingPointsFromJson(Map<String, dynamic> json) =>
    FlowStartingPoints(
      nodeId: json['nodeId'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$FlowStartingPointsToJson(FlowStartingPoints instance) =>
    <String, dynamic>{
      'nodeId': instance.nodeId,
      'name': instance.name,
    };

PrototypeDevice _$PrototypeDeviceFromJson(Map<String, dynamic> json) =>
    PrototypeDevice(
      type: json['type'] as String?,
      size: json['size'] == null
          ? null
          : FigmaSize.fromJson(json['size'] as Map<String, dynamic>),
      presetIdentifier: json['presetIdentifier'] as String?,
      rotation: json['rotation'] as String?,
    );

Map<String, dynamic> _$PrototypeDeviceToJson(PrototypeDevice instance) =>
    <String, dynamic>{
      'type': instance.type,
      'size': instance.size?.toJson(),
      'presetIdentifier': instance.presetIdentifier,
      'rotation': instance.rotation,
    };

FigmaSize _$FigmaSizeFromJson(Map<String, dynamic> json) => FigmaSize(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );

Map<String, dynamic> _$FigmaSizeToJson(FigmaSize instance) => <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
    };

FigmaComponents _$FigmaComponentsFromJson(Map<String, dynamic> json) =>
    FigmaComponents(
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ComponentStyle.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$FigmaComponentsToJson(FigmaComponents instance) =>
    <String, dynamic>{
      'properties': instance.properties?.map((k, e) => MapEntry(k, e.toJson())),
    };

ComponentStyle _$ComponentStyleFromJson(Map<String, dynamic> json) =>
    ComponentStyle(
      key: json['key'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      remote: json['remote'] as bool?,
      documentationLinks: json['documentationLinks'] as List<dynamic>?,
    );

Map<String, dynamic> _$ComponentStyleToJson(ComponentStyle instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'description': instance.description,
      'remote': instance.remote,
      'documentationLinks': instance.documentationLinks,
    };

ComponentSet _$ComponentSetFromJson(Map<String, dynamic> json) => ComponentSet(
      key: json['key'] as String?,
      fileKey: json['fileKey'] as String?,
      nodeId: json['nodeId'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$ComponentSetToJson(ComponentSet instance) =>
    <String, dynamic>{
      'key': instance.key,
      'fileKey': instance.fileKey,
      'nodeId': instance.nodeId,
      'thumbnailUrl': instance.thumbnailUrl,
      'name': instance.name,
      'description': instance.description,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

FigmaStyle _$FigmaStyleFromJson(Map<String, dynamic> json) => FigmaStyle(
      key: json['key'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      remote: json['remote'] as bool?,
      styleType:
          $enumDecodeNullable(_$FigmaStyleTypeEnumMap, json['styleType']),
    );

Map<String, dynamic> _$FigmaStyleToJson(FigmaStyle instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'description': instance.description,
      'remote': instance.remote,
      'styleType': _$FigmaStyleTypeEnumMap[instance.styleType],
    };

const _$FigmaStyleTypeEnumMap = {
  FigmaStyleType.FILL: 'FILL',
  FigmaStyleType.TEXT: 'TEXT',
  FigmaStyleType.EFFECT: 'EFFECT',
  FigmaStyleType.GRID: 'GRID',
};
