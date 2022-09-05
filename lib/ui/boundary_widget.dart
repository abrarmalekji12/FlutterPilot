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
                size: const Size(double.infinity, double.infinity),
                painter: BoundaryPainter(
                    boundaries: boundaries,
                    errorBoundary:
                        BlocProvider.of<VisualBoxCubit>(context).errorMessage !=
                                null
                            ? BlocProvider.of<ComponentOperationCubit>(context,
                                    listen: false)
                                .project!
                                .rootComponent!
                                .boundary!
                            : null,
                    hoverBoundaries: state is VisualBoxHoverUpdatedState
                        ? state.boundaries
                        : []),
              );
            },
          );
        },
      ),
    );
  }

  List<Boundary> getAllBoundaries(BuildContext context) {
    return BlocProvider.of<ComponentSelectionCubit>(context)
        .currentSelected
        .visualSelection
        .where((element) => element.boundary != null)
        .where((element) {
          if (GlobalObjectKey(element).currentContext != null) {
            return true;
          } else {
            element.cloneOf?.cloneElements.remove(element);
            return false;
          }
        })
        .map<Boundary>((e) => Boundary(e.boundary!, e.name))
        .toList(growable: false);
  }

// List<Boundary> getAllBoundaries(BuildContext context) {
//   final List<Boundary> boundaries = [];
//   if (BlocProvider.of<ComponentSelectionCubit>(context)
//       .currentSelected is CustomComponent) {
//     if ((BlocProvider.of<ComponentSelectionCubit>(context)
//                 .currentSelected as CustomComponent)
//             .root
//             ?.boundary !=
//         null) {
//       boundaries.add(Boundary(
//           (BlocProvider.of<ComponentSelectionCubit>(context)
//                   .currentSelected as CustomComponent)
//               .root!
//               .boundary!,
//           BlocProvider.of<ComponentSelectionCubit>(context)
//               .currentSelected
//               .));
//     }
//   } else if (BlocProvider.of<ComponentSelectionCubit>(context)
//       .currentSelectedRoot is CustomComponent) {
//     final rootComp =
//         BlocProvider.of<ComponentSelectionCubit>(context)
//             .currentSelectedRoot as CustomComponent;
//     addCustomComponentInstancesBoundary(context, rootComp, boundaries);
//   } else if (BlocProvider.of<ComponentSelectionCubit>(context)
//           .currentSelected
//           .boundary !=
//       null) {
//     boundaries.add(
//       Boundary(
//           BlocProvider.of<ComponentSelectionCubit>(context)
//               .currentSelected
//               .boundary!,
//           BlocProvider.of<ComponentSelectionCubit>(context)
//               .currentSelected
//               .name),
//     );
//   }
//   logger('==== BOUNDARY ${boundaries.length}');
//   return boundaries;
// }
//
// void addCustomComponentInstancesBoundary(BuildContext context,
//     CustomComponent rootComp, List<Boundary> boundaries) {
//   final comp = CustomComponent.findSameLevelComponent(
//       rootComp,
//       (BlocProvider.of<ComponentSelectionCubit>(context)
//           .currentSelectedRoot as CustomComponent),
//       BlocProvider.of<ComponentSelectionCubit>(context)
//           .currentSelected);
//   if (comp.boundary != null) {
//     boundaries.add(Boundary(comp.boundary!, comp.name));
//   } else {
//     for (final customComponent in rootComp.objects) {
//       final comp = CustomComponent.findSameLevelComponent(
//           customComponent,
//           (BlocProvider.of<ComponentSelectionCubit>(context)
//               .currentSelectedRoot as CustomComponent),
//           BlocProvider.of<ComponentSelectionCubit>(context)
//               .currentSelected);
//       if (comp.boundary != null) {
//         boundaries.add(Boundary(comp.boundary!, comp.name));
//       }
//       final customRoot = customComponent.getLastRoot();
//       if (customRoot is CustomComponent) {
//         for (final customRootObject in customRoot.objects) {
//           final cloneComp = CustomComponent.findSameLevelComponent(
//               customRootObject, customRoot, customComponent);
//           logger(
//               '=== addCustomComponentInstancesBoundary cloneComp ${cloneComp.name}');
//
//           addCustomComponentInstancesBoundary(
//               context, cloneComp as CustomComponent, boundaries);
//         }
//         // addCustomComponentInstancesBoundary(context,customRoot)
//       }
//       // if(customRoot !=null )
//       logger(
//           '=== addCustomComponentInstancesBoundary CUSTOM ROOT ${customRoot.name}');
//     }
//   }
// }
}
