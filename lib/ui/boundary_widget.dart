import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:flutter_builder/parameter_model.dart';
import 'package:flutter_builder/ui/visual_model.dart';
import 'package:flutter_builder/ui/visual_painter.dart';
import 'package:provider/provider.dart';

class BoundaryWidget extends StatelessWidget {
  const BoundaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
        builder: (context, state) {
          return BlocBuilder<VisualBoxCubit, VisualBoxState>(
            builder: (context, state) {
              final List<Boundary> boundaries = getAllBoundaries(context);
              return CustomPaint(
                painter: BoundaryPainter(
                    boundaries: boundaries,
                    errorBoundary:
                        Provider.of<VisualBoxCubit>(context, listen: false)
                                    .errorMessage !=
                                null
                            ? Provider.of<ComponentOperationCubit>(context,
                                    listen: false)
                                .mainExecution
                                .rootComponent!
                                .boundary!
                            : null),
              );
              return Container();
            },
          );
        },
      ),
    );
  }

  List<Boundary> getAllBoundaries(BuildContext context) {
    final List<Boundary> boundaries = [];
    if (Provider.of<ComponentSelectionCubit>(context, listen: false)
        .currentSelected is CustomComponent) {
      if ((Provider.of<ComponentSelectionCubit>(context, listen: false)
                  .currentSelected as CustomComponent)
              .root
              ?.boundary !=
          null) {
        boundaries.add(Boundary(
            (Provider.of<ComponentSelectionCubit>(context, listen: false)
                    .currentSelected as CustomComponent)
                .root!
                .boundary!,
            Provider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelected
                .name));
      }
    } else if (Provider.of<ComponentSelectionCubit>(context, listen: false)
        .currentSelectedRoot is CustomComponent) {
      for (final customComponent
          in (Provider.of<ComponentSelectionCubit>(context, listen: false)
                  .currentSelectedRoot as CustomComponent)
              .objects) {
        final comp = findSameLevelComponent(
            customComponent,
            (Provider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelectedRoot as CustomComponent),
            Provider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelected);
        if (comp.boundary != null) {
          boundaries.add(Boundary(comp.boundary!, comp.name));
        }
      }
    } else if (Provider.of<ComponentSelectionCubit>(context, listen: false)
            .currentSelected
            .boundary !=
        null) {
      boundaries.add(Boundary(
          Provider.of<ComponentSelectionCubit>(context, listen: false)
              .currentSelected
              .boundary!,
          Provider.of<ComponentSelectionCubit>(context, listen: false)
              .currentSelected
              .name));
    }
    return boundaries;
  }

  Component findSameLevelComponent(
      CustomComponent copy, CustomComponent original, Component object) {
    Component? tracer = object;
    List<List<Parameter>> paramList = [];
    while (tracer != original) {
      // print('TRACER ${tracer?.name}');
      paramList.add(tracer!.parameters);
      tracer = tracer.parent;
    }
    // print('TRACER 1 ${tracer?.name}');
    tracer = copy;
    for (final param in paramList.reversed) {
      tracer = findChildWithParam(tracer!, param);
    }
    // print('TRACER 2 ${tracer?.name}');

    return tracer!;
  }

  Component? findChildWithParam(Component component, List<Parameter> params) {
    switch (component.type) {
      case 3:
        return (component as Holder).child!;
      case 2:
        return (component as MultiHolder)
            .children
            .firstWhere((element) => element.parameters == params);
      case 4:
        return (component as CustomNamedHolder).childMap.values.firstWhere(
            (element) => element != null && element.parameters == params);
      case 5:
        return (component as CustomComponent).root;
    }
    return null;
  }
}
