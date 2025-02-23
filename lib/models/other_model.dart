import 'dart:typed_data';
import 'dart:ui';

import '../data/remote/firestore/firebase_bridge.dart';
import 'fvb_ui_core/component/component_model.dart';
import 'fvb_ui_core/component/custom_component.dart';

class FVBImage {
  Uint8List? bytes;
  String? id;

  String? name;
  String? path;

  FVBImage({this.bytes, this.name, this.id, this.path});

  @override
  String toString() {
    return name != null ? '\'$name\'' : '';
  }

  toJson() {
    return {'id': id, 'name': name!, 'path': path};
  }

  factory FVBImage.fromJson(Map<String, dynamic> json) {
    // if (json['bytes'] != null) {
    //   return FVBImage(base64Decode(json['bytes']), json['img_name']);
    // }
    // Uint8List list=Uint8List.fromList([]);
    // for(int i=0;json['bytes$i']!=null;i++){
    //   list.addAll(base64Decode(json['bytes$i']));
    // }
    return FVBImage(
      name: json['name'] ?? '',
      id: json['id'],
      path: json['path'],
    );
  }
}

class FavouriteModel {
  late Component component;
  final String projectId;
  final List<CustomComponent> components;
  final DateTime? createdAt;
  String? id;
  final String userId;

  FavouriteModel(
    this.component,
    this.components,
    this.createdAt, {
    this.id,
    required this.userId,
    this.projectId = '',
  });

  factory FavouriteModel.fromJson(
      List<CustomComponent> customComponents, Map<String, dynamic> json) {
    return FavouriteModel(
      Component.fromJson(json['code'], null, customs: customComponents)
        ..boundary = Rect.fromLTWH(
            0.0,
            0.0,
            double.parse(json['width'].toString()),
            double.parse(json['height'].toString())),
      customComponents,
      FirebaseDataBridge.timestampToDate(
        json['createdAt'],
      ),
      id: json['id'],
      userId: json['userId'],
      projectId: json['projectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': component.toJson(),
      'id': id,
      'userId': userId,
      'projectId': projectId,
      'width': component.boundary!.width,
      'height': component.boundary!.height,
      'customComponents':
          components.map((e) => e.toMainJson()).toList(growable: false),
      'createdAt': FirebaseDataBridge.timestamp(DateTime.now())
    };
  }
}
