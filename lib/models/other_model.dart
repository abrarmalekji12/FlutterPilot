import 'dart:typed_data';

class ImageData {
  Uint8List? bytes;

  String? imagePath;

  ImageData(this.bytes,this.imagePath);
  @override
  String toString() {
    return imagePath!=null?'\'$imagePath\'':'';
  }
}
