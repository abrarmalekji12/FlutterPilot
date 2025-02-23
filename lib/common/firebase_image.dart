import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../data/remote/firestore/firebase_lib.dart';
import '../injector.dart';
import 'extension_util.dart';

class FirebaseImage extends StatelessWidget {
  final String path;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Function(Uint8List)? onLoaded;
  final ImageErrorWidgetBuilder? errorBuilder;

  const FirebaseImage(this.path,
      {Key? key,
      this.errorBuilder,
      this.width,
      this.height,
      this.color,
      this.fit = BoxFit.contain,
      this.alignment = Alignment.center,
      this.onLoaded})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: ColorAssets.grey,
        alignment: Alignment.center,
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        color: color,
        fit: fit,
        alignment: alignment,
        errorBuilder: errorBuilder,
      );
    }

    if (byteCache.containsKey(path)) {
      onLoaded?.call(byteCache[path]!);
      return Image.memory(
        byteCache[path]!,
        width: width,
        height: height,
        color: color,
        fit: fit,
        errorBuilder: errorBuilder,
        alignment: alignment,
      );
    }

    return FutureBuilder<Uint8List?>(
      builder: (context, value) {
        if (value.hasData && value.data != null && value.data!.isNotEmpty) {
          onLoaded?.call(value.data!);
          return Image.memory(
            value.data!,
            width: width,
            height: height,
            color: color,
            fit: fit,
            alignment: alignment,
          );
        }

        if (value.connectionState == ConnectionState.done) {
          if (value.error == null) {
            return const Offstage();
          }
          if (errorBuilder != null) {
            return errorBuilder!.call(context, value.error!, value.stackTrace);
          }
          return FVBImageNetworkError(
            width: width,
            height: height,
            path: path,
          );
        }
        return Center(
          child: Container(
            width: width,
            height: height,
            color: ColorAssets.grey,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: ColorAssets.theme,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
      future: getBytesFromStorage(path),
    );
  }
}

Future<Uint8List?> getBytesFromStorage(String path) async {
  if (byteCache.containsKey(path)) {
    return byteCache[path];
  }
  if (path.startsWith('http') || !path.contains('/')) {
    return null;
  }
  try {
    final FirebaseStorage firebaseStorage = sl<FirebaseStorage>();
    final Uint8List? imageBytes =
        await firebaseStorage.ref().child(path).getData();
    if (imageBytes != null) {
      byteCache[path] = imageBytes;
    }
    return imageBytes;
  } catch (e) {
    debugPrint(e.toString());
  }
  return null;
}

class FVBImageNetworkError extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;

  const FVBImageNetworkError(
      {super.key, required this.path, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final double f = width != null ? min(max(width! / 6.9, 12), 18) : 12;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: ColorAssets.lightGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorAssets.red, width: 1),
      ),
      height: height,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: ColorAssets.red,
            size: f * 1.2,
          ),
          max(f / 2, 10).wBox,
          Flexible(
              child: Text(
            'Invalid Image "${path}"',
            style: AppFontStyle.lato(f, color: ColorAssets.red),
          )),
        ],
      ),
    );
  }
}
