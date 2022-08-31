import 'package:device_preview/device_preview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:keyboard_event/keyboard_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win_toast/win_toast.dart';

import 'bloc/action_code/action_code_bloc.dart';
import 'bloc/api_bloc/api_bloc.dart';
import 'bloc/error/error_bloc.dart';
import 'bloc/key_fire/key_fire_bloc.dart';
import 'bloc/state_management/state_management_bloc.dart';
import 'common/common_methods.dart';
import 'common/compiler/code_processor.dart';
import 'common/io_lib.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'cubit/component_creation/component_creation_cubit.dart';
import 'cubit/component_operation/component_operation_cubit.dart';
import 'cubit/component_selection/component_selection_cubit.dart';
import 'cubit/flutter_project/flutter_project_cubit.dart';
import 'cubit/stack_action/stack_action_cubit.dart';

final get = GetIt.instance;

void initInjector() async {
  if (Platform.isWindows) {
    WinToast.instance().initialize(
        appName: 'Flutter Visual Builder',
        productName: 'Flutter Visual Builder',
        companyName: 'AMSoftwares');
  }

  get.registerSingleton<CodeProcessor>(CodeProcessor.build(name: 'MainScope'));
  get.registerSingleton<StateManagementBloc>(StateManagementBloc());
  get.registerSingleton<StackActionCubit>(StackActionCubit());
  get.registerSingleton<ErrorBloc>(ErrorBloc());
  if (Platform.isWindows) {
    get.registerSingleton<KeyboardEvent>(KeyboardEvent());
  }
  get.registerSingleton<KeyFireBloc>(KeyFireBloc());
  get.registerFactory<ActionCodeBloc>(() => ActionCodeBloc());
  get.registerSingleton<AuthenticationCubit>(AuthenticationCubit());
  get.registerSingleton<FlutterProjectCubit>(FlutterProjectCubit());
  get.registerSingleton<ComponentOperationCubit>(ComponentOperationCubit());

  get.registerSingleton<ComponentSelectionCubit>(ComponentSelectionCubit());
  get.registerSingleton<ComponentCreationCubit>(ComponentCreationCubit(get()));
  final _preference = DevicePreviewStorage.preferences();
  get.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance());
  get.registerSingleton<DevicePreviewStorage>(_preference);
  get.registerSingleton<ApiBloc>(ApiBloc());

}
