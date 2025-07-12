import 'dart:ui' as ui;

import 'package:device_preview/device_preview.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:get_it/get_it.dart';
// import 'package:keyboard_event/keyboard_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/component_generator.dart';
import 'bloc/action_code/action_code_bloc.dart';
import 'bloc/api_bloc/api_bloc.dart';
import 'bloc/component_drag/component_drag_bloc.dart';
import 'bloc/error/error_bloc.dart';
import 'bloc/key_fire/key_fire_bloc.dart';
import 'bloc/navigation/fvb_navigation_bloc.dart';
import 'bloc/state_management/state_management_bloc.dart';
import 'bloc/theme/theme_bloc.dart';
import 'code_snippets/common_snippets.dart';
import 'collections/project_info_collection.dart';
import 'common/analyzer/package_analyzer.dart';
import 'common/responsive/responsive_widget.dart';
import 'components/component_list.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'cubit/component_creation/component_creation_cubit.dart';
import 'cubit/component_operation/operation_cubit.dart';
import 'cubit/component_selection/component_selection_cubit.dart';
import 'cubit/parameter_build_cubit/parameter_build_cubit.dart';
import 'cubit/screen_config/screen_config_cubit.dart';
import 'cubit/stack_action/stack_action_cubit.dart';
import 'cubit/user_details/user_details_cubit.dart';
import 'cubit/visual_box_drawer/visual_box_cubit.dart';
import 'data/remote/data_bridge.dart';
import 'data/remote/firestore/firebase_bridge.dart';
import 'generated/l10n.dart';
import 'mode_converters/figma/data/api_client.dart';
import 'mode_converters/figma/data/core/dio_client.dart';
import 'models/variable_model.dart';
import 'ui/feedback/bloc/feedback_bloc.dart';
import 'ui/firebase_connect/cubit/firebase_connect_cubit.dart';
import 'ui/home/cubit/home_cubit.dart';
import 'ui/settings/bloc/settings_bloc.dart';
import 'user_session.dart';

final sl = GetIt.instance;
final theme = ThemeBloc();
late final FvbNavigationBloc fvbNavigationBloc;
late final Processor systemProcessor;
final collection = UserProjectCollection();

final componentGenerator=ComponentGenerator();
final Map<String, ui.Image> uiImageCache = {};

enum PlatformType { desktop, tablet, phone }

PlatformType platform = PlatformType.desktop;
double deviceWidth = 0;
double deviceHeight = 0;

bool get isDesktop => platform == PlatformType.desktop;

bool get isTab => platform == PlatformType.tablet;

bool get isTabAnyOrientation =>
    platform == PlatformType.tablet || isLandscapeTab;

bool get isPhone => platform == PlatformType.phone;

bool get hasTouchInput =>
    isPhone || isTab || isLandscapeTab || isLandscapePhone;

bool get isLandscapeTab =>
    platform == PlatformType.desktop && deviceWidth < 1400;

bool get isLandscapePhone =>
    platform == PlatformType.desktop &&
    deviceWidth != 0 &&
    (deviceHeight / deviceWidth) > 2;
late S i10n;

Future<void> initInjector() async {
  i10n = S();
  systemProcessor = Processor.build(name: 'System', package: 'main');
  systemProcessor.variables['dw'] = VariableModel('dw', DataType.fvbDouble,
      deletable: false,
      isFinal: true,
      description: 'device width',
      uiAttached: true,
      value: 1,
      isDynamic: true);
  systemProcessor.variables['dh'] = VariableModel('dh', DataType.fvbDouble,
      deletable: false,
      uiAttached: true,
      isFinal: true,
      description: 'device height',
      value: 1,
      isDynamic: true);
  sl.registerSingleton<Processor>(systemProcessor, instanceName: 'system');
  sl.registerSingleton<Processor>(
      Processor.build(name: 'MainScope', parent: systemProcessor));
  initializePackages();
  sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance());
  await dataBridge.init();
  sl.registerSingleton<StateManagementBloc>(StateManagementBloc());
  sl.registerSingleton(UserSession());
  sl.registerFactory<CommonSnippets>(() => CommonSnippets());
  sl.registerSingleton<StackActionCubit>(StackActionCubit());
  sl.registerSingleton<EventLogBloc>(EventLogBloc());
  sl.registerSingleton<KeyFireBloc>(KeyFireBloc());
  sl.registerSingleton<ScreenConfigCubit>(ScreenConfigCubit(collection));
  sl.registerFactory<ActionCodeBloc>(() => ActionCodeBloc());
  sl.registerFactory<FirebaseConnectCubit>(() => FirebaseConnectCubit(sl()));
  sl.registerFactory<ComponentDragBloc>(() => ComponentDragBloc());
  sl.registerSingleton<AuthenticationCubit>(AuthenticationCubit(sl(), sl()));
  sl.registerSingleton<UserProjectCollection>(collection);
  sl.registerSingleton<Dio>(DioClient.getInstance(sl()));
  sl.registerFactory<FigmaApiClient>(() => FigmaApiClient(sl()));
  final componentSelectionCubit = SelectionCubit();

  sl.registerSingleton<SelectionCubit>(componentSelectionCubit);
  final componentCreationCubit = CreationCubit(sl());
  sl.registerSingleton<CreationCubit>(componentCreationCubit);
  sl.registerSingleton<ParameterBuildCubit>(
      ParameterBuildCubit(componentSelectionCubit));
  sl.registerSingleton<OperationCubit>(OperationCubit(
      componentSelectionCubit, componentCreationCubit, collection, sl(), sl()));
  sl.registerSingleton<UserDetailsCubit>(
      UserDetailsCubit(sl(), componentSelectionCubit, sl()));
  sl.registerSingleton<FvbNavigationBloc>(
      fvbNavigationBloc = FvbNavigationBloc());
  // if (Platform.isWindows) {
  // sl.registerSingleton<KeyboardEvent>(KeyboardEvent());
  // }
  final _preference = DevicePreviewStorage.preferences();

  sl.registerSingleton<DevicePreviewStorage>(_preference);
  sl.registerSingleton<FVBApiBloc>(FVBApiBloc());
  sl.registerSingleton<VisualBoxCubit>(VisualBoxCubit());
  sl.registerSingleton<ThemeBloc>(theme);
  sl.registerSingleton<DataBridge>(dataBridge);
  sl.registerFactory<FeedbackBloc>(() => FeedbackBloc());
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl()));
  sl.registerFactory<SettingsBloc>(() => SettingsBloc(sl(), sl()));
  sl.registerSingleton(FirebaseStorage.instance);
  materialWidgets.clear();
  materialWidgets.addAll(componentList.keys);
  materialWidgets.addAll(['SearchBar']);
  Processor.init();
}

void initScreenUtils(BuildContext context) {
  platform = (Responsive.isDesktop(context)
      ? PlatformType.desktop
      : (Responsive.isMobile(context)
          ? PlatformType.phone
          : PlatformType.tablet));
  deviceWidth = MediaQuery.of(context).size.width;
  deviceHeight = MediaQuery.of(context).size.height;
  // ScreenUtil.init(context,designSize: res<Size>(context,const Size(1920, 1080),MediaQuery.of(context).size,const Size(960, 1440)),minTextAdapt: true);
}
