import 'dart:typed_data';

class ImageData {
  Uint8List? bytes;
  String? imageName;

  String? imagePath;

  ImageData(this.bytes,this.imagePath,this.imageName);
  @override
  String toString() {
    return imagePath??'';
  }
}
