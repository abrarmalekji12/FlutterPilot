import 'dart:ui';

import 'data/models/figma_file_response.dart';
import 'data/models/figma_files_image_response.dart';

class FigmaDocumentConfiguration {
  final List<FigmaImageNode> vectorNodes = [];
}

class FigmaImageNode {
  final String id;
  final Rect box;

  FigmaImageNode(this.id, this.box);
}

class FigmaImageNodeResponse {
  final String url;
  final Rect box;
  final Rect? clippedBox;

  FigmaImageNodeResponse(this.url, this.box, this.clippedBox);
}

class FigmaDocumentMeta {
  final Map<String, String> vectorNodesImages;
  FigmaFilesImageResponse? images;

  FigmaDocumentMeta({required this.vectorNodesImages, this.images});
}

class FigmaAnalyzer {
  FigmaDocumentConfiguration analyzeConfiguration(FigmaFileResponse response) {
    final FigmaDocumentConfiguration _figmaFileConfig =
        FigmaDocumentConfiguration();
    response.document!.children!.forEach((element) {
      analyzeComponent(element, _figmaFileConfig, Rect.zero);
    });
    return _figmaFileConfig;
  }

  void analyzeComponent(
    FigmaComponent component,
    FigmaDocumentConfiguration configuration,
    Rect rect,
  ) {
    if (component.useImage) {
      configuration.vectorNodes
          .add(FigmaImageNode(component.id!, component.absoluteBoundingBox!));
    } else {
      if (component.children != null) {
        component.children!.forEach((element) {
          analyzeComponent(
              element,
              configuration,
              component.type == FigmaNodeType.CANVAS
                  ? element.absoluteBoundingBox!
                  : rect);
        });
      }
    }
  }
}
