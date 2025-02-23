import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';

import '../../components/component_impl.dart';
import '../../components/component_list.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/parameter_model.dart';
import '../../models/project_model.dart';
import '../fvb_arch/widgets.dart';

final Set<String> materialWidgets = {};

abstract class PackageAnalyzer {
  static String getPackages(
      FVBProject project, Component? child, String? code) {
    final Set<String> packages = {};
    final package = project.packageName;
    final Set<String> ignoreMaterial = {};
    child?.forEach((p0) {
      if (p0 is CustomComponent) {
        packages.add('package:${package}/ui/common/${p0.fileName}.dart');
        if (materialWidgets.contains(p0.name)) {
          ignoreMaterial.add(p0.name);
        }
      } else if (p0 is CMaterialApp) {
        packages.addAll(project.screens.map((e) => e.import));
      } else if (p0 is CCustomPaint) {
        packages.add('package:${package}/common/painters/${p0.import}.dart');
      } else if (p0 is CLoadingIndicator) {
        packages.add('package:loading_indicator/loading_indicator.dart');
      } else if (p0.import != null) {
        packages.add('package:${package}/common/widgets/${p0.import}.dart');
      }
      final List<CommonParam> commons = [];
      p0.parameters.forEach((element) {
        element.forEach((p0) {
          if (p0 is UsableParam) {
            final common = (p0 as UsableParam).commonParam;
            if (common != null) {
              commons.add(common);
            }
          }
          return false;
        });
      });
      packages.addAll(
          commons.map((e) => 'package:${package}/common/${e.fileName}.dart'));
      return false;
    });

    if (code != null) {
      packages.add('package:${package}/data/apis.dart');
    }
    packages.add('package:${package}/common/extensions.dart');
    if (child == null) {
      for (final custom in project.customComponents) {
        packages.add('package:${package}/ui/common/${custom.fileName}.dart');
        if (materialWidgets.contains(custom.name)) {
          ignoreMaterial.add(custom.name);
        }
      }
    }
    return '''import 'package:flutter/material.dart'${ignoreMaterial.isNotEmpty ? ' hide ${ignoreMaterial.join(',')}' : ''};
    import 'package:google_fonts/google_fonts.dart';
    import 'package:intl/intl.dart';
    import 'dart:convert';
    ${Processor.classes.values.whereType<FVBModelClass>().map((e) => "import 'package:$package/data/models/${e.fileName}.dart';").join()}
    import 'package:flutter_animate/flutter_animate.dart';
    import 'package:ionicons/ionicons.dart';
    ${project.settings.firebaseConnect != null ? "import 'package:${package}/common/firebase_lib.dart';" : ''}
    import 'dart:math';
    import 'package:${package}/dependency/dependency.dart';
    import 'package:${package}/main.dart';
    ${addedWidgets.keys.map((key) => "import 'package:${package}/common/widgets/$key.dart';").join('\n')}
    
    ${packages.map((e) => 'import \'$e\';').join('\n')}
    ''';
  }
}
