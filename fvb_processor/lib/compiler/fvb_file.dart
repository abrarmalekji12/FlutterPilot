import 'package:get/get.dart';

abstract class FVBPath {
  final String name;
  FVBDirectory? parent;

  FVBPath(this.name);
  String get path => parent == null ? name : '${parent!.path}/$name';

  FVBPath? findFolder(String p) {
    if (this is FVBDirectory) {
      return (this as FVBDirectory)
          .folders
          .firstWhereOrNull((e) => e.name == p);
    }
    return null;
  }

  FVBPath? findFile(String p) {
    if (this is FVBDirectory) {
      return (this as FVBDirectory).files.firstWhereOrNull((e) => e.name == p);
    }
    return null;
  }
}

class FVBFile extends FVBPath {
  String? code;

  FVBFile(super.name, this.code);
}

class FVBDirectory extends FVBPath {
  List<FVBFile> files;
  List<FVBDirectory> folders;

  FVBDirectory(super.name, this.files, this.folders) {
    for (final element in files) {
      element.parent = this;
    }
    for (final element in folders) {
      element.parent = this;
    }
  }
}
