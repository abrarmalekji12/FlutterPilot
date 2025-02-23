import 'dart:ui';

import 'package:flutter_builder/mode_converters/figma/data/models/figma_file_response.dart';
import 'package:flutter_builder/mode_converters/figma/data/models/figma_files_image_response.dart';
import 'package:flutter_builder/mode_converters/figma/figma_analyzer.dart';
import 'package:flutter_builder/mode_converters/figma/figma_layout_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Checking figma layout generator', () {
    final FigmaLayoutGenerator generator = FigmaLayoutGenerator();
    generator.generateV2(
        const Rect.fromLTWH(0, 0, 500, 800),
        [
          FigmaComponent(
            absoluteBoundingBox:
                AbsoluteBoundingBox(x: 0, y: 0, width: 100, height: 100),
          ),
          FigmaComponent(
            absoluteBoundingBox:
                AbsoluteBoundingBox(x: 100, y: 0, width: 150, height: 50),
          ),
          FigmaComponent(
            absoluteBoundingBox:
                AbsoluteBoundingBox(x: 100, y: 70, width: 30, height: 30),
          ),
          FigmaComponent(
            absoluteBoundingBox:
                AbsoluteBoundingBox(x: 140, y: 70, width: 50, height: 30),
          ),
          FigmaComponent(
            absoluteBoundingBox:
                AbsoluteBoundingBox(x: 350, y: 0, width: 40, height: 40),
          ),
        ],
        FigmaDocumentMeta(
            vectorNodesImages: {}, images: FigmaFilesImageResponse()),
        const Rect.fromLTWH(0, 0, 300, 800));
  });

  test('Checking figma layout generator - stack list 1', () {
    final FigmaLayoutGenerator generator = FigmaLayoutGenerator();
    generator.generateV2(
        const Rect.fromLTWH(0, 0, 500, 800),
        [
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 0, y: 0, width: 100, height: 100),
              name: '0'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 100, y: 0, width: 150, height: 50),
              name: '1'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 100, y: 70, width: 30, height: 30),
              name: '2'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 140, y: 70, width: 50, height: 30),
              name: '3'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 350, y: 0, width: 40, height: 40),
              name: '4'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 80, y: 0, width: 20, height: 20),
              name: '5'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 140, y: 0, width: 230, height: 10),
              name: '6'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 0, y: 0, width: 500, height: 400),
              name: 'background'),
        ],
        FigmaDocumentMeta(
            vectorNodesImages: {}, images: FigmaFilesImageResponse()),
        const Rect.fromLTWH(0, 0, 300, 800));
  });

  test('Checking figma layout generator - stack list 2', () {
    final FigmaLayoutGenerator generator = FigmaLayoutGenerator();
    generator.generateV2(
        const Rect.fromLTWH(0, 0, 500, 800),
        [
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 0, y: 0, width: 300, height: 30),
              name: '0'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 110, y: 35, width: 50, height: 50),
              name: '1'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 200, y: 35, width: 50, height: 50),
              name: '2'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 110, y: 90, width: 50, height: 50),
              name: '3'),
          FigmaComponent(
              absoluteBoundingBox:
                  AbsoluteBoundingBox(x: 0, y: 35, width: 100, height: 120),
              name: '4'),
          // FigmaChild(
          //   absoluteBoundingBox: AbsoluteBoundingBox(x: 80, y: 0, width: 20, height: 20),
          //   name: '5'
          // ),
          // FigmaChild(absoluteBoundingBox: AbsoluteBoundingBox(x: 0, y: 0, width: 500, height: 400), name: 'background'),
        ],
        FigmaDocumentMeta(
          vectorNodesImages: {},
          images: FigmaFilesImageResponse(),
        ),
        const Rect.fromLTWH(0, 0, 300, 800));
  });
}
