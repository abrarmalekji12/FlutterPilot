import 'dart:math';
import 'dart:ui';

import 'package:get/get.dart';

import '../../components/component_impl.dart';
import '../../components/holder_impl.dart';
import '../../components/scrollable_impl.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/parameter_model.dart';
import 'data/models/figma_file_response.dart';
import 'figma_analyzer.dart';
import 'figma_layout_generator.dart';
import 'figma_to_fvb_converter.dart';

class FigmaPropertyConverter {
  applyPadding(ChoiceParameter param, double? left, double? top, double? right,
      double? bottom, Size size) {
    final complex = param.update(param.options.length - 2) as ComplexParameter;
    setDoubleParameter(complex.params[0], top, size, false);
    setDoubleParameter(complex.params[1], left, size, true);
    setDoubleParameter(complex.params[2], bottom, size, false);
    setDoubleParameter(complex.params[3], right, size, true);
  }

  computePadding(
      Rect parentBox, Rect childBox, Parameter parameter, Size size) {
    double? l, r, t, b;
    if (childBox.left - parentBox.left >= 1) {
      l = childBox.left - parentBox.left - 1;
    }
    if (parentBox.right - childBox.right >= 1) {
      r = parentBox.right - childBox.right - 1;
    }
    if (childBox.top - parentBox.top >= 1) {
      t = childBox.top - parentBox.top - 1;
    }
    if (parentBox.bottom - childBox.bottom >= 1) {
      b = parentBox.bottom - childBox.bottom - 1;
    }
    if (l != null || r != null || t != null || b != null) {
      applyPadding(parameter as ChoiceParameter, l, t, r, b, size);
    }
  }

  String applyAlignment(Rect parentBox, Rect childBox) {
    final leftA = (parentBox.left - childBox.left).abs();
    final rightA = (parentBox.right - childBox.right).abs();
    final topA = (parentBox.top - childBox.top).abs();
    final bottomA = (parentBox.bottom - childBox.bottom).abs();
    String horizontal = (leftA - rightA).abs() <= min(leftA, rightA)
        ? 'center'
        : (leftA < rightA ? 'left' : 'right');
    String vertical = (topA - bottomA).abs() <= min(topA, bottomA)
        ? 'center'
        : (topA < bottomA ? 'top' : 'bottom');
    if (horizontal == vertical) {
      return 'center';
    }
    return '$vertical${horizontal.capitalizeFirst}';
  }

  applyStrokes(
      FigmaComponent component, List<FigmaFill> strokes, CContainer container) {
    if (strokes.isNotEmpty) {
      (((container.parameters[5] as ComplexParameter).params[2]
              as ChoiceParameter)
          .update(1) as ComplexParameter)
        ..params[0].setCode(convertColorToFVB(strokes.first.color!,
            opacity: strokes.first.opacity ?? component.opacity))
        ..params[1].setCode('');
    }
  }

  applyRadius(FigmaComponent component, CContainer container) {
    if (component.cornerRadius != null) {
      ((container.parameters[5] as ComplexParameter).params[1]
              as ChoiceParameter)
          .update(1)
          .setCode(component.cornerRadius?.toStringAsFixed(2));
    }
  }

  applyFills(FigmaComponent component, List<FigmaFill> fills,
      CContainer container, FigmaDocumentMeta config) {
    if (fills.isNotEmpty) {
      switch (fills.first.type) {
        case FigmaPaint.SOLID:
          (container.parameters[5] as ComplexParameter).params[0].setCode(
              convertColorToFVB(fills.first.color!,
                  opacity: fills.first.opacity ?? component.opacity));
          break;
        case FigmaPaint.GRADIENT_LINEAR:
          final linearGradient = ((container.parameters[5] as ComplexParameter)
                  .params[3] as ChoiceParameter)
              .update(1) as ComplexParameter;
          (linearGradient.params[0] as ListParameter).params.clear();
          (linearGradient.params[0] as ListParameter).params.addAll(
                fills.first.gradientStops!.map(
                  (e) => (linearGradient.params[0] as ListParameter)
                      .parameterGenerator()
                    ..setCode(convertColorToFVB(e.color!)),
                ),
              );
          // component.fills!.first.gradientHandlePositions!
          // (linearGradient.params[1] as ChoiceValueParameter).update( );
          // (linearGradient.params[2] as ChoiceValueParameter).update();
          (linearGradient.params[3] as ListParameter)
            ..params.clear()
            ..params.addAll(
              fills.first.gradientStops!.map((e) =>
                  (linearGradient.params[3] as ListParameter)
                      .parameterGenerator()
                    ..setCode(
                      e.position?.toStringAsFixed(2),
                    )),
            );
          break;
        case FigmaPaint.GRADIENT_RADIAL:
          // TODO: Handle this case.
          break;
        case FigmaPaint.GRADIENT_ANGULAR:
          // TODO: Handle this case.
          break;
        case FigmaPaint.GRADIENT_DIAMOND:
          // TODO: Handle this case.
          break;
        case FigmaPaint.IMAGE:
          final image = CImage();

          ((image.parameters[0] as ChoiceParameter).update(1)
                  as SimpleParameter)
              .setCode(config.images!.meta!.images[fills[0].imageRef!]!);
          if (fills[0].scaleMode != null)
            (image.parameters[4] as ChoiceValueParameter).val =
                imageScaleConvert[fills[0].scaleMode];
          container.updateChild(image);
          break;
        case FigmaPaint.EMOJI:
          // TODO: Handle this case.
          break;
        case FigmaPaint.VIDEO:
          // TODO: Handle this case.
          break;
        default:
          break;
      }
    }
  }

  Component applyFrameProperties(FigmaComponent comp, Layout? childLayout,
      Component? child, Size size, FigmaDocumentMeta config) {
    Component component = (CContainer()..updateChild(child));
    // if (childLayout?.type == LayoutType.horizontal || childLayout?.type == LayoutType.vertical) {
    //   final vertical = childLayout!.type == LayoutType.vertical;
    //   component = CSizedBox()
    //     ..parameters[0].setCode(
    //       vertical ? comp.absoluteBoundingBox!.width.toStringAsFixed(2) : null,
    //     ).
    //     ..parameters[1].setCode(
    //       !vertical ? comp.absoluteBoundingBox!.height.toStringAsFixed(2) : null,
    //     )
    //     ..child = child;
    // }
    if (comp.fills != null)
      applyFills(comp, comp.fills!, component as CContainer, config);

    if (comp.strokes != null)
      applyStrokes(comp, comp.strokes!, component as CContainer);
    applyRadius(comp, component as CContainer);
    if (comp.backgroundColor != null) {
      (component.parameters[5] as ComplexParameter)
          .params[0]
          .setCode(convertColorToFVB(comp.backgroundColor!));
    }
    final childBox = childLayout?.box;
    // setDoubleParameter(component.parameters[0], comp.absoluteBoundingBox!.width, size, true);
    // setDoubleParameter(component.parameters[1], comp.absoluteBoundingBox!.height, size, false);
    if (childBox != null) {
      final parentBox = comp.absoluteBoundingBox!;
      computePadding(parentBox, childBox, component.parameters[0], size);
    }
    if (comp.scrollBehavior == 'SCROLLS' &&
        childBox != null &&
        (childBox.width > comp.absoluteBoundingBox!.width ||
            childBox.height > comp.absoluteBoundingBox!.height)) {
      final scrollView = CSingleChildScrollView()..updateChild(component);
      (scrollView.parameters[0] as ChoiceValueParameter).update(
          comp.absoluteBoundingBox!.width < comp.absoluteBoundingBox!.height
              ? 'vertical'
              : 'horizontal');
      return scrollView;
    }
    return component;
  }

  CText applyTextProperties(FigmaComponent child, Size size) {
    final text = CText(text: child.characters?.replaceAll('\$', '\\\$'));
    final param = (text.parameters[1] as ComplexParameter);
    param.enable = true;
    final i = (param.params[0] as ChoiceValueListParameter)
        .options
        .indexWhere((element) => element == child.style!.fontFamily);
    if (i != -1) {
      (param.params[0] as ChoiceValueListParameter).val = i;
    }
    if ((child.fills?.isNotEmpty ?? false) &&
        child.fills!.first.color != null) {
      (param.params[1] as ComplexParameter).params[1].setCode(
          convertColorToFVB(child.fills!.first.color!, opacity: child.opacity));
    }
    if (child.style != null) {
      if (child.style!.textCase != null) {
        final value = text.parameters[0].compiler.code.toUpperCase();
        final String output;
        switch (child.style!.textCase!) {
          case TextCase.UPPER:
            output = value.toUpperCase();
            break;
          case TextCase.LOWER:
            output = value.toLowerCase();
            break;
          case TextCase.TITLE:
            output = value;
            break;
          case TextCase.SMALL_CAPS:
            output = value.toUpperCase();

            break;
          case TextCase.SMALL_CAPS_FORCED:
            output = value.toUpperCase();

            break;
          default:
            output = value;
        }
        text.parameters[0].setCode(output);
      }
      if (child.style!.textAlignHorizontal != null) {
        (text.parameters[2] as ChoiceValueParameter).update(
            convertTextHorizontalAlign(child.style!.textAlignHorizontal!));
        setDoubleParameter(text.defaultParam[0]!,
            child.absoluteBoundingBox!.width, size, null);
      }
    }
    setDoubleParameter((param.params[1] as ComplexParameter).params[0],
        child.style!.fontSize, size, null);
    ((param.params[1] as ComplexParameter).params[2] as ChoiceValueParameter)
        .val = 'w${child.style!.fontWeight!}';
    return text;
  }

  Color convertColor(FigmaColor c) {
    return Color.fromARGB((c.a * 255).toInt(), (c.r * 255).toInt(),
        (c.g * 255).toInt(), (c.b * 255).toInt());
  }

  String? convertTextHorizontalAlign(String alignment) {
    switch (alignment) {
      case 'LEFT':
        return 'left';
      case 'RIGHT':
        return 'right';
      case 'CENTER':
        return 'center';
      case 'JUSTIFIED':
        return 'justify';
      default:
        return null;
    }
  }

  String convertColorToFVB(FigmaColor c, {double? opacity}) {
    Color color = Color.fromARGB((c.a * 255).toInt(), (c.r * 255).toInt(),
        (c.g * 255).toInt(), (c.b * 255).toInt());
    if (opacity != null) {
      color = color.withOpacity(opacity);
    }
    return 'Color(0x${color.value.toRadixString(16)})';
  }
}
