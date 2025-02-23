import '../data/remote/firestore/firebase_bridge.dart';
import 'common_mixins.dart';
import 'fvb_ui_core/component/custom_component.dart';
import 'other_model.dart';
import 'project_model.dart';
import 'variable_model.dart';

class TemplateModel with ImageExtractor, CustomComponentExtractor {
  final Screen screen;
  final List<CustomComponent> customComponents = [];
  final String name;
  final String? description;
  final String publisherId;
  final List<FVBImage> images = [];
  final List<VariableModel> variables;
  final String device;
  String? timeStamp;
  final String id;
  final DateTime createdAt;

  TemplateModel(
    this.screen,
    this.variables,
    this.name,
    this.description,
    this.publisherId,
    this.createdAt, {
    this.timeStamp,
    required this.id,
    this.device = 'iPhone X',
  });

  List<FVBImage> get extractedImages {
    final List<FVBImage> images = [];
    extractImages(screen.rootComponent!, images);
    for (final component in customComponents)
      extractImages(component.rootComponent!, images);
    return images;
  }

  List<CustomComponent> get extractedCustoms {
    final List<CustomComponent> list = [];
    extractCustomComponents(screen.rootComponent!, list);
    for (final component in customComponents)
      extractCustomComponents(component.rootComponent!, list);
    return list;
  }

  Map<String, dynamic> toJson() {
    this.timeStamp = timeStamp;
    return {
      'screen': screen.toJson(),
      'customComponents':
          customComponents.map((e) => e.toMainJson()).toList(growable: false),
      'name': name,
      'id': id,
      'description': description,
      'publisherId': publisherId,
      'images': images.map((e) => e.toJson()).toList(growable: false),
      'variables': variables.map((e) => e.toJson()).toList(growable: false),
      'createdAt': FirebaseDataBridge.timestamp(createdAt)
    };
  }

  factory TemplateModel.fromJson(
      Map<String, dynamic> json, final List<VariableModel> variables) {
    return TemplateModel(
        Screen.fromJson(json['screen'], parentVars: variables),
        variables,
        json['name'],
        json['description'],
        json['publisherId'],
        FirebaseDataBridge.timestampToDate(json['createdAt'])!,
        id: json['id'])
      ..images.addAll(List.from(json['images'] ?? [])
          .map((image) => FVBImage.fromJson(image))
          .toList(growable: false));
  }
}
