import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../components/component_list.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/project_model.dart';
import '../../ui/boundary_widget.dart';
import '../../ui/navigation_setting_view.dart';

part 'fvb_navigation_event.dart';
part 'fvb_navigation_state.dart';

class FvbNavigationBloc extends Bloc<FvbNavigationEvent, FvbNavigationState> {
  final NavigationModel model = NavigationModel();
  PersistentBottomSheetController? persistentBottomSheetController;

  FvbNavigationBloc() : super(FvbNavigationInitial()) {
    on<FvbNavigationEvent>((event, emit) {});
    on<FvbNavigationChangedEvent>(_navigationChanged);
  }

  void restoreState(Screen screen) {
    if (model.drawer) {
      toggleDrawer(open: model.drawer, screen: screen);
    }
  }

  bool isDrawerOpen(Viewable screen) {
    bool open = false;
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          open =
              (GlobalObjectKey(p0).currentState as ScaffoldState).isDrawerOpen;
          return true;
        }
      }
      return false;
    });
    return open;
  }

  bool isEndDrawerOpen(Viewable screen) {
    bool open = false;
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          open = (GlobalObjectKey(p0).currentState as ScaffoldState)
              .isEndDrawerOpen;
          return true;
        }
      }
      return false;
    });
    return open;
  }

  Component? getDrawerComponent(Viewable screen) {
    Component? component;
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          component = p0.childMap['drawer'];
          return true;
        }
      }
      return false;
    });
    return component;
  }

  Component? getEndDrawerComponent(Viewable screen) {
    Component? component;
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          component = p0.childMap['endDrawer'];
          return true;
        }
      }
      return false;
    });
    return component;
  }

  void setDrawerComponent(Component? c, Viewable screen) {
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          p0.childMap['drawer'] = c;
          return true;
        }
      }
      return false;
    });
  }

  void setEndDrawerComponent(Component? c, Viewable screen) {
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          p0.childMap['endDrawer'] = c;
          return true;
        }
      }
      return false;
    });
  }

  void toggleDrawer({bool? open, required Viewable screen}) {
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          if (open ??
              (!(GlobalObjectKey(p0).currentState as ScaffoldState)
                  .isDrawerOpen)) {
            model.drawer = true;
            (GlobalObjectKey(p0).currentState as ScaffoldState?)?.openDrawer();
          } else {
            model.drawer = false;
            (GlobalObjectKey(p0).currentState as ScaffoldState?)?.closeDrawer();
          }
          return true;
        }
      }
      return false;
    });
  }

  void reset() {
    model.dialog = false;
    model.bottomSheet = false;
    model.drawer = false;
    model.endDrawer = false;
  }

  void toggleEndDrawer({bool? open, required Viewable screen}) {
    screen.rootComponent?.forEachWithClones((p0) {
      if (p0 is CScaffold) {
        if (GlobalObjectKey(p0).currentState != null) {
          if (open ??
              (!(GlobalObjectKey(p0).currentState as ScaffoldState)
                  .isEndDrawerOpen)) {
            model.endDrawer = true;
            (GlobalObjectKey(p0).currentState as ScaffoldState?)
                ?.openEndDrawer();
          } else {
            model.endDrawer = false;
            (GlobalObjectKey(p0).currentState as ScaffoldState?)
                ?.closeEndDrawer();
          }
          return true;
        }
      }
      return false;
    });
  }

  FutureOr<void> _navigationChanged(
      FvbNavigationChangedEvent event, Emitter<FvbNavigationState> emit) {
    emit(FvbNavigationChangedState());
  }
}
