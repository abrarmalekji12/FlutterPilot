import 'package:collection/collection.dart';

import '../enums.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../components/component_list.dart';
import '../data/remote/firestore/firebase_bridge.dart';
import '../injector.dart';
import '../models/parameter_model.dart';
import 'component_generator.dart';

class AIPostProcessor {
  Map<String, dynamic> cleanData(dynamic data) {
    return Map<String, dynamic>.from(data);
  }

  Map<String, dynamic> transformStructure(dynamic data) {
    if (!data.containsKey('name') && data.containsKey('children')) {
      if (data['children'].length == 1) {
        data = data['children'][0];
      }
    }
    final result = Map<String, dynamic>.from(data);

    if (data.containsKey('name') && componentCreatedCache.containsKey(data['name'])) {
      result['props'] = {
        ...?data['props'],
        for (final e in Map<String, dynamic>.from(data).entries)
          if (!['name', 'child', 'children', 'childMap', 'childrenMap', 'slots'].contains(e.key)) e.key: e.value
      };

      if (result['name'] == 'ListView.builder') {
        if (result.containsKey('children')) {
          result['name'] = 'ListView';
        } else if (result.containsKey('child')) {
          result['slots'] = {...?result['slots'], 'itemBuilder': result['child']};
          // result.remove('child');
        }
      }

      final comp = componentCreatedCache[data['name']];

      if (comp is CustomNamedHolder) {
        result['childMap'] ??= {};
        result['childrenMap'] ??= {};
        for (final slotEntry in Map.of({...data, ...?data['slots'], ...?data['props']}).entries) {
          if (comp.childMap.containsKey(slotEntry.key)) {
            result['childMap'][slotEntry.key] = slotEntry.value;
          } else if (comp.childrenMap.containsKey(slotEntry.key)) {
            if (slotEntry.value is! List) {
              result['childrenMap'][slotEntry.key] = [slotEntry.value];
            } else {
              result['childrenMap'][slotEntry.key] = slotEntry.value;
            }
          }
        }

        if (data.containsKey('child')) {
          if (comp is CScaffold) {
            result['childMap'] = {'body': data['child']};
          } else if (comp is CAppBar) {
            result['childMap'] = {'title': data['child']};
          }
        } else if (data.containsKey('children')) {
          if (comp.childrenMap.isNotEmpty) {
            result['childrenMap'] = {comp.childrenMap.keys.first: data['children']};
          }
        }

        if (comp is CListTile) {
          if (result['childMap']['trailing'] != null) {
            final trailing = result['childMap']['trailing'];
            if (trailing['name'] == 'Row') {
              trailing['props']?['mainAxisSize'] = 'min';
            }
          }
        } else if (result['name'] == 'DropdownButton') {
          final items = data['childrenMap']?['items'];
          final hint = data['childMap']?['hint'];
          if (items != null && hint == null) {
            final itemText = List.of(items)
                .map<List<String>>((e) => e['child']?['props']?['Text']?.split(' ') ?? [])
                .nonNulls
                .expand((e) => e)
                .toList();
            final Map<String, int> counter = {};
            for (final itemName in itemText) {
              counter[itemName] = (counter[itemName] ?? 0) + 1;
            }
            final list = counter.entries.sorted((e, v) => v.value > e.value ? 1 : 0);
            if (list.isNotEmpty) {
              result['childMap']?['hint'] = {
                'name': 'Text',
                'props': {'Text': 'Select ${list.first.key}'}
              };
            }
          } else {
            result['childMap']?['hint'] = {
              'name': 'Text',
              'props': {'Text': 'Select Option'}
            };
          }
        }

        result.remove('slots');
      } else if (comp is MultiHolder) {
        if (result['props']?['children']!=null) {
          result['children'] = result['props']['children'];
          // result['props'].remove('children');
        }
        if (result['slots']?['children'] != null) {
          result['children'] = result['slots']?['children'];
          // result['slots'].remove('children');
        }
      } else if (comp is Holder) {
        if (result['props']?['child']!=null) {
          result['child'] = result['props']['child'];
          // result['props'].remove('child');
        }
        if (result['slots']?['child'] != null) {
          result['child'] =  Map<String, dynamic>.from(result['slots']['child']);
          // result['slots'].remove('child');
        }
      }
    }

    result.forEach((key, value) {
      if (value is Map) {
        result[key] = Map<String, dynamic>.from(transformStructure(value));
      } else if (value is List) {
        result[key] =
            value.map((e) => Map<String, dynamic>.from(transformStructure(e))).toList(); // Handle lists of maps
      } else if (value is String) {
        result[key] = value.replaceAll('\$', '\\\$');
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Map<String, dynamic> parseComponent(dynamic data) {
    final cleanedData = cleanData(data);
    return modifyStructure(transformStructure(cleanedData));
  }

  Map<String, dynamic> modifyStructure(dynamic data) {
    if (data is! Map) return {}; // Safety check

    final result = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Map) {
        result[key] = Map<String, dynamic>.from(modifyStructure(value)); // Recursively handle nested map
      } else if (value is List) {
        result[key] = value.map((e) => modifyStructure(e)).toList(); // Handle lists of maps
      } else {
        result[key] = value;
      }
    });

    if (data.containsKey('name') && data.containsKey('props')) {
      if (!componentCreatedCache.containsKey(data['name'])) {
        return {};
      }

      result['id'] = randomId;

      // if (data['name'] == 'DropdownButton') {
      //   final items = data['childrenMap']?['items'];
      //   final hint = data['childMap']?['hint'];
      //   if (items != null && hint == null) {
      //     final itemText = List.of(items)
      //         .map<List<String>>((e) => e['child']?['props']?['Text']?.split(' ') ?? [])
      //         .nonNulls
      //         .expand((e) => e)
      //         .toList();
      //     final Map<String, int> counter = {};
      //     for (final itemName in itemText) {
      //       counter[itemName] = (counter[itemName] ?? 0) + 1;
      //     }
      //     final list = counter.entries.sorted((e, v) => v.value > e.value ? 1 : 0);
      //     if (list.isNotEmpty) {
      //       data['childMap']?['hint'] = {
      //         'name': 'Text',
      //         'props': {'Text': 'Select ${list.first.key}'}
      //       };
      //     } else {
      //       data['childMap']?['hint'] = {
      //         'name': 'Text',
      //         'props': {'Text': 'Select'}
      //       };
      //     }
      //
      //     result['childMap']= {...?result['childMap'],'hint':data['childMap']?['hint'] };
      //   }
      // }
      final name = data['name'];
      final Map<String, dynamic> inputParamsUnFiltered = Map<String, dynamic>.from(data['props'] ?? {});
      final Map<String, dynamic> inputParams = {};

      for (final param in inputParamsUnFiltered.entries) {
        if (param.key.contains('.')) {
          final path = param.key.split('.');
          Map<String, dynamic> value = {};
          for (final p in path.reversed) {
            if (value.isEmpty) {
              value[p] = param.value;
            } else {
              value = {
                p: {...?inputParams[p], ...Map.from(value)}
              };
            }
          }
          inputParams.addAll(value);
        } else {
          inputParams[param.key] = param.value != null ? param.value : null;
        }
      }

      if (componentCreatedCache.containsKey(name)) {
        final thatComp = componentCreatedCache[name];
        result.remove('props');
        final lowerParams = covertToLower(inputParams);
        result['parameters'] = convertParamOrientation(lowerParams, thatComp?.parameters ?? []);
        result['defaultParameters'] = convertParamOrientation(lowerParams, thatComp?.defaultParam ?? []);
      }
    }

    return result;
  }

  Component? processMap(Map<String, dynamic> mapData) {
    // if (output.startsWith('```')) {
    //   output = output.substring(output.indexOf('{'), output.length - 3);
    // }
    // output = output.replaceAll('""', '"').replaceAll('"\\"', '"').replaceAll('\\"', '"');
    try {
      // final mapData = jsonDecode(output);

      final Map<String, dynamic>? map = parseComponent(mapData);

      print('==============PARAM_CONVERTED-OUTPUT===================');
      if (map != null) print(prettyJson(map));
      print('==========================================');

      return Component.fromJson(map, collection.project);
    } on Exception catch (e) {
      print('Exception Post Processing : ${e.toString()}');
    } catch (e, stack) {
      print('🔴 Error: $e');
      print('📌 Stack Trace:\n$stack');
    }
    return null;
  }

  Map<String, dynamic> covertToLower(Map<String, dynamic> map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, value) {
      final _k = key.toLowerCase();
      if (value is Map) {
        result[_k] = covertToLower(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[_k] = value;
      } else if (value != null) {
        result[_k] = value.toString();
      }
    });
    return result;
  }

  List<Map<String, dynamic>> convertParamOrientation(Map<String, dynamic> inputParams, List<Parameter?> parameters) {
    final List<Map<String, dynamic>> params = [];

    for (final Parameter? param in parameters) {
      if (param == null) {
        params.add({});
        continue;
      }
      final name = (param.info.getName() ?? param.displayName)?.toLowerCase();
      if (name != null && inputParams.containsKey(name)) {
        switch (param) {
          case ComplexParameter(params: var childParams):
            dynamic paramData = inputParams[name];

            if (paramData is! String) {
              params.add({'params': convertParamOrientation(paramData, childParams)});
            } else if (childParams.length == 1) {
              params.add({
                'params': convertParamOrientation({childParams.first.idName ?? '': paramData}, childParams)
              });
            } else {
              if (param.fromCode(paramData, collection.project)) {
                params.add({
                  'params': param.params.map((e) => {'code': e.compiler.code}).toList()
                });
              }
            }
            break;

          case ChoiceParameter(options: var options, isRequired: var isRequired):
            if (inputParams[name] is String) {
              param.fromCode(inputParams[name], collection.project);
              params.add(param.toJson());
              break;
            }

            var paramData = Map<String, dynamic>.from(inputParams[name] ?? {});
            int? index;
            Parameter? option;

            if (paramData.keys.length == 1 && RegExp(r'^(\w+)\.(\d)$').hasMatch(paramData.keys.first)) {
              final match = RegExp(r'^(\w+)\.(\d)$').firstMatch(paramData.keys.first);
              if (match?.group(1) == name) {
                index = int.tryParse(match?.group(2) ?? '');
                if (index != null && !isRequired) {
                  index = index + 1;
                }
                if (index != null) {
                  option = options[index];
                  paramData = {option.idName ?? '': paramData.values.first};
                }
              }
            } else {
              // dynamic subMap;
              option = options.firstWhereIndexedOrNull((i, param) {
                final optionName = (param.info.getName() ?? param.displayName)?.toLowerCase();

                if (optionName != null && paramData.keys.contains(optionName)) {
                  // subMap = paramData['${optionName ?? i.toString()}'];
                  index = i;
                  return true;
                } else if (param is ComplexParameter) {
                  if (param.params.any((e) => paramData.containsKey(e.info.getName()?.toLowerCase()))) {
                    index = i;
                    return true;
                  }
                }
                return false;
              });
            }
            if (option == null &&
                options
                        .whereNot(
                            (e) => e is NullParameter || (e is ConstantValueParameter && e.paramType == ParamType.none))
                        .length ==
                    1 &&
                paramData.isNotEmpty) {
              if (options.length == 2) {
                option = options.firstWhere(
                    (e) => e is! NullParameter && (e is! ConstantValueParameter || e.paramType != ParamType.none));
                index = options.indexOf(option);
              } else {
                option = options.first;
                index = 0;
              }
            }
            params.add({
              'val': convertParamOrientation(paramData, [option]).firstOrNull,
              'meta': {'choice': index}
            });

            break;
          case ComponentParameter():
            params.add({
              'components': inputParams[name] is List
                  ? inputParams[name].map((e) => modifyStructure(e)).toList()
                  : [modifyStructure(inputParams[name])]
            });
            break;

          case ChoiceValueParameter(options: var options):
            final code = inputParams[name].toString();
            final filteredCode = options.keys.contains(code)
                ? code
                : options.keys.firstWhereOrNull((e) => code.contains(e) || e.contains(code));
            params.add({
              'code': filteredCode,
              'value': filteredCode,
            });
          default:
            if (inputParams[name] is Map) {
              if (inputParams[name].containsKey(name)) {
                inputParams[name] = inputParams[name][name];
              }
            }
            final code = inputParams[name].toString();
            params.add({
              'code': code,
              'value': code,
            });
        }
      } else if (param is ComplexParameter) {
        params.add({'params': convertParamOrientation(inputParams, param.params)});
      } else {
        params.add({});
      }
    }
    return params;
  }
}
