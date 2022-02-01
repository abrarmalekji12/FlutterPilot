import 'dart:typed_data';

import 'component_model.dart';

class ImageData {
  Uint8List? bytes;

  String? imageName;

  ImageData(this.bytes,this.imageName);
  @override
  String toString() {
    return imageName!=null?'\'$imageName\'':'';
  }
}
class FavouriteModel{
  final Component component;
  final String projectName;

  FavouriteModel(this.component, this.projectName);
}
