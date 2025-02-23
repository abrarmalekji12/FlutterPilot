import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/extension_util.dart';
import '../../components/component_impl.dart';
import '../../components/holder_impl.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/parameter_model.dart';
import '../../models/project_model.dart';
import '../../ui/paint_tools/paint_tools.dart';
import 'data/models/figma_file_response.dart';
import 'figma_analyzer.dart';
import 'figma_layout_generator.dart';
import 'property_converter.dart';

Map<String, String> imageScaleConvert = {
  'FILL': 'cover',
  'FIT': 'fitWidth',
  'TILE': 'contain',
  'STRETCH': 'fill',
};

class FigmaToFVBConverter {
  final FigmaPropertyConverter propertyConverter = FigmaPropertyConverter();

  List<Screen>? convert(
      FVBProject project, FigmaDocument? document, FigmaDocumentMeta? meta) {
    if (document == null) {
      return null;
    }
    final List<Screen> screens = [];
    for (final item in document.children!) {
      decodeChild(project, item, meta!, screens);
    }
    return screens;
  }

  decodeChild(FVBProject project, FigmaComponent child,
      FigmaDocumentMeta config, List<Screen> screens) {
    switch (child.type) {
      case FigmaNodeType.CANVAS:
        for (final FigmaComponent item in child.children ?? []) {
          if (item.type == FigmaNodeType.FRAME && (item.visible ?? true)) {
            item.children?.forEach((element) {
              checkForMask(element, item);
            });
            screens.add(Screen(
                item.name
                        ?.replaceAll('/', '_')
                        .replaceAll('(', '_')
                        .replaceAll('(', '_')
                        .camelCase ??
                    'N/A',
                DateTime.now(),
                project: project)
              ..rootComponent = decodeComponent(
                item,
                item,
                config,
                item.absoluteBoundingBox!,
              ));
          }
        }
        break;
      default:
        break;
    }
  }

  Component? decodeComponent(FigmaComponent component, FigmaComponent? parent,
      FigmaDocumentMeta config, Rect screenSize,
      {ConvertedComponent? child}) {
    if (component.visible == false) {
      return null;
    }
    if (component.useImage) {
      final image = CImage();
      (image.parameters[0] as ChoiceParameter)
          .update(1)
          .setCode(config.vectorNodesImages[component.id!]);

      /// Need to check if image is clipped, if it is, we need to clip it and used it.
      // final clipped = component.getClipped(screenSize);
      setDoubleParameter(
          image.parameters[1],
          component.absoluteRenderBounds?.width ??
              component.absoluteBoundingBox!.width,
          screenSize.size,
          true);
      setDoubleParameter(
          image.parameters[2],
          component.absoluteRenderBounds?.height ??
              component.absoluteBoundingBox!.height,
          screenSize.size,
          false);
      if ((component.fills?.isNotEmpty ?? false) &&
          component.fills!.first.color != null &&
          (component.fills!.first.visible ?? false)) {
        setColorParameter(
          image.parameters[3],
          component.fills!.first.color!,
          component.opacity ?? component.fills!.first.opacity,
        );
      }
      (image.parameters[4] as ChoiceValueParameter).update('contain');
      return image;
    }
    switch (component.type) {
      case FigmaNodeType.FRAME:
        ConvertedComponent? frameChild;
        if ((component.children?.where((e) => e.visible ?? true).length ?? 0) >
            1) {
          frameChild = buildLayout(component.absoluteBoundingBox!,
              component.children!, config, screenSize);
        } else if (component.children
                ?.where((e) => e.visible ?? true)
                .isNotEmpty ??
            false) {
          final child = decodeComponent(
              component.children!.first, component, config, screenSize);
          frameChild = ConvertedComponent(
              component: child, layout: Layout.self(component.children!.first));
        }
        return propertyConverter.applyFrameProperties(
          component,
          frameChild?.layout,
          frameChild?.component,
          screenSize.size,
          config,
        );

      case FigmaNodeType.COMPONENT ||
            FigmaNodeType.INSTANCE ||
            FigmaNodeType.GROUP:
        ConvertedComponent? frameChild;
        if ((component.children?.where((e) => e.visible ?? true).length ?? 0) >
            1) {
          frameChild = buildLayout(component.absoluteBoundingBox!,
              component.children!, config, screenSize);
        } else if (component.children
                ?.where((e) => e.visible ?? true)
                .isNotEmpty ??
            false) {
          final child = decodeComponent(
              component.children!.first, component, config, screenSize);
          frameChild = ConvertedComponent(
              component: child, layout: Layout.self(component.children!.first));
        }
        return propertyConverter.applyFrameProperties(
          component,
          frameChild?.layout,
          frameChild?.component,
          screenSize.size,
          config,
        );

      case FigmaNodeType.RECTANGLE:
        final container = CContainer();
        // container.child = CText(text: component.name ?? '');
        if (component.fills != null)
          propertyConverter.applyFills(
              component, component.fills!, container, config);

        if (component.strokes != null)
          propertyConverter.applyStrokes(
              component, component.strokes!, container);
        propertyConverter.applyRadius(component, container);
        if (child != null) {
          addContainerChild(
              component, container, child.component!, child.layout!);
        }
        if (component.absoluteRenderBounds != null) {
          setDoubleParameter(container.parameters[1],
              component.absoluteRenderBounds!.width, screenSize.size, true);
          setDoubleParameter(container.parameters[2],
              component.absoluteRenderBounds!.height, screenSize.size, false);
        }
        return container;
      case FigmaNodeType.LINE:
        if (component.strokeDashes?.isNotEmpty ?? false) {
          final line = CDashedLine();
          final isHorizontal = component.absoluteRenderBounds!.width >
              component.absoluteRenderBounds!.height;
          setDoubleParameter(
              line.parameters[0],
              component.absoluteRenderBounds!.width,
              screenSize.size,
              !isHorizontal ? null : true);
          setDoubleParameter(
              line.parameters[1],
              component.absoluteRenderBounds!.height,
              screenSize.size,
              isHorizontal ? null : false);
          (line.parameters[2] as ChoiceValueParameter).update(
            isHorizontal ? 'horizontal' : 'vertical',
          );
          if (component.strokes?.isNotEmpty ?? false) {
            setColorParameter(
              line.parameters[3],
              component.strokes!.first.color,
              component.strokes!.first.opacity ?? component.opacity,
            );
          }

          setDoubleParameter(line.parameters[4], component.strokeDashes![0],
              screenSize.size, null);
          if (component.strokeDashes!.length > 1) {
            setDoubleParameter(line.parameters[5], component.strokeDashes![1],
                screenSize.size, null);
          }
          return line;
        } else {
          if (component.absoluteBoundingBox!.height <
              component.absoluteBoundingBox!.width) {
            final line = CDivider();
            if (component.strokes?.isNotEmpty ?? false) {
              setColorParameter(
                line.parameters[0],
                component.strokes!.first.color,
                component.opacity ?? component.strokes!.first.opacity,
              );
            }
            if (component.strokeWeight != null)
              setDoubleParameter(line.parameters[2], component.strokeWeight,
                  screenSize.size, null);
            setDoubleParameter(line.defaultParam[0]!,
                component.absoluteBoundingBox!.width, screenSize.size, true);
            setDoubleParameter(line.parameters[1],
                component.absoluteBoundingBox!.height, screenSize.size, false);
            return line;
          } else {}
        }

        break;
      case FigmaNodeType.ELLIPSE:
        final container = CContainer();
        setDoubleParameter(container.parameters[1],
            component.absoluteRenderBounds!.width, screenSize.size, true);
        setDoubleParameter(container.parameters[2],
            component.absoluteRenderBounds!.height, screenSize.size, false);
        ((container.parameters[5] as ComplexParameter).params[5]
                as ChoiceValueParameter)
            .val = 'circle';
        (container.parameters[6] as ChoiceValueParameter).val = 'hardEdge';
        if (component.fills != null)
          propertyConverter.applyFills(
              component, component.fills!, container, config);

        if (child != null) {
          addContainerChild(
              component, container, child.component!, child.layout!);
        }

        if (component.strokes != null)
          propertyConverter.applyStrokes(
              component, component.strokes!, container);
        propertyConverter.applyRadius(component, container);
        if (component.masking?.isNotEmpty ?? false) {
          final comp = buildLayout(component.absoluteBoundingBox!,
              component.masking!, config, screenSize);
          (container.parameters[6] as ChoiceValueParameter).update('hardEdge');
          propertyConverter.computePadding(
            component.absoluteBoundingBox!,
            comp.layout!.box,
            container.parameters[0] as ChoiceParameter,
            screenSize.size,
          );
          container.updateChild(comp.component!);
        }

        // for (final child in parent.children!.where((element) => element != component)) {
        //
        // }

        return container;
      // final paint = CCustomPaint();
      // final box = component.absoluteBoundingBox!;
      // paint.paintObjects.addAll(booleanUnion(component));
      // (paint.parameters[1] as ComplexParameter).params[0].setCode(box.width.toStringAsFixed(1));
      // (paint.parameters[1] as ComplexParameter).params[1].setCode(box.height.toStringAsFixed(1));
      // return paint;
      case FigmaNodeType.TEXT:
        //  (param.params[1] as ComplexParameter).params[1].compiler.code='Color(0xff${child.fills!})';
        return propertyConverter.applyTextProperties(
            component, screenSize.size);
      default:
        print('FIGMA TYPE ${component.type?.name}');
        break;
    }
    return null;
  }

  List<FVBPaintObj> booleanUnion(FigmaComponent component) {
    final box = component.absoluteBoundingBox!;
    final List<FVBPaintObj> list = [];
    for (final FigmaComponent comp in component.children ?? []) {
      FVBPaintObj? obj;

      switch (comp.type) {
        case FigmaNodeType.BOOLEAN_OPERATION:
          list.addAll(booleanUnion(comp));
          break;

        case FigmaNodeType.ELLIPSE:
          /*
           color: parameters[0].value,
        filled: parameters[1].value,
        strokeWidth: parameters[2].value,
        width: parameters[5].value,
        height: parameters[6].value,
        angle: parameters[7].value,
          */
          obj = CircleObj();
          if (comp.fills?.isNotEmpty ?? false) {
            obj.parameters[0].value =
                propertyConverter.convertColor(comp.fills!.first.color!);
            obj.parameters[1].value = false;
          }
          if (comp.strokes?.isNotEmpty ?? false) {
            if (comp.strokes!.first.visible ?? true) {
              obj.parameters[0].value =
                  propertyConverter.convertColor(comp.strokes!.first.color!);
            }
          }
          obj.parameters[3].value = (comp.absoluteBoundingBox!.left) - box.x;
          obj.parameters[4].value = comp.absoluteBoundingBox!.top - box.y;
          obj.parameters[5].value = comp.absoluteBoundingBox!.width;
          obj.parameters[6].value = comp.absoluteBoundingBox!.height;
          obj.parameters[7].value =
              (comp.rotation != null ? -comp.rotation! : 0.0).toDegree;
          break;
        case FigmaNodeType.RECTANGLE:
          /*
              color: parameters[0].value,
              filled: parameters[1].value,
              strokeWidth: parameters[2].value,
              width: parameters[5].value,
              height: parameters[6].value,
              rotation: parameters[7].value,
              radius: parameters[8].value ?? 0)
              * */
          obj = RectObj();
          if (comp.fills?.isNotEmpty ?? false) {
            obj.parameters[0].value =
                propertyConverter.convertColor(comp.fills!.first.color!);
            obj.parameters[1].value = true;
          }
          if (comp.strokes?.isNotEmpty ?? false) {
            if (comp.strokes!.first.visible ?? true) {
              obj.parameters[0].value =
                  propertyConverter.convertColor(comp.strokes!.first.color!);
            }
          }
          obj.parameters[3].value = (comp.absoluteBoundingBox!.left) - box.x;
          obj.parameters[4].value = comp.absoluteBoundingBox!.top - box.y;
          obj.parameters[5].value = comp.absoluteBoundingBox!.width;
          obj.parameters[6].value = comp.absoluteBoundingBox!.height;
          obj.parameters[7].value =
              (comp.rotation != null ? -comp.rotation! : 0.0).toDegree;
          obj.parameters[8].value = comp.cornerRadius ?? 0.0;
          break;

        case FigmaNodeType.VECTOR:
          /*
              color: parameters[0].value,
              filled: parameters[1].value,
              strokeWidth: parameters[2].value,
              width: parameters[5].value,
              height: parameters[6].value,
              rotation: parameters[7].value,
              radius: parameters[8].value ?? 0)
              * */
          obj = RectObj();
          if (comp.fills?.isNotEmpty ?? false) {
            obj.parameters[0].value =
                propertyConverter.convertColor(comp.fills!.first.color!);
            obj.parameters[1].value = true;
          }
          obj.parameters[3].value = comp.absoluteBoundingBox!.left - box.x;
          obj.parameters[4].value = comp.absoluteBoundingBox!.top - box.y;
          obj.parameters[5].value = comp.absoluteBoundingBox!.width;
          obj.parameters[6].value = comp.absoluteBoundingBox!.height;
          obj.parameters[7].value =
              (comp.rotation != null ? comp.rotation! : 0.0).toDegree;
          obj.parameters[8].value = comp.cornerRadius ?? 0.0;
        default:
          break;
      }
      if (obj != null) list.add(obj);
    }
    return list;
  }

  final generator = FigmaLayoutGenerator();

  ConvertedComponent buildLayout(AbsoluteBoundingBox box,
      List<FigmaComponent> children, FigmaDocumentMeta meta, Rect size) {
    return generator.generateV2(box, children, meta, size);
  }

  List<FigmaComponent>? checkForMask(
      FigmaComponent comp, FigmaComponent parent) {
    if (comp.isMask) {
      comp.masking =
          parent.children?.where((element) => element != comp).toList();
      comp.isMask = false;
      return parent.children?.where((element) => element != comp).toList();
    } else if (comp.children != null) {
      List<FigmaComponent> list = [];
      comp.children!.forEach((element) {
        list.addAll(checkForMask(element, comp) ?? []);
      });
      if (list.isNotEmpty) {
        comp.children?.removeWhere((element) => list.contains(element));
      }
    }
    return null;
  }

  void addContainerChild(FigmaComponent component, CContainer container,
      Component component2, Layout layout) {
    container.updateChild(component2);
    final align = propertyConverter.applyAlignment(
        component.absoluteBoundingBox!, layout.box);
    (container.parameters[4] as ChoiceValueParameter).update(align);
  }
}
