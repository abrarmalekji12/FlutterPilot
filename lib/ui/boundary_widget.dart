import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
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
      color: Colors.transparent,
      child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
        builder: (context, state) {
          return BlocBuilder<VisualBoxCubit, VisualBoxState>(
            builder: (context, state) {
              if(Provider.of<ComponentSelectionCubit>(context,listen: false).currentSelected.boundary!=null) {
                return CustomPaint(
                  painter: BoundaryPainter(selectedBoundary:Boundary( Provider.of<ComponentSelectionCubit>(context,listen: false).currentSelected.boundary!, Provider.of<ComponentSelectionCubit>(context,listen: false).currentSelected.name),errorBoundary: Provider.of<VisualBoxCubit>(context,listen: false).errorMessage!=null?Provider.of<ComponentOperationCubit>(context,listen: false).rootComponent.boundary!:null),
                );
              }
              return Container();
            },
          );
        },
      ),
    );
  }
}
