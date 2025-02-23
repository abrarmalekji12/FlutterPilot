import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../common/extension_util.dart';
import '../../components/component_list.dart';
import '../../components/holder_impl.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/parameter_model.dart';
import 'data/models/figma_file_response.dart';
import 'figma_analyzer.dart';
import 'figma_to_fvb_converter.dart';
import 'property_converter.dart';

class RouteValue {
  int route;
  double distance;
  int i;
  int j;
  Layout li;
  Layout lj;

  RouteValue(this.route, this.distance, this.i, this.j, this.li, this.lj);

  @override
  String toString() => 'i=$i, j=$j, route=$route, distance=$distance';
}

class FigmaLayoutGenerator {
  List<Layout> getStackList(List<Layout> list) {
    List<Layout> output = [];
    List<Layout> occupied = [];

    final List<List<RouteValue?>> routes =
        List.generate(list.length, (e) => List.filled(list.length, null));
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < i; j++) {
        final route = RouteValue(getLayoutType(list[i], list[j], stack: true),
            0, i, j, list[i], list[j]);
        routes[i][j] = route;
      }
    }

    final Map<Layout, List<Layout>> routeMap = {};
    for (int i = 0; i < list.length; i++) {
      for (int j = 0; j < i; j++) {
        if (routes[i][j]?.route == 3) {
          if (list[i].box.size > list[j].box.size) {
            if (routeMap.containsKey(list[i])) {
              routeMap[list[i]]!.add(list[j]);
            } else {
              routeMap[list[i]] = [list[j]];
            }
          } else {
            if (routeMap.containsKey(list[j])) {
              routeMap[list[j]]!.add(list[i]);
            } else {
              routeMap[list[j]] = [list[i]];
            }
          }
        }
      }
    }
    final List<Layout> layoutList = list.toList();
    layoutList.sort((a, b) =>
        (routeMap[a]?.length ?? 0) < (routeMap[b]?.length ?? 0) ? 1 : -1);
    routeMap.removeWhere((key, value) => value.length < 1);

    for (final layout in layoutList) {
      if (routeMap.containsKey(layout) && !occupied.contains(layout)) {
        output.add(_createStack(routeMap, layout, occupied));
      }
    }
    print('STACK LIST ${output}');
    return output +
        (list.where((element) => !occupied.contains(element)).toList());
  }

  Layout _createStack(
      Map<Layout, List<Layout>> routeMap, Layout layout, List<Layout> used) {
    used.add(layout);
    final List<Layout> children = [];
    for (final value in routeMap[layout]!) {
      if (!routeMap.containsKey(value)) {
        if (value.type == LayoutType.stack) {
          children.addAll(value.children ?? []);
        } else {
          children.add(value);
        }
        used.add(value);
      } else {
        children.removeWhere((element) => routeMap[value]!.contains(element));
        children.add(_createStack(routeMap, value, used));
      }
    }
    if (children.isEmpty) {
      return layout;
    }
    return Layout(LayoutType.stack, children: [
      ...(layout.type == LayoutType.stack ? layout.children! : [layout]),
      if (children.length > 1) createRouteV3(children) else ...children
    ]);
  }

  String combine(String a, String b) {
    if (a == b) {
      return a;
    }
    return '0';
  }

  Layout createRouteV3(List<Layout> list) {
    List<Layout> output = list.toList();

    final List<Layout> leftOutList = output.toList();

    while (output.length > 1) {
      List<List<RouteValue?>> routes =
          List.generate(output.length, (e) => List.filled(output.length, null));
      List<String> layoutList = List.generate(output.length, (index) => '');

      for (int i = 0; i < output.length; i++) {
        for (int j = 0; j < i; j++) {
          final type = getLayoutType(output[i], output[j]);
          final route = RouteValue(type, 0, i, j, output[i], output[j]);
          routes[i][j] = route;
          if (i - 1 == j) {
            layoutList[i - 1] += '0';
          }
          layoutList[i] += type.toString();
          layoutList[j] += type.toString();
        }
        if (i == output.length - 1) {
          layoutList[i] += '0';
        }
      }

      for (int i = 0; i < layoutList.length; i++) {
        for (int j = 0; j < i; j++) {
          if (output[i] != output[j] &&
              [1, 2].contains(routes[i][j]?.route ?? 0) &&
              layoutList[i][j] != '0' &&
              match(routes[i][j]!.route, layoutList[i], layoutList[j])) {
            final layout =
                createLayout(output[i], output[j], routes[i][j]!.route);
            final Set<int> indexes = {i, j};
            String lay = '';
            for (int o = 0; o < output.length; o++) {
              lay += combine(layoutList[i][o], layoutList[j][o]);
            }
            for (int o = 0; o < output.length; o++) {
              if ((o != i && output[o] == output[i]) ||
                  (o != j && output[o] == output[j])) {
                indexes.add(o);
              }
            }
            for (int index in indexes) {
              output[index] = layout;
              layoutList[index] = lay;
            }
            if (leftOutList.contains(routes[i][j]!.li)) {
              leftOutList.remove(routes[i][j]!.li);
            }
            if (leftOutList.contains(routes[i][j]!.lj)) {
              leftOutList.remove(routes[i][j]!.lj);
            }
          }
        }
      }
      final updated = output.toSet().toList();
      if (updated.length != output.length) {
        output = updated;
      } else {
        return Layout(
          LayoutType.stack,
          children: output,
        );
      }
    }
    return output.first;
  }

  Layout createLayout(Layout layout1, Layout layout2, int iType) {
    final type = iType == 1
        ? LayoutType.horizontal
        : (iType == 2 ? LayoutType.vertical : LayoutType.stack);
    final Set<Layout> children = {};
    for (final layout in [layout1, layout2]) {
      if (layout.type == type)
        children.addAll(layout.children!);
      else
        children.add(layout);
    }
    final childrenList = children.toList();
    if (type == LayoutType.horizontal)
      childrenList
          .sort((value1, value2) => value1.box.left > value2.box.left ? 1 : -1);
    else if (type == LayoutType.vertical)
      childrenList
          .sort((value1, value2) => value1.box.top > value2.box.top ? 1 : -1);
    return Layout(
      type,
      children: childrenList,
    );
  }

  bool match(int route, String a, String b) {
    bool singleMatch = false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i] && (a[i] != '0' && b[i] != '0')) {
        return false;
      } else if (a[i] == b[i]) {
        singleMatch = true;
      }
    }
    return singleMatch || a.length <= 2;
  }

  ConvertedComponent generateV2(
      Rect box, List<FigmaComponent> list, FigmaDocumentMeta meta, Rect size) {
    list.sort((comp1, comp2) => comp1.absoluteBoundingBox!.top <=
                comp2.absoluteBoundingBox!.top ||
            comp1.absoluteBoundingBox!.left <= comp2.absoluteBoundingBox!.left
        ? 0
        : 1);
    final route = createRouteV3(getStackList(list
        .where((e) => e.visible ?? true)
        .map((e) => Layout.self(e))
        .toList()));

    layoutSize(route, box);
    print('FINAL ${route}');
    return ConvertedComponent(
        component: route.convertToComponent(FigmaToFVBConverter(), meta, size),
        layout: route);
  }

  void layoutSize(Layout layout, Rect rect) {
    layout.rect = rect;

    for (final Layout lay in layout.children ?? []) {
      final b = lay.box;

      if (layout.type == LayoutType.horizontal) {
        layoutSize(lay, Rect.fromLTWH(b.left, b.top, b.width, rect.height));
      } else {
        layoutSize(
            lay,
            Rect.fromLTWH(
              b.left,
              b.top,
              rect.width,
              b.height,
            ));
      }
    }
  }

  int getLayoutType(Layout child1, Layout child2, {bool stack = false}) {
    if ((child1.type != LayoutType.self && child2.type == LayoutType.self) ||
        (child2.type != LayoutType.self && child1.type == LayoutType.self)) {
      if (child1.type == LayoutType.self) {
        final t = child1;
        child1 = child2;
        child2 = t;
      }
      List<int> types = [];
      for (final subChild in child1.children ?? []) {
        types.add(getLayoutType(subChild, child2));
      }
      if (types.isNotEmpty) {
        if (types.first != 0 &&
            types.every((element) => types.first == element)) {
          return types.first;
        }
      }
    }
    final box = child1.box;
    final prevBox = child2.box;

    final hGap = min(prevBox.height, box.height) / 2;
    final wGap = min(prevBox.width, box.width) / 2;
    if (stack && box.overlaps(prevBox)) {
      return 3;
    } else if ((box.height >= prevBox.height &&
            prevBox.top + hGap >= box.top &&
            prevBox.bottom - hGap <= box.bottom) ||
        (box.height < prevBox.height &&
            prevBox.top - hGap <= box.top &&
            prevBox.bottom + hGap >= box.bottom)) {
      return 1;
    } else if ((box.width >= prevBox.width &&
            prevBox.left + wGap >= box.left &&
            prevBox.right - wGap <= box.right) ||
        (box.width < prevBox.width &&
            prevBox.left - wGap <= box.left &&
            prevBox.right + wGap >= box.right)) {
      return 2;
    }
    return 0;
  }
}

enum LayoutType { self, vertical, horizontal, stack }

class LayoutAlignment {
  final double cCenter, cStart, cEnd;

  LayoutAlignment(this.cCenter, this.cStart, this.cEnd);

  @override
  String toString() => '[center=  $cCenter, start= $cStart, end= $cEnd]';
}

class Layout {
  final LayoutType type;
  final List<Layout>? children;
  final FigmaComponent? self;
  Rect? rect;
  Layout? child;

  Layout(this.type, {this.children, this.self, this.rect}) {
    if (type == LayoutType.stack) {
      final List<Layout> stackList = [];
      for (final Layout child in children ?? []) {
        if (child.type == LayoutType.stack) {
          stackList.add(child);
        }
      }
      for (final val in stackList) {
        children!.remove(val);
        children!.addAll(val.children ?? []);
      }
    }
  }

  @override
  String toString() {
    if (children?.isNotEmpty ?? false) {
      return '{"${type.name}":[\n${children!.map((e) => '${e.toString()}').join(',\n')}]}';
    }
    return '{"${self?.name}":${self?.absoluteBoundingBox}}';
  }

  (double, double, double, double) get layoutDimen {
    final b = children![0].box;
    double x = b.left, y = b.top, right = b.right, bottom = b.bottom;
    for (final Layout child in children ?? []) {
      final b = child.box;
      if (b.left < x) {
        x = b.left;
      }
      if (b.top < y) {
        y = b.top;
      }
      if (b.right > right) {
        right = b.right;
      }
      if (b.bottom > bottom) {
        bottom = b.bottom;
      }
    }
    return (x, y, right, bottom);
  }

  Rect get boundaryBox {
    final (x, y, right, bottom) = layoutDimen;
    return AbsoluteBoundingBox(
        x: x, y: y, width: right - x, height: bottom - y);
  }

  Rect get box {
    if (self != null) {
      return self!.absoluteBoundingBox!;
    }

    /*
    double x = type==LayoutType.vertical&&child!=null?child.x:b.x, y = type==LayoutType.horizontal&&child!=null?child.y:b.y,
    width =  type==LayoutType.vertical&&child!=null?b.width:, height = b.height;
    */

    var (x, y, right, bottom) = layoutDimen;
    if (rect != null) {
      if (type == LayoutType.horizontal) {
        return Rect.fromLTRB(x, rect!.top, right, rect!.bottom);
      } else if (type == LayoutType.vertical) {
        return Rect.fromLTRB(rect!.left, y, rect!.right, bottom);
      } else if (type == LayoutType.stack || type == LayoutType.self) {
        return rect!;
      }
    }
    return AbsoluteBoundingBox(
        x: x, y: y, width: right - x, height: bottom - y);
  }

  factory Layout.self(FigmaComponent child) {
    return Layout(LayoutType.self, self: child);
  }

  double _round(double d) => (d * 1000).round() / 1000;

  List<LayoutAlignment> crossAlignment(List<Layout> layouts) {
    final rect = box;
    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    List<LayoutAlignment> list = [];
    for (final layout in layouts) {
      final layRect = layout.box;
      final horizontal = type == LayoutType.horizontal;

      final cCenter = horizontal
          ? ((layRect.center.dy - centerY) / rect.height)
          : (layRect.center.dx - centerX) / rect.width;
      final cStart = horizontal
          ? ((layRect.top - rect.top) / rect.height)
          : (layRect.left - rect.left) / rect.width;
      final cEnd = horizontal
          ? ((rect.bottom - layRect.bottom) / rect.height)
          : (rect.right - layRect.right) / rect.width;

      list.add(LayoutAlignment(
        _round(cCenter),
        _round(cStart),
        _round(cEnd),
      ));
    }
    return list;
  }

  (double?, double?, double?, double?) computePaddings(
      Offset parent, Offset child) {
    double? top, bottom, left, right;
    if ((parent.dx - child.dx).abs() >= 1) {
      if (parent.dx < child.dx) {
        left = child.dx - parent.dx;
      } else {
        right = parent.dx - child.dx;
      }
    }
    if ((parent.dy - child.dy).abs() >= 1) {
      if (parent.dy < child.dy) {
        top = child.dy - parent.dy;
      } else {
        bottom = parent.dy - child.dy;
      }
    }
    return (top, bottom, left, right);
  }

  (double?, double?) computeHorizontalPaddings(double parent, double child) {
    double? left, right;
    if ((parent - child).abs() >= 1) {
      if (parent < child) {
        left = child - parent;
      } else {
        right = parent - child;
      }
    }
    return (left, right);
  }

  (double?, double?) computeVerticalPaddings(double parent, double child) {
    double? top, bottom;
    if ((parent - child).abs() >= 1) {
      if (parent < child) {
        top = child - parent;
      } else {
        bottom = parent - child;
      }
    }
    return (top, bottom);
  }

  Component convertToComponent(
      FigmaToFVBConverter converter, FigmaDocumentMeta meta, Rect size) {
    if (type == LayoutType.self) {
      return converter.decodeComponent(self!, null, meta, size,
              child: child != null
                  ? ConvertedComponent(
                      component:
                          child!.convertToComponent(converter, meta, size),
                      layout: child,
                    )
                  : null) ??
          COffstage();
    } else if (type == LayoutType.stack) {
      final list = children!.toList();
      list.sort((v1, v2) => v1.box.area < v2.box.area ? 1 : -1);
      if (list.length == 2 &&
          list.any((element) => !(element.self?.hasAnyChild ?? false))) {
        final index =
            list.indexWhere((element) => element.self?.isDecorative ?? false);
        if (index >= 0) {
          Layout comp;
          Layout childLay;
          if (index == 0) {
            comp = (list[index]..child = (childLay = list[1]));
          } else {
            comp = (list[index]..child = (childLay = list[0]));
          }
          if (comp.box.containsRect(childLay.box)) {
            return comp.convertToComponent(converter, meta, size);
          }
        }
      }
      final stack = CStack();
      (stack.parameters[0] as ChoiceValueParameter).update('center');
      final parentBox = box;
      setDoubleParameter(
          stack.defaultParam[0]!, parentBox.width, size.size, true);
      setDoubleParameter(
          stack.defaultParam[1]!, parentBox.height, size.size, false);
      stack.children.addAll(list.map((e) {
        final b = e.box;
        Component comp = e.convertToComponent(converter, meta, size);
        final leftD = (b.left - parentBox.left).abs();
        final centerHorizontalD = (b.center.dx - parentBox.center.dx).abs();
        final rightD = (parentBox.right - b.right).abs();

        final topD = (b.top - parentBox.top).abs();
        final centerVerticalD = (b.center.dy - parentBox.center.dy).abs();
        final bottomD = (parentBox.bottom - b.bottom).abs();
        if ((centerHorizontalD <= leftD && centerHorizontalD <= rightD) &&
            (centerVerticalD <= topD && centerVerticalD <= bottomD)) {
          Holder component = CCenter();
          var (top, bottom, left, right) =
              computePaddings(parentBox.center, b.center);
          if (top != null || bottom != null || left != null || right != null) {
            final padding = CPadding();
            final complex = (padding.parameters[0] as ChoiceParameter).update(1)
                as ComplexParameter;
            setDoubleParameter(complex.params[0], top, size.size, false);
            setDoubleParameter(complex.params[1], left, size.size, true);
            setDoubleParameter(complex.params[2], bottom, size.size, false);
            setDoubleParameter(complex.params[3], right, size.size, true);
            component.updateChild((padding..updateChild(comp)));
          } else {
            component.updateChild(comp);
          }
          return component;
        } else {
          double? left, right, top, bottom;
          if (centerHorizontalD <= leftD && centerHorizontalD <= rightD) {
            (left, right) =
                computeHorizontalPaddings(parentBox.center.dx, b.center.dx);
          } else if (leftD <= rightD) {
            (left, right) = computeHorizontalPaddings(parentBox.left, b.left);
          } else {
            (left, right) = computeHorizontalPaddings(parentBox.right, b.right);
          }
          if (centerVerticalD <= topD && centerVerticalD <= bottomD) {
            (top, bottom) =
                computeVerticalPaddings(parentBox.center.dy, b.center.dy);
          } else if (topD <= bottomD) {
            (top, bottom) = computeVerticalPaddings(parentBox.top, b.top);
          } else {
            (top, bottom) = computeVerticalPaddings(parentBox.bottom, b.bottom);
          }
          if (top != null || bottom != null || left != null || right != null) {
            Holder component = CPositioned();
            setDoubleParameter(component.parameters[0], left, size.size, true);
            setDoubleParameter(component.parameters[1], right, size.size, true);
            setDoubleParameter(component.parameters[2], top, size.size, false);
            setDoubleParameter(
                component.parameters[3], bottom, size.size, false);
            String alignment =
                converter.propertyConverter.applyAlignment(parentBox, b);
            if (alignment != 'center') {
              final align = CAlign();
              (align.parameters[0] as ChoiceValueParameter).update(alignment);
              component.updateChild(align);
              align.updateChild(comp);
              comp = align;
            }
            return component
              ..updateChild(comp)
              ..setParent(stack);
          }
          return comp;
        }
      }).map((e) => e..setParent(stack)));
      return stack;
    } else {
      List<Component> list = children!
          .map((e) => e.convertToComponent(converter, meta, size))
          .toList();
      final crossAlignList = crossAlignment(children!);
      final r = box;
      final averageCrossCenter = crossAlignList
              .map((e) => e.cCenter.abs())
              .reduce((value, element) => value + element) /
          crossAlignList.length;
      final averageCrossStart = crossAlignList
              .map((e) => e.cStart)
              .reduce((value, element) => value + element) /
          crossAlignList.length;
      final averageCrossEnd = crossAlignList
              .map((e) => e.cEnd)
              .reduce((value, element) => value + element) /
          crossAlignList.length;
      final globalAlignment = averageCrossCenter <= averageCrossStart &&
              averageCrossCenter <= averageCrossEnd
          ? 'center'
          : (averageCrossStart < averageCrossEnd ? 'start' : 'end');
      final horizontal = type == LayoutType.horizontal;

      List<LayoutConfig> paddings = [];
      if (averageCrossCenter != 0 &&
          averageCrossStart != 0 &&
          averageCrossEnd != 0) {
        for (int i = 0; i < list.length; i++) {
          final String alignment;
          double? paddingStart, paddingEnd;
          if (crossAlignList[i].cCenter.abs() < crossAlignList[i].cStart &&
              crossAlignList[i].cCenter.abs() < crossAlignList[i].cEnd) {
            alignment = 'center';
            if (crossAlignList[i].cCenter != 0) {
              if (crossAlignList[i].cCenter < 0) {
                paddingEnd = (crossAlignList[i].cCenter.abs() *
                    (horizontal ? r.height : r.width));
              } else {
                paddingStart = (crossAlignList[i].cCenter *
                    (horizontal ? r.height : r.width));
              }
            }
          } else if (crossAlignList[i].cStart < crossAlignList[i].cEnd) {
            alignment = 'start';
            if (crossAlignList[i].cStart != 0) {
              paddingStart = (crossAlignList[i].cStart *
                  (horizontal ? r.height : r.width));
            }
          } else {
            alignment = 'end';
            if (crossAlignList[i].cEnd != 0) {
              paddingEnd =
                  (crossAlignList[i].cEnd * (horizontal ? r.height : r.width));
            }
          }
          paddings.add(LayoutConfig(
            paddingCrossStart: paddingStart,
            paddingCrossEnd: paddingEnd,
            alignment: alignment != globalAlignment
                ? convertCrossAxisAlignment(alignment)
                : null,
          ));
        }
      } else {
        paddings = List.generate(list.length, (index) => LayoutConfig());
      }

      final rectList = children!.map((e) => e.box).toList();
      for (int i = 0; i < list.length; i++) {
        final hasPaddingParameter = list[i].defaultParam[2] ??
            list[i].parameters.firstWhereOrNull(
                (element) => element.info.getName() == 'margin');
        final ComplexParameter complex;
        if (hasPaddingParameter == null) {
          final padding = CPadding();
          padding.updateChild(list[i]);
          complex = (padding.parameters[0] as ChoiceParameter).update(1)
              as ComplexParameter;
          list[i] = padding;
        } else {
          complex = (hasPaddingParameter as ChoiceParameter)
                  .update(hasPaddingParameter.options.length - 2)
              as ComplexParameter;
        }
        if (!horizontal) {
          if (paddings[i].paddingCrossStart != null &&
              paddings[i].paddingCrossStart! >= 1)
            setDoubleParameter(complex.params[1], paddings[i].paddingCrossStart,
                size.size, true);
          else if (paddings[i].paddingCrossEnd != null &&
              paddings[i].paddingCrossEnd! >= 1)
            setDoubleParameter(complex.params[3], paddings[i].paddingCrossEnd,
                size.size, true);
          if (i > 0 && (rectList[i].top - rectList[i - 1].bottom) >= 1) {
            setDoubleParameter(complex.params[0],
                rectList[i].top - rectList[i - 1].bottom, size.size, false);
          }
        } else {
          if (paddings[i].paddingCrossStart != null &&
              paddings[i].paddingCrossStart! >= 1) {
            setDoubleParameter(complex.params[0], paddings[i].paddingCrossStart,
                size.size, false);
          } else if (paddings[i].paddingCrossEnd != null &&
              paddings[i].paddingCrossEnd! >= 1) {
            setDoubleParameter(complex.params[2], paddings[i].paddingCrossEnd,
                size.size, false);
          }
          if (i > 0 && (rectList[i].left - rectList[i - 1].right) >= 1) {
            setDoubleParameter(complex.params[1],
                (rectList[i].left - rectList[i - 1].right), size.size, true);
          }
        }
        if (paddings[i].alignment != null) {
          final align = CAlign();
          align.updateChild(list[i]);
          (align.parameters[0] as ChoiceValueParameter)
              .update(paddings[i].alignment);
          list[i] = align;
        }
      }
      if (type == LayoutType.horizontal) {
        final row = CRow();
        (row.parameters[1] as ChoiceValueParameter).update(globalAlignment);
        final bBox = boundaryBox;
        if (rect != null && (rect!.width - bBox.width) < 1) {
          (row.parameters[2] as ChoiceValueParameter).update('min');
        }
        return row..children.addAll(list.map((e) => e..setParent(row)));
      } else if (type == LayoutType.vertical) {
        final column = CColumn();
        final bBox = boundaryBox;

        (column.parameters[1] as ChoiceValueParameter).update(globalAlignment);
        if (rect != null && (rect!.height - bBox.height) < 1) {
          (column.parameters[2] as ChoiceValueParameter).update('min');
        }
        print(
            'LAYOUT ${crossAlignList} AVERAGE center=$averageCrossCenter, start=$averageCrossStart, end=$averageCrossEnd, ');
        return column..children.addAll(list.map((e) => e..setParent(column)));
      }
    }
    return COffstage();
  }

  String convertCrossAxisAlignment(String align) {
    final horizontal = type == LayoutType.horizontal;
    if (align == 'start') {
      return horizontal ? 'topCenter' : 'centerLeft';
    }
    if (align == 'end') {
      return horizontal ? 'bottomCenter' : 'centerRight';
    }
    return 'center';
  }
}

class LayoutConfig {
  double? paddingStart;
  double? paddingEnd;
  double? paddingCrossStart;
  double? paddingCrossEnd;
  String? alignment;

  LayoutConfig({
    this.paddingStart,
    this.paddingEnd,
    this.paddingCrossStart,
    this.paddingCrossEnd,
    this.alignment,
  });
}

class ConvertedComponent {
  Layout? layout;
  Component? component;

  ConvertedComponent({this.component, this.layout});
}

final converter = FigmaPropertyConverter();

void setDoubleParameter(
    Parameter parameter, double? value, Size screenSize, bool? horizontal) {
  if (value != null) {
    if (horizontal != null) {
      final v = (value / (horizontal ? screenSize.width : screenSize.height));
      parameter.setCode('${v.toStringAsFixed(4)}.${horizontal ? 'w' : 'h'}');
    } else {
      parameter.setCode('${value.toStringAsFixed(2)}');
    }
  }
}

void setColorParameter(
    Parameter parameter, FigmaColor? value, double? opacity) {
  if (value != null) {
    parameter
        .setCode('${converter.convertColorToFVB(value, opacity: opacity)}');
  }
}
