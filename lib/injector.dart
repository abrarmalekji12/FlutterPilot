import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:win_toast/win_toast.dart';

import 'bloc/state_management/state_management_bloc.dart';
import 'common/common_methods.dart';
import 'common/compiler/code_processor.dart';
import 'common/io_lib.dart';
import 'cubit/authentication/authentication_cubit.dart';
import 'cubit/component_creation/component_creation_cubit.dart';
import 'cubit/component_operation/component_operation_cubit.dart';
import 'cubit/flutter_project/flutter_project_cubit.dart';
import 'cubit/stack_action/stack_action_cubit.dart';
final get = GetIt.instance;

void initInjector() {
  if(Platform.isWindows){
    WinToast.instance().initialize(appName: 'Flutter Visual Builder',
        productName: 'Flutter Visual Builder', companyName: 'AMSoftwares');
  }
  get.registerSingleton<StateManagementBloc>(StateManagementBloc());
  get.registerSingleton<StackActionCubit>(StackActionCubit());
  get.registerSingleton<AuthenticationCubit>(AuthenticationCubit());
  get.registerSingleton<FlutterProjectCubit>(FlutterProjectCubit());
  get.registerSingleton<ComponentOperationCubit>(ComponentOperationCubit());
  get.registerSingleton<ComponentCreationCubit>(ComponentCreationCubit());


  get.registerSingleton<CodeProcessor>(CodeProcessor.build());
}

