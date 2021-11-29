import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:flutter_builder/ui/visual_model.dart';
import 'package:flutter_builder/ui/visual_painter.dart';
import 'package:provider/provider.dart';

class BoundaryWidget extends StatelessWidget {
  const BoundaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
        builder: (context, state) {
          return BlocBuilder<VisualBoxCubit, VisualBoxState>(
            builder: (context, state) {
              if (Provider.of<ComponentSelectionCubit>(context, listen: false)
                      .currentSelected
                      .boundary !=
                  null) {
                return CustomPaint(
                  painter: BoundaryPainter([
                    Boundary(
                        Provider.of<ComponentSelectionCubit>(context,
                                listen: false)
                            .currentSelected
                            .boundary!,
                        Provider.of<ComponentSelectionCubit>(context,
                                listen: false)
                            .currentSelected
                            .name)
                  ]),
                );
              }
              return Container();
            },
          );
        },
      ),
      decoration: const BoxDecoration(
        // border: Border.all(color: Colors.black, width: 1.5),
        color: Colors.transparent,
      ),
    );
  }
}
