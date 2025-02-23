import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../collections/project_info_collection.dart';
import '../../../data/remote/firestore/firebase_bridge.dart';
import '../../../models/fvb_ui_core/component/custom_component.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final UserProjectCollection _collection;
  HomeCubit(this._collection) : super(HomeInitial());

  void updateCustomWidgetPreview(CustomComponent component) async {
    component.previewEnable = !component.previewEnable;
    final index = _collection.project!.customComponents
        .indexWhere((element) => element.id == component.id);
    emit(HomeCustomComponentPreviewUpdatedState(index));
    await dataBridge.updateCustomComponentField(
      component,
      'previewEnable',
      component.previewEnable,
    );
  }
}
