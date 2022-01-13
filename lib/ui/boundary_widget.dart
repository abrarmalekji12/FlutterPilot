import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/logger.dart';
import '../models/component_model.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import 'visual_model.dart';
import 'visual_painter.dart';
import 'package:provider/provider.dart';

class BoundaryWidget extends StatelessWidget {
  const BoundaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
        builder: (context, state) {
          logger('======== COMPONENT SELECTION ');
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
                            .flutterProject!
                                .rootComponent!
                                .boundary!
                            : null),
              );
            },
          );
        },
      ),
    );
  }

  List<Boundary> getAllBoundaries(BuildContext context) {
    final List<Boundary> boundaries = [];
    if (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
        .currentSelected is CustomComponent) {
      if ((BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                  .currentSelected as CustomComponent)
              .root
              ?.boundary !=
          null) {
        boundaries.add(Boundary(
            (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                    .currentSelected as CustomComponent)
                .root!
                .boundary!,
            BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelected
                .name));
      }
    } else if (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
        .currentSelectedRoot is CustomComponent) {
      final rootComp =
          BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
              .currentSelectedRoot as CustomComponent;
      addCustomComponentInstancesBoundary(context, rootComp, boundaries);
    } else if (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
            .currentSelected
            .boundary !=
        null) {
      boundaries.add(
        Boundary(
            BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelected
                .boundary!,
            BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelected
                .name),
      );
    }
    logger('==== BOUNDARY ${boundaries.length}');
    return boundaries;
  }

  void addCustomComponentInstancesBoundary(BuildContext context,
      CustomComponent rootComp, List<Boundary> boundaries) {
    final comp = CustomComponent.findSameLevelComponent(
        rootComp,
        (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
            .currentSelectedRoot as CustomComponent),
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
            .currentSelected);
    if (comp.boundary != null) {
      boundaries.add(Boundary(comp.boundary!, comp.name));
    } else {
      for (final customComponent in rootComp.objects) {
        final comp = CustomComponent.findSameLevelComponent(
            customComponent,
            (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelectedRoot as CustomComponent),
            BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                .currentSelected);
        if (comp.boundary != null) {
          boundaries.add(Boundary(comp.boundary!, comp.name));
        }
        final customRoot = customComponent.getLastRoot();
        if (customRoot is CustomComponent) {
          for (final customRootObject in customRoot.objects) {
            final cloneComp = CustomComponent.findSameLevelComponent(
                customRootObject, customRoot, customComponent);
            logger(
                '=== addCustomComponentInstancesBoundary cloneComp ${cloneComp.name}');

            addCustomComponentInstancesBoundary(
                context, cloneComp as CustomComponent, boundaries);
          }
          // addCustomComponentInstancesBoundary(context,customRoot)
        }
        // if(customRoot !=null )
        logger(
            '=== addCustomComponentInstancesBoundary CUSTOM ROOT ${customRoot.name}');
      }
    }
  }
}
