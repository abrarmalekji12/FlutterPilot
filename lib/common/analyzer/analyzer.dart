import 'dart:math';

import 'package:flutter/material.dart';

import '../../components/component_list.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../ui/boundary_widget.dart';
import 'render_models.dart';

class AnalyzerException implements Exception {
  AnalyzerException();
}

class FVBAnalyzer {
  static Future<List<AnalyzerError>?> analyze(
      Component component, Size size, Viewable screen) async {
    systemProcessor.variables['dw']!.value = size.width;
    systemProcessor.variables['dh']!.value = size.height;
    final List<AnalyzerError> list = [];
    try {
      await analyzeComponent(component, size, list, screen);
    } on AnalyzerException {
      return list.isEmpty ? null : list;
    }
    return list.isEmpty ? null : list;
  }

  static Future<Size> analyzeComponent(Component component, Size size,
      List<AnalyzerError> list, Viewable screen) async {
    if (list.isNotEmpty) {
      return size;
    }
    if (component is CustomComponent) {
      if (component.rootComponent != null) {
        return await analyzeComponent(
            component.rootComponent!, size, list, screen);
      }
    }

    if (component is CParentFlexModel) {
      if (component is Holder) {
        final child = component.child;
        if (child != null) {
          return await analyzeComponent(child, size, list, screen);
        }
      }
      return size;
    } else if (component is CRenderModel) {
      final compSize = (component as CRenderModel).size;
      final calculatedSize = finiteSize(compSize, size);
      if (!(component as CRenderModel).settle &&
          ((size.width != -1 && calculatedSize.width > size.width) ||
              (size.height != -1 && calculatedSize.height > size.height))) {
        list.add(AnalyzerError(
            '${component.name} has $calculatedSize which is bigger than $size',
            component,
            screen));
        throw AnalyzerException();
      }
      final margin = (component as CRenderModel).margin;
      final padding = (component as CRenderModel).padding;
      if (component is Holder && component.child != null) {
        final childSize =
            finiteSize((component as CRenderModel).childSize, size);

        final diff = Size(
            childSize.width != -1 ? (childSize.width - padding.horizontal) : -1,
            childSize.height != -1
                ? (childSize.height - padding.vertical)
                : -1);
        final output = await analyzeComponent(
            component.child!,
            Size(
              size.width != -1 ? min(diff.width, size.width) : diff.width,
              size.height != -1 ? min(diff.height, size.height) : diff.height,
            ),
            list,
            screen);
        return Size(
          max(output.width, childSize.width + margin.horizontal),
          max(output.height, childSize.height + margin.vertical),
        );
      }
      return calculatedSize + Offset(margin.horizontal, margin.vertical);
    } else if (component is CLeafRenderModel) {
      final calculate = await (component as CLeafRenderModel).size(Size(
        size.width.isNegative ? double.infinity : size.width,
        size.height.isNegative ? double.infinity : size.height,
      ));

      return calculate;
    } else if (component is CBoxScrollModel) {
      // if((component as CBoxScrollModel).direction==Axis.vertical){
      //
      // }
      return size;
    } else if (component is ComplexRenderModel) {
      final compSize = (component as ComplexRenderModel).size;
      final calculatedSize = Size(
          compSize.width.isInfinite ? size.width : compSize.width,
          compSize.height.isInfinite ? size.height : compSize.height);
      if (calculatedSize > size) {
        list.add(AnalyzerError('Error 1', component, screen));
        throw AnalyzerException();
      }
      for (final child in (component as CustomNamedHolder).childMap.entries) {
        if (child.value != null) {
          final temp = (component as ComplexRenderModel).childSize(child.key);
          await analyzeComponent(
              child.value!, temp.childSize(size), list, screen);
        }
      }

      // for (final child in component.childrenMap.entries) {
      //   if (child.value != null) {
      //     analyzeComponent(child.value!, (component as ComplexRenderModel).childSize(child.key), list);
      //   }
      // }
    } else if (component is CFlexModel && component is MultiHolder) {
      final vertical = (component as CFlexModel).direction == Axis.vertical;
      double v = vertical ? size.height : size.width;
      double c = vertical ? size.width : size.height;
      final List<CParentFlexModel> parentFlexes = [];
      for (final child in component.children) {
        if (child is CParentFlexModel) {
          parentFlexes.add(child as CParentFlexModel);
          continue;
        }
        final aSize = await analyzeComponent(
            child,
            vertical ? Size(size.width, -1) : Size(-1, size.height),
            list,
            screen);
        final cross = vertical ? aSize.width : aSize.height;
        if (cross > c) {
          c = cross;
        }
        if (v >= 0) {
          v -= (vertical ? aSize.height : aSize.width);
          if (v < 0) {
            list.add(AnalyzerError(
                '${child.parent?.name} => child ${child.name} ${vertical ? 'height' : 'width'} overflowed by ${(-v).toStringAsFixed(2)} pixels',
                component,
                screen));
            list.add(AnalyzerError(
                'Overflow ${(-v).toStringAsFixed(2)} pixels', child, screen));

            throw AnalyzerException();
          }
        }
      }
      if (parentFlexes.isNotEmpty) {
        final flexFactor = v /
            (parentFlexes
                .map((e) => e.flex)
                .reduce((value, element) => value + element));
        for (final flexModel in parentFlexes) {
          await analyzeComponent(
              flexModel as Component,
              vertical
                  ? Size(size.width, flexFactor * flexModel.flex)
                  : Size(flexFactor * flexModel.flex, size.height),
              list,
              screen);
        }
      }
      if ((component as CFlexModel).mainAxisSize == MainAxisSize.max ||
          parentFlexes.isNotEmpty) {
        return Size(vertical ? c : size.width, vertical ? size.height : c);
      } else {
        return vertical ? Size(c, v) : Size(v, c);
      }
    } else {
      debugPrint('Not implemented ${component.name}');
    }
    return size;
  }
}

Size finiteSize(Size size, Size boundary) {
  return Size(size.width == double.infinity ? boundary.width : size.width,
      size.height == double.infinity ? boundary.height : size.height);
}

Size finiteComponentSize(ComponentSize size, Size boundary) {
  return Size(size.width == double.infinity ? boundary.width : size.width,
      size.height == double.infinity ? boundary.height : size.height);
}

class AnalyzerError {
  final String message;
  final Component component;
  final Viewable screen;

  AnalyzerError(this.message, this.component, this.screen);

  @override
  String toString() {
    return '${component.name} = $message';
  }
}
