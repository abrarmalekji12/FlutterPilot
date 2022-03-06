import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'common/logger.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constant/app_colors.dart';
import 'enums.dart';
import 'models/other_model.dart';
import 'models/parameter_info_model.dart';
import 'models/parameter_model.dart';

class Parameters {
  static ChoiceParameter paddingParameter() => ChoiceParameter(
        name: 'padding',
        required: false,
        info: NamedParameterInfo('padding'),
        options: [
          SimpleParameter<double>(
              name: 'all',
              info: InnerObjectParameterInfo(
                innerObjectName: 'EdgeInsets.all',
              ),
              evaluate: (value) => EdgeInsets.all(value)),
          ComplexParameter(
            name: 'only',
            info: InnerObjectParameterInfo(
              innerObjectName: 'EdgeInsets.only',
            ),
            params: [
              SimpleParameter<double>(
                name: 'top',
                info: NamedParameterInfo('top'),
              ),
              SimpleParameter<double>(
                name: 'left',
                info: NamedParameterInfo('left'),
              ),
              SimpleParameter<double>(
                name: 'bottom',
                info: NamedParameterInfo('bottom'),
              ),
              SimpleParameter<double>(
                name: 'right',
                info: NamedParameterInfo('right'),
              )
            ],
            evaluate: (List<Parameter> params) {
              return EdgeInsets.only(
                top: params[0].value,
                left: params[1].value,
                bottom: params[2].value,
                right: params[3].value,
              );
            },
          ),
          ComplexParameter(
            name: 'symmetric',
            info: InnerObjectParameterInfo(
              innerObjectName: 'EdgeInsets.symmetric',
            ),
            params: [
              SimpleParameter<double>(
                name: 'horizontal',
                info: NamedParameterInfo('horizontal'),
              ),
              SimpleParameter<double>(
                name: 'vertical',
                info: NamedParameterInfo('vertical'),
              ),
            ],
            evaluate: (List<Parameter> params) {
              return EdgeInsets.symmetric(
                horizontal: params[0].value,
                vertical: params[1].value,
              );
            },
          ),
        ],
      );

  static ChoiceParameter sliverDelegate() => ChoiceParameter(
        options: [
          ComplexParameter(
              params: [
                Parameters.flexParameter()
                  ..withNamedParamInfoAndSameDisplayName('crossAxisCount')
                  ..withRequired(true)
                  ..withDefaultValue(2),
              ],
              evaluate: (params) {
                return SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: params[0].value);
              },
              name: 'Fixed cross count',
              info: InnerObjectParameterInfo(
                  innerObjectName:
                      'SliverGridDelegateWithFixedCrossAxisCount')),
          ComplexParameter(
              params: [
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('maxCrossAxisExtent')
                  ..withRequired(true)
                  ..withDefaultValue(200),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('mainAxisSpacing')
                  ..withRequired(true)
                  ..withDefaultValue(0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('mainAxisSpacing')
                  ..withRequired(true)
                  ..withDefaultValue(0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('childAspectRatio')
                  ..withRequired(true)
                  ..withDefaultValue(1),
              ],
              evaluate: (params) {
                return SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: params[0].value,
                  mainAxisSpacing: params[1].value,
                  crossAxisSpacing: params[2].value,
                  childAspectRatio: params[3].value,
                );
              },
              name: 'By individual width',
              info: InnerObjectParameterInfo(
                  innerObjectName:
                      'SliverGridDelegateWithFixedCrossAxisCount')),
        ],
        required: true,
        info: NamedParameterInfo('sliverDelegate'),
      );

  static ComplexParameter inputDecorationParameter() => ComplexParameter(
          params: [
            Parameters.paddingParameter()
              ..withRequired(true)
              ..withNamedParamInfoAndSameDisplayName('contentPadding'),
            Parameters.textParameter()
              ..withDefaultValue(null)
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('labelText'),
            Parameters.textParameter()
              ..withDefaultValue(null)
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('helperText'),
            Parameters.textParameter()
              ..withDefaultValue(null)
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('hintText'),
            Parameters.googleFontTextStyleParameter()
              ..withInnerNamedParamInfoAndDisplayName(
                  'labelStyle', 'GoogleFonts.getFont'),
            Parameters.googleFontTextStyleParameter()
              ..withInnerNamedParamInfoAndDisplayName(
                  'helperStyle', 'GoogleFonts.getFont'),
            Parameters.googleFontTextStyleParameter()
              ..withInnerNamedParamInfoAndDisplayName(
                  'hintStyle', 'GoogleFonts.getFont'),
            Parameters.textParameter()
              ..withDefaultValue(null)
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('errorText'),
            Parameters.googleFontTextStyleParameter()
              ..withInnerNamedParamInfoAndDisplayName(
                  'errorStyle', 'GoogleFonts.getFont'),
            Parameters.inputBorderParameter(),
            ComponentParameter(
              multiple: false,
              info: NamedParameterInfo('icon'),
            ),
            ComponentParameter(
              multiple: false,
              info: NamedParameterInfo('prefixIcon'),
            ),
            ComponentParameter(
              multiple: false,
              info: NamedParameterInfo('suffixIcon'),
            ),
            Parameters.colorParameter()
              ..withNamedParamInfoAndSameDisplayName('iconColor'),
            Parameters.textParameter()
              ..withNamedParamInfoAndSameDisplayName('prefixText'),
            Parameters.googleFontTextStyleParameter()
              ..withInnerNamedParamInfoAndDisplayName(
                  'prefixStyle', 'GoogleFonts.getFont'),
            Parameters.textParameter()
              ..withNamedParamInfoAndSameDisplayName('suffixText'),
            Parameters.googleFontTextStyleParameter()
              ..withInnerNamedParamInfoAndDisplayName(
                  'suffixStyle', 'GoogleFonts.getFont'),
            Parameters.inputBorderParameter()
              ..withNamedParamInfoAndSameDisplayName('enabledBorder'),
            Parameters.colorParameter()
              ..withNamedParamInfoAndSameDisplayName('fillColor')
              ..withRequired(false),
            Parameters.enableParameter()
          ],
          evaluate: (params) {
            return InputDecoration(
              contentPadding: params[0].value,
              labelText: params[1].value,
              helperText: params[2].value,
              hintText: params[3].value,
              labelStyle: params[4].value,
              helperStyle: params[5].value,
              hintStyle: params[6].value,
              errorText: params[7].value,
              errorStyle: params[8].value,
              border: params[9].value,
              icon: (params[10] as ComponentParameter).build(),
              prefixIcon: (params[11] as ComponentParameter).build(),
              suffixIcon: (params[12] as ComponentParameter).build(),
              iconColor: params[13].value,
              prefixText: params[14].value,
              prefixStyle: params[15].value,
              suffixText: params[16].value,
              suffixStyle: params[17].value,
              enabledBorder: params[18].value,
              fillColor: params[19].value,
              enabled: params[20].value,
            );
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'InputDecoration',
              namedIfHaveAny: 'decoration'));

  static ChoiceParameter inputBorderParameter() => ChoiceParameter(options: [
        Parameters.underlineInputBorderParameter(),
        Parameters.outlineInputBorderParameter(),
      ], required: false, info: NamedParameterInfo('border'));

  static ComplexParameter underlineInputBorderParameter() => ComplexParameter(
          params: [
            Parameters.borderRadiusParameter()..withRequired(true),
            Parameters.borderSideParameter(),
          ],
          evaluate: (params) {
            return UnderlineInputBorder(
              borderRadius: params[0].value,
              borderSide: params[1].value,
            );
          },
          info:
              InnerObjectParameterInfo(innerObjectName: 'UnderlineInputBorder'),
          name: 'underline-border');

  static ComplexParameter outlineInputBorderParameter() => ComplexParameter(
          params: [
            Parameters.borderRadiusParameter()..withRequired(true),
            Parameters.borderSideParameter(),
            Parameters.widthParameter()
              ..withNamedParamInfoAndSameDisplayName('gapPadding')
              ..withDefaultValue(0)
              ..withRequired(true)
          ],
          evaluate: (params) {
            return OutlineInputBorder(
              borderRadius: params[0].value,
              borderSide: params[1].value,
              gapPadding: params[2].value,
            );
          },
          info: InnerObjectParameterInfo(innerObjectName: 'OutlineInputBorder'),
          name: 'outline-border');

  static ComplexParameter roundedRectangleBorderParameter() => ComplexParameter(
          params: [
            Parameters.borderRadiusParameter()..withRequired(true),
            Parameters.borderSideParameter()
              ..withInfo(NamedParameterInfo('side')),
          ],
          evaluate: (params) {
            return RoundedRectangleBorder(
              borderRadius: params[0].value,
              side: params[1].value,
            );
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'RoundedRectangleBorder'),
          name: 'rounded-rectangle-border');

  static ComplexParameter decorationParameter() => ComplexParameter(
        params: [
          colorParameter()..withRequired(false),
          borderRadiusParameter(),
          borderParameter(),
          gradientParameter(),
          boxShadowListParameter(),
          boxShapeParameter(),
        ],
        name: 'decoration',
        evaluate: (params) {
          return BoxDecoration(
              color: params[0].value,
              borderRadius: params[1].value,
              border: params[2].value,
              gradient: params[3].value,
              boxShadow: params[4].value,
              shape: params[5].value);
        },
        info: InnerObjectParameterInfo(
            innerObjectName: 'BoxDecoration', namedIfHaveAny: 'decoration'),
      );

  static borderParameter() => ChoiceParameter(
        name: 'border',
        required: false,
        info: NamedParameterInfo('border'),
        options: [
          ComplexParameter(
            info: InnerObjectParameterInfo(
              innerObjectName: 'Border.all',
            ),
            params: [
              colorParameter()..withDefaultValue(const Color(0xffffffff)),
              widthParameter()
                ..withDisplayName('stroke-width')
                ..withDefaultValue(2)
                ..withRequired(true),
            ],
            name: 'all',
            evaluate: (params) => Border.all(
              color: params[0].value,
              width: params[1].value,
            ),
          ),
          ComplexParameter(
            info: InnerObjectParameterInfo(innerObjectName: 'Border'),
            params: [
              Parameters.borderSideParameter()
                ..withInfo(NamedParameterInfo('left'))
                ..withDisplayName('left'),
              Parameters.borderSideParameter()
                ..withInfo(NamedParameterInfo('top'))
                ..withDisplayName('top'),
              Parameters.borderSideParameter()
                ..withInfo(NamedParameterInfo('right'))
                ..withDisplayName('right'),
              Parameters.borderSideParameter()
                ..withInfo(NamedParameterInfo('bottom'))
                ..withDisplayName('bottom'),
            ],
            name: 'only',
            evaluate: (params) => Border(
                left: params[0].value,
                top: params[1].value,
                right: params[2].value,
                bottom: params[3].value),
          ),
        ],
      );

  static Parameter alignmentParameter() => ChoiceValueParameter(
      name: 'alignment',
      options: {
        'centerLeft': Alignment.centerLeft,
        'center': Alignment.center,
        'centerRight': Alignment.centerRight,
        'topCenter': Alignment.topCenter,
        'bottomCenter': Alignment.bottomCenter,
        'topLeft': Alignment.topLeft,
        'topRight': Alignment.topRight,
        'bottomLeft': Alignment.bottomLeft,
        'bottomRight': Alignment.bottomRight,
      },
      defaultValue: 'center',
      info: NamedParameterInfo('alignment'));

  static Parameter tileModeParameter() => ChoiceValueParameter(
      name: 'tile-mode',
      options: {
        'clamp': TileMode.clamp,
        'mirror': TileMode.mirror,
        'decal': TileMode.decal,
        'repeated': TileMode.repeated,
      },
      defaultValue: 'clamp',
      info: NamedParameterInfo('tileMode'));

  static Parameter stackFitParameter() => ChoiceValueParameter(
      name: 'fit',
      options: {
        'expand': StackFit.expand,
        'loose': StackFit.loose,
        'passThrough': StackFit.passthrough,
      },
      defaultValue: 'loose',
      info: NamedParameterInfo('alignment'));

  static Parameter iconParameter() => ChoiceValueParameter(
      name: 'Choose icon',
      getCode: (key) {
        return 'Icons.$key';
      },
      fromCodeToKey: (code) {
        return code.substring(code.indexOf('.') + 1);
      },
      options: {
        'close': Icons.close,
        'add': Icons.add,
        'delete': Icons.delete,
        'arrow_back': Icons.arrow_back,
        'arrow_back_ios': Icons.arrow_back_ios,
        'arrow_forward': Icons.arrow_forward,
        'arrow_forward_ios': Icons.arrow_forward_ios,
        'image': Icons.image,
        'remove': Icons.remove,
        'create': Icons.create,
        'cloud': Icons.cloud,
        'settings': Icons.settings,
        'refresh': Icons.refresh,
        'call': Icons.call,
        'shopping_cart': Icons.shopping_cart,
        'event': Icons.event,
        'code': Icons.code,
        'info': Icons.info,
        'list': Icons.list,
        'menu': Icons.menu,
        'notifications': Icons.notifications,
        'wifi': Icons.wifi,
        'comment_rounded': Icons.comment_rounded,
        'apps': Icons.apps,
        'arrow_drop_down_rounded': Icons.arrow_drop_down_rounded,
        'visibility_rounded': Icons.visibility_rounded,
        'visibility_off': Icons.visibility_off,
        'star': Icons.star,
        'star_border': Icons.star_border,
        'person': Icons.person,
        'done': Icons.done,
        'lock': Icons.lock,
        'mail': Icons.mail,
        'mail_outline': Icons.mail_outline,
        'work': Icons.work,
      },
      defaultValue: 'close',
      required: true);

  static Parameter textAlignParameter() => ChoiceValueParameter(
      name: 'alignment',
      options: {
        'center': TextAlign.center,
        'left': TextAlign.left,
        'right': TextAlign.right,
        'start': TextAlign.start,
        'end': TextAlign.end,
        'justify': TextAlign.justify,
      },
      defaultValue: 'left',
      info: NamedParameterInfo('textAlign'));

  static Parameter blurStyleParameter() => ChoiceValueParameter(
      name: 'blur-style',
      options: {
        'solid': BlurStyle.solid,
        'normal': BlurStyle.normal,
        'inner': BlurStyle.inner,
        'outer': BlurStyle.outer,
      },
      defaultValue: 'normal',
      info: NamedParameterInfo('blurStyle'));

  static Parameter boxShapeParameter() => ChoiceValueParameter(
      name: 'shape',
      options: {
        'rectangle': BoxShape.rectangle,
        'circle': BoxShape.circle,
      },
      defaultValue: 'rectangle',
      info: NamedParameterInfo('shape'));

  static marginParameter() => paddingParameter()
    ..withDisplayName('margin')
    ..withInfo(NamedParameterInfo('margin'));

  static SimpleParameter colorParameter() => SimpleParameter<Color>(
        name: 'color',
        defaultValue: AppColors.white,
        inputType: ParamInputType.color,
        info: NamedParameterInfo('color'),
      );

  static ComplexParameter themeDataParameter() => ComplexParameter(
          params: [
            Parameters.backgroundColorParameter(),
            Parameters.colorParameter()
              ..withRequired(false)
              ..inputCalculateAs =
                  ((color, forward) => (color as Color).withAlpha(255))
              ..withNamedParamInfoAndSameDisplayName('primaryColor'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('secondaryHeaderColor'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('primaryColorLight'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('primaryColorDark'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('cardColor'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('focusColor'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('hoverColor'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('splashColor'),
            Parameters.colorParameter()
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('hintColor'),
          ],
          evaluate: (params) {
            return ThemeData(
                backgroundColor: params[0].value,
                primaryColor: params[1].value,
                secondaryHeaderColor: params[2].value,
                primaryColorLight: params[3].value,
                primaryColorDark: params[4].value,
                cardColor: params[5].value,
                focusColor: params[6].value,
                hoverColor: params[7].value,
                splashColor: params[8].value,
                hintColor: params[9].value,
                visualDensity: VisualDensity.comfortable);
          },
          name: 'Theme',
          info: InnerObjectParameterInfo(innerObjectName: 'ThemeData'));

  static SimpleParameter backgroundColorParameter() => colorParameter()
    ..withDisplayName('background-color')
    ..withRequired(false)
    ..withInfo(NamedParameterInfo('backgroundColor'));

  static SimpleParameter foregroundColorParameter() => colorParameter()
    ..withDisplayName('foreground-color')
    ..withRequired(false)
    ..withInfo(NamedParameterInfo('foregroundColor'));

  static wrapAlignmentParameter() => ChoiceValueParameter(
        name: 'wrap-alignment',
        options: {
          'start': WrapAlignment.start,
          'center': WrapAlignment.center,
          'end': WrapAlignment.end,
          'spaceBetween': WrapAlignment.spaceBetween,
          'spaceAround': WrapAlignment.spaceAround,
          'spaceEvenly': WrapAlignment.spaceEvenly,
        },
        info: NamedParameterInfo('alignment'),
        defaultValue: 'start',
      );

  static wrapCrossAxisAlignmentParameter() => ChoiceValueParameter(
        name: 'wrap-cross-alignment',
        options: {
          'start': WrapCrossAlignment.start,
          'center': WrapCrossAlignment.center,
          'end': WrapCrossAlignment.end,
        },
        info: NamedParameterInfo('crossAxisAlignment'),
        defaultValue: 'start',
      );

  static themeModeParameter() => ChoiceValueParameter(
        name: 'theme Mode',
        options: {
          'light': ThemeMode.light,
          'dark': ThemeMode.dark,
          'system': ThemeMode.system,
        },
        info: NamedParameterInfo('themeMode'),
        defaultValue: 'system',
      );

  static mainAxisAlignmentParameter() => ChoiceValueParameter(
        name: 'mainAxisAlignment',
        options: {
          'start': MainAxisAlignment.start,
          'center': MainAxisAlignment.center,
          'end': MainAxisAlignment.end,
          'spaceBetween': MainAxisAlignment.spaceBetween,
          'spaceAround': MainAxisAlignment.spaceAround,
          'spaceEvenly': MainAxisAlignment.spaceEvenly,
        },
        info: NamedParameterInfo('mainAxisAlignment'),
        defaultValue: 'start',
      );

  static crossAxisAlignmentParameter() => ChoiceValueParameter(
        name: 'crossAxisAlignment',
        options: {
          'start': CrossAxisAlignment.start,
          'center': CrossAxisAlignment.center,
          'end': CrossAxisAlignment.end,
          'stretch': CrossAxisAlignment.stretch,
          'baseline': CrossAxisAlignment.baseline,
        },
        defaultValue: 'center',
        info: NamedParameterInfo('crossAxisAlignment'),
      );

  static mainAxisSizeParameter() => ChoiceValueParameter(
        name: 'mainAxisSize',
        options: {
          'max': MainAxisSize.max,
          'min': MainAxisSize.min,
        },
        defaultValue: 'max',
        info: NamedParameterInfo('mainAxisSize'),
      );

  static ChoiceValueParameter axisParameter() => ChoiceValueParameter(
        name: 'direction',
        options: {'vertical': Axis.vertical, 'horizontal': Axis.horizontal},
        defaultValue: 'vertical',
        info: NamedParameterInfo('direction'),
      );

  static Parameter borderRadiusParameter() => ChoiceParameter(
        name: 'borderRadius',
        info: NamedParameterInfo('borderRadius'),
        required: false,
        options: [
          SimpleParameter<double>(
              name: 'circular',
              info: InnerObjectParameterInfo(
                  innerObjectName: 'BorderRadius.circular'),
              evaluate: (value) {
                return BorderRadius.circular(value);
              }),
          ComplexParameter(
            info:
                InnerObjectParameterInfo(innerObjectName: 'BorderRadius.only'),
            params: [
              SimpleParameter<double>(
                  name: 'topLeft',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'topLeft')),
              SimpleParameter<double>(
                  name: 'bottomLeft',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'bottomLeft')),
              SimpleParameter<double>(
                  name: 'topRight',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'topRight')),
              SimpleParameter<double>(
                  name: 'bottomRight',
                  info: InnerObjectParameterInfo(
                      innerObjectName: 'Radius.circular',
                      namedIfHaveAny: 'bottomRight')),
            ],
            evaluate: (List<Parameter> params) {
              return BorderRadius.only(
                topLeft: Radius.circular(params[0].value),
                bottomLeft: Radius.circular(params[1].value),
                topRight: Radius.circular(params[2].value),
                bottomRight: Radius.circular(params[3].value),
              );
            },
            name: 'only',
          )
        ],
      );

  static gradientParameter() => ChoiceParameter(
          options: [
            linearGradientParameter(),
            radialGradientParameter(),
          ],
          name: 'gradient',
          required: false,
          info: NamedParameterInfo('gradient'));

  static linearGradientParameter() => ComplexParameter(
          params: [
            colorListParameter(),
            alignmentParameter()..withNamedParamInfoAndSameDisplayName('begin'),
            alignmentParameter()..withNamedParamInfoAndSameDisplayName('end'),
            doubleListParameter()
              ..withNamedParamInfoAndSameDisplayName('stops'),
            tileModeParameter()
          ],
          name: 'linear gradient',
          info: InnerObjectParameterInfo(innerObjectName: 'LinearGradient'),
          evaluate: (params) {
            return LinearGradient(
              colors: params[0].value,
              begin: params[1].value,
              end: params[2].value,
              stops: params[3].value,
              tileMode: params[4].value,
            );
          });

  static radialGradientParameter() => ComplexParameter(
          params: [
            colorListParameter(),
            radiusParameter()
              ..withDefaultValue(0.5)
              ..withRequired(true),
            doubleListParameter()
              ..withNamedParamInfoAndSameDisplayName('stops'),
            alignmentParameter()
              ..withNamedParamInfoAndSameDisplayName('center'),
            tileModeParameter()
          ],
          name: 'radial gradient',
          info: InnerObjectParameterInfo(innerObjectName: 'RadialGradient'),
          evaluate: (params) {
            logger('HIIII  ${params[0].value}');
            return RadialGradient(
              colors: params[0].value,
              radius: params[1].value,
              stops: params[2].value,
              center: params[3].value,
              tileMode: params[4].value,
            );
          });

  static Parameter boxShadowParameter() => ComplexParameter(
          params: [
            colorParameter(),
            offsetParameter(),
            directionParameter()
              ..withRequired(true)
              ..withNamedParamInfoAndSameDisplayName('blurRadius'),
            directionParameter()
              ..withRequired(true)
              ..withNamedParamInfoAndSameDisplayName('spreadRadius'),
            blurStyleParameter(),
          ],
          info: InnerObjectParameterInfo(innerObjectName: 'BoxShadow'),
          evaluate: (params) {
            return BoxShadow(
                color: params[0].value,
                offset: params[1].value,
                blurRadius: params[2].value,
                spreadRadius: params[3].value,
                blurStyle: params[4].value);
          });

  static Parameter boxShadowListParameter() => ListParameter<BoxShadow>(
        parameterGenerator: () => boxShadowParameter(),
        displayName: 'box-shadow',
        required: false,
        info: NamedParameterInfo('boxShadow'),
      );

  static colorListParameter() => ListParameter<Color>(
        displayName: 'colors',
        initialParams: [
          colorParameter()
            ..withInfo(null)
            ..withDefaultValue(AppColors.black),
          colorParameter()
            ..withInfo(null)
            ..withDefaultValue(AppColors.white)
        ],
        parameterGenerator: () => colorParameter()..withInfo(null),
        info: NamedParameterInfo('colors'),
      );

  static Parameter doubleListParameter() => ListParameter<double>(
      parameterGenerator: () => widthParameter()
        ..withRequired(false)
        ..withInfo(null)
        ..withDisplayName('stop-point'),
      required: false);

  static SimpleParameter directionParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('direction'),
      name: 'direction',
      required: false,
      defaultValue: 0);

  static SimpleParameter widthParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('width'),
      name: 'width',
      required: false,
      defaultValue: 100);

  static ComplexParameter offsetParameter() => ComplexParameter(
          info: InnerObjectParameterInfo(
              namedIfHaveAny: 'offset', innerObjectName: 'Offset'),
          name: 'offset',
          evaluate: (params) {
            return Offset(params[0].value, params[1].value);
          },
          params: [
            directionParameter()
              ..withRequired(true)
              ..withInfo(null)
              ..withDisplayName('X'),
            directionParameter()
              ..withRequired(true)
              ..withInfo(null)
              ..withDisplayName('Y')
          ]);

  static ComplexParameter sizeParameter() => ComplexParameter(
          info: InnerObjectParameterInfo(
              namedIfHaveAny: 'preferredSize', innerObjectName: 'Size'),
          name: 'size',
          evaluate: (params) {
            return Size(params[0].value, params[1].value);
          },
          params: [
            directionParameter()
              ..withRequired(true)
              ..withInfo(null)
              ..withDisplayName('width'),
            directionParameter()
              ..withRequired(true)
              ..withInfo(null)
              ..withDisplayName('height')
          ]);

  static SimpleParameter heightParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('height'),
      name: 'height',
      required: false,
      defaultValue: 100);

  static Parameter boxFitParameter() => ChoiceValueParameter(
          options: {
            'none': BoxFit.none,
            'fill': BoxFit.fill,
            'fitWidth': BoxFit.fitWidth,
            'fitHeight': BoxFit.fitHeight,
            'contain': BoxFit.contain,
            'scaleDown': BoxFit.scaleDown,
            'cover': BoxFit.cover,
          },
          defaultValue: 'none',
          info: NamedParameterInfo('fit'),
          name: 'box-fit');

  static SimpleParameter thicknessParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('thickness'),
      name: 'thickness',
      required: false,
      defaultValue: 1);

  static SimpleParameter radiusParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('radius'),
      name: 'radius',
      required: false,
      defaultValue: 30);

  static SimpleParameter flexParameter() => SimpleParameter<int>(
      info: NamedParameterInfo('flex'),
      name: 'flex',
      required: true,
      defaultValue: 1);

  static ChoiceParameter borderSideParameter() => ChoiceParameter(
        info: NamedParameterInfo('borderSide'),
        required: true,
        name: 'Border',
        options: [
          ConstantValueParameter(
              displayName: 'none',
              constantValue: BorderSide.none,
              constantValueInString: 'BorderSide.none',
              paramType: ParamType.other),
          ComplexParameter(
              name: 'enable',
              info: InnerObjectParameterInfo(
                innerObjectName: 'BorderSide',
              ),
              params: [
                colorParameter(),
                widthParameter()
                  ..withDisplayName('stroke-width')
                  ..withRequired(true)
                  ..withDefaultValue(2)
              ],
              evaluate: (params) {
                return BorderSide(
                  color: params[0].value,
                  width: params[1].value,
                );
              }),
        ],
      );

  static shapeBorderParameter() => ChoiceParameter(
      required: true,
      options: [
        NullParameter(displayName: 'None'),
        ComplexParameter(
          name: 'Round Rectangular Border',
          params: [
            borderRadiusParameter()..withRequired(true),
            borderSideParameter()..withInfo(NamedParameterInfo('side')),
          ],
          evaluate: (params) {
            return RoundedRectangleBorder(
                borderRadius: params[0].value, side: params[1].value);
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'RoundedRectangleBorder'),
        )
      ],
      name: 'Shape Border',
      info: NamedParameterInfo('shape'));

  static SimpleParameter angleParameter() => SimpleParameter<double>(
      defaultValue: 0,
      inputType: ParamInputType.text,
      name: 'angle',
      required: true,
      inputCalculateAs: (value, forward) {
        if (forward) {
          return value * pi / 360;
        }
        return (value * 360 / pi).toDouble();
      },
      info: NamedParameterInfo('angle'));

  static SimpleParameter widthFactorParameter() => SimpleParameter<double>(
      defaultValue: null,
      inputType: ParamInputType.sliderZeroToOne,
      name: 'width factor',
      required: false,
      info: NamedParameterInfo('widthFactor'));

  static SimpleParameter heightFactorParameter() => SimpleParameter<double>(
      defaultValue: null,
      inputType: ParamInputType.sliderZeroToOne,
      name: 'height factor',
      required: false,
      info: NamedParameterInfo('heightFactor'));

  static SimpleParameter elevationParameter() => SimpleParameter<double>(
      defaultValue: 1,
      required: false,
      info: NamedParameterInfo('elevation'),
      name: 'elevation');
  static final toolbarHeight = heightParameter()
    ..withRequired(true)
    ..withDisplayName('toolbar-height')
    ..withInfo(NamedParameterInfo('toolbarHeight'))
    ..withDefaultValue(55);

  static Parameter textSpanParameter() => ChoiceParameter(
          options: [
            ComplexParameter(
                params: [
                  textParameter()..withInfo(NamedParameterInfo('text')),
                  googleFontTextStyleParameter(),
                ],
                evaluate: (params) =>
                    TextSpan(text: params[0].value, style: params[1].value),
                name: 'Text'),
            ComplexParameter(
                params: [
                  ListParameter(
                    parameterGenerator: textSpanParameter,
                    displayName: 'text list',
                  )
                ],
                info: NamedParameterInfo('children'),
                evaluate: (params) {
                  final List<InlineSpan> list = (params[0].value as List)
                      .map<InlineSpan>((e) => e as InlineSpan)
                      .toList();
                  return TextSpan(children: list);
                },
                name: 'Add Multiple Text')
          ],
          info: InnerObjectParameterInfo(
              innerObjectName: 'TextSpan', namedIfHaveAny: 'children'));

  static SimpleParameter textParameter() => SimpleParameter<String>(
      name: 'text',
      defaultValue: '',
      inputType: ParamInputType.longText,
      required: true);

  static SimpleParameter shortStringParameter() => SimpleParameter<String>(
      name: 'text',
      defaultValue: '',
      inputType: ParamInputType.longText,
      required: true);

  static Parameter imageParameter() => SimpleParameter<ImageData>(
      name: 'Choose image',
      required: false,
      defaultValue: null,
      inputType: ParamInputType.image);

  static Parameter googleFontTypeParameter() {
    return ChoiceValueListParameter<String>(
        options: GoogleFonts.asMap().keys.toList(),
        defaultValue: 0,
        name: 'Font - Family',
        dynamicChild: (value) {
          return Text(
            value,
            style: GoogleFonts.getFont(
              value,
              textStyle: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          );
        });
  }

  static BooleanParameter italicParameter() => BooleanParameter(
        displayName: 'italic',
        required: false,
        val: false,
        evaluate: (val) => val ? 'FontStyle.italic' : 'FontStyle.normal',
        info: NamedParameterInfo('fontStyle'),
      );

  static BooleanParameter enableParameter() => BooleanParameter(
        displayName: 'enable',
        required: true,
        val: true,
        info: NamedParameterInfo('enabled'),
      );

  static Parameter textStyleParameter() => ComplexParameter(
        info: InnerObjectParameterInfo(
            innerObjectName: 'TextStyle', namedIfHaveAny: 'textStyle'),
        params: [
          SimpleParameter<double>(
              name: 'font-size',
              info: NamedParameterInfo('fontSize'),
              defaultValue: 13),
          Parameters.colorParameter()..withDefaultValue(AppColors.black),
          ChoiceValueParameter(
            options: {
              'w200': FontWeight.w200,
              'w300': FontWeight.w300,
              'w400': FontWeight.w400,
              'w500': FontWeight.w500,
              'normal': FontWeight.normal,
              'w600': FontWeight.w600,
              'w700': FontWeight.w700,
              'w800': FontWeight.w800,
              'w900': FontWeight.w900,
              'bold': FontWeight.bold
            },
            defaultValue: 'normal',
            name: 'fontWeight',
            info: NamedParameterInfo('fontWeight'),
          ),
          italicParameter()
        ],
        name: 'Style',
        evaluate: (params) {
          return TextStyle(
              fontSize: params[0].value,
              color: params[1].value,
              fontWeight: params[2].value,
              fontStyle: params[3].value ? FontStyle.italic : FontStyle.normal);
        },
      );

  static Parameter googleFontTextStyleParameter() => ComplexParameter(
      info: InnerObjectParameterInfo(
          innerObjectName: 'GoogleFonts.getFont', namedIfHaveAny: 'style'),
      params: [googleFontTypeParameter(), textStyleParameter()],
      evaluate: (params) {
        return GoogleFonts.getFont(params[0].value, textStyle: params[1].value);
      });

  static ComplexParameter materialStatePropertyParameter<T>(
          Parameter parameter, String named) =>
      ComplexParameter(
          params: [parameter],
          evaluate: (params) {
            return MaterialStateProperty.all<T>(params[0].value);
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'MaterialStateProperty.all',
              namedIfHaveAny: named));

  static buttonStyleParameter() => ComplexParameter(
          params: [
            materialStatePropertyParameter<Color?>(
                backgroundColorParameter()..withChangeNamed(null),
                'backgroundColor'),
            materialStatePropertyParameter<Color?>(
                foregroundColorParameter()..withChangeNamed(null),
                'foregroundColor'),
            alignmentParameter(),
            materialStatePropertyParameter<TextStyle>(
                googleFontTextStyleParameter()..withChangeNamed(null),
                'textStyle'),
            materialStatePropertyParameter<EdgeInsets?>(
                paddingParameter()..withChangeNamed(null), 'padding'),
            materialStatePropertyParameter<BorderSide?>(
                borderSideParameter()..withChangeNamed(null), 'side'),
          ],
          evaluate: (params) {
            return ButtonStyle(
              backgroundColor: params[0].value,
              foregroundColor: params[1].value,
              alignment: params[2].value,
              textStyle: params[3].value,
              padding: params[4].value,
              side: params[5].value,
            );
          });

  static bottomNavigationItem() => ComplexParameter(
          params: [
            ComponentParameter(
              multiple: false,
              info: NamedParameterInfo('icon'),
            )
          ],
          evaluate: (params) {
            return BottomNavigationBarItem(
                icon: (params[0] as ComponentParameter).build());
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'BottomNavigationBarItem'));

  static bottomNavigationBarItems() => ListParameter(
        info: NamedParameterInfo('items'),
        parameterGenerator: () {
          return bottomNavigationItem();
        },
      );

  static filterParameter() => ComplexParameter(
          params: [
            Parameters.widthParameter()

              ..withRequired(true)
              ..withDefaultValue(0.1)
              ..withNamedParamInfoAndSameDisplayName('sigmaX'),
            Parameters.widthParameter()
            ..withRequired(true)
              ..withDefaultValue(0.1)
              ..withNamedParamInfoAndSameDisplayName('sigmaY')
          ],
          evaluate: (params) {
            return ImageFilter.blur(
                sigmaX: params[0].value, sigmaY: params[1].value);
          },
          info: InnerObjectParameterInfo(
              innerObjectName: 'ImageFilter.blur', namedIfHaveAny: 'filter'));
}
