import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';

import 'bloc/state_management/state_management_bloc.dart';
import 'common/common_methods.dart';
import 'common/compiler/code_processor.dart';
import 'cubit/stack_action/stack_action_cubit.dart';

final get = GetIt.instance;

void initInjector() {
  get.registerSingleton<StateManagementBloc>(StateManagementBloc());
  get.registerSingleton<StackActionCubit>(StackActionCubit());

  get.registerSingleton<CodeProcessor>(CodeProcessor(
    consoleCallback: (message) {
      doAPIOperation(message,
          stackActionCubit: get<StackActionCubit>(),
          stateManagementBloc: get<StateManagementBloc>());
      return null;
    },
    onError: (error) {
      Fluttertoast.showToast(
          msg: error,
          timeInSecForIosWeb: 9,
          webBgColor: '#ff0000',
          webPosition: 'center',
          gravity: ToastGravity.BOTTOM);
    },
  ));
}
