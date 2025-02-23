import 'dart:convert';

import 'fvb_ui_core/component/component_model.dart';
import 'fvb_ui_core/component/custom_component.dart';

class GlobalComponentModel {
  final String name;
  final String? description;
  final String? category;
  final String publisherId;
  final String publisherName;
  bool isCustom = true;
  final List<String>? platforms;
  late final Component component;
  final List<CustomComponent> customs;
  final num? width;
  final num? height;
  String? id;

  GlobalComponentModel(
      {required this.name,
      this.description,
      required this.customs,
      this.category,
      dynamic code,
      this.id,
      required this.publisherId,
      required this.publisherName,
      required this.width,
      required this.height,
      Component? comp,
      this.platforms}) {
    if (comp != null) {
      this.component = comp;
    }
    if (code != null) {
      isCustom = false;
      if (code is Map) {
        component = Component.fromJson(code, null, customs: customs);
      } else if (code is String) {
        component =
            Component.fromJson(jsonDecode(code), null, customs: customs);
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'component': valueFromType,
      'publisherId': publisherId,
      'publisherName': publisherName,
      'isCustom': isCustom,
      'customs': customs.map((e) => e.toMainJson()).toList(growable: false),
      'platforms': platforms,
      'width': width,
      'height': height,
      'id': id
    };
  }

  get valueFromType {
    if (component is! CustomComponent) {
      return component.toJson();
    } else {
      return (component as CustomComponent).toMainJson();
    }
  }

  Component componentFromData(data) {
    if (data is! String && data['type'] != null) {
      return CustomComponent.fromJson(data);
    }
    return Component.fromJson(data, null, customs: customs);
  }

  factory GlobalComponentModel.fromJson(Map<String, dynamic> json) {
    final model = GlobalComponentModel(
        name: json['name'],
        description: json['description'],
        publisherId: json['publisherId'],
        publisherName: json['publisherName'],
        category: json['category'],
        platforms: json['platforms'],
        customs: [],
        width: json['width'],
        height: json['height']);
    model.customs.addAll(
      (List.from(json['customs'] ?? []).map(
        (e) => CustomComponent.fromJson(e),
      )),
    );
    for (int i = 0; i < model.customs.length; i++) {
      model.customs[i].rootComponent = Component.fromJson(
          json['customs'][i]['code'], null,
          customs: model.customs);
    }
    model.component = model.componentFromData(json['component']);
    if (model.component is CustomComponent) {
      (model.component as CustomComponent).rootComponent = Component.fromJson(
          json['component']['code'], null,
          customs: model.customs);
    }
    return model;
  }
}
