import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'common/compiler/painter.dart';
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
            evaluate: (value) => EdgeInsets.all(value),
          ),
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

  static SimpleParameter get durationParameter => SimpleParameter(
        name: 'duration',
        required: true,
        defaultValue: Duration.zero,
        info: NamedParameterInfo('duration'),
      )..compiler.code = 'Duration(milliseconds: 500)';

  static SimpleParameter get curveParameter => SimpleParameter(
        name: 'curve',
        required: true,
        info: NamedParameterInfo('curve'),
      )..compiler.code = 'Curves.linear';

  static ChoiceParameter sliverDelegate() => ChoiceParameter(
        options: [
          ComplexParameter(
              params: [
                Parameters.flexParameter()
                  ..withNamedParamInfoAndSameDisplayName('crossAxisCount')
                  ..withRequired(true)
                  ..withDefaultValue(2),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('mainAxisSpacing')
                  ..withRequired(true)
                  ..withDefaultValue(0.0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('crossAxisSpacing')
                  ..withRequired(true)
                  ..withDefaultValue(0.0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('childAspectRatio')
                  ..withRequired(true)
                  ..withDefaultValue(1.0),
              ],
              evaluate: (params) {
                return SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: params[0].value,
                  mainAxisSpacing: params[1].value,
                  crossAxisSpacing: params[2].value,
                  childAspectRatio: params[3].value,
                );
              },
              name: 'Fixed cross count',
              info: InnerObjectParameterInfo(innerObjectName: 'SliverGridDelegateWithFixedCrossAxisCount')),
          ComplexParameter(
              params: [
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('maxCrossAxisExtent')
                  ..withRequired(true)
                  ..withDefaultValue(200.0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('mainAxisSpacing')
                  ..withRequired(true)
                  ..withDefaultValue(0.0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('crossAxisSpacing')
                  ..withRequired(true)
                  ..withDefaultValue(0.0),
                Parameters.widthParameter()
                  ..withNamedParamInfoAndSameDisplayName('childAspectRatio')
                  ..withRequired(true)
                  ..withDefaultValue(1.0),
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
              info: InnerObjectParameterInfo(innerObjectName: 'SliverGridDelegateWithFixedCrossAxisCount')),
        ],
        required: true,
        info: NamedParameterInfo('gridDelegate'),
      );

  static textInputActionParameter() => ChoiceValueParameter(
        name: 'textInputAction',
        required: false,
        info: NamedParameterInfo('textInputAction'),
        options: {
          'done': TextInputAction.done,
          'next': TextInputAction.next,
          'newline': TextInputAction.newline,
          'send': TextInputAction.send,
          'search': TextInputAction.search,
        },
        defaultValue: null,
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
            Parameters.googleFontTextStyleParameter
              ..withInnerNamedParamInfoAndDisplayName('labelStyle', 'GoogleFonts.getFont')
              ..withRequired(false),
            Parameters.googleFontTextStyleParameter
              ..withInnerNamedParamInfoAndDisplayName('helperStyle', 'GoogleFonts.getFont')
              ..withRequired(false),
            Parameters.googleFontTextStyleParameter
              ..withInnerNamedParamInfoAndDisplayName('hintStyle', 'GoogleFonts.getFont')
              ..withRequired(false),
            Parameters.textParameter()
              ..withDefaultValue(null)
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('errorText'),
            Parameters.googleFontTextStyleParameter
              ..withInnerNamedParamInfoAndDisplayName('errorStyle', 'GoogleFonts.getFont')
              ..withRequired(false),
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
            Parameters.colorParameter..withNamedParamInfoAndSameDisplayName('iconColor'),
            Parameters.textParameter()..withNamedParamInfoAndSameDisplayName('prefixText'),
            Parameters.googleFontTextStyleParameter
              ..withInnerNamedParamInfoAndDisplayName('prefixStyle', 'GoogleFonts.getFont'),
            Parameters.textParameter()..withNamedParamInfoAndSameDisplayName('suffixText'),
            Parameters.googleFontTextStyleParameter
              ..withInnerNamedParamInfoAndDisplayName('suffixStyle', 'GoogleFonts.getFont'),
            Parameters.inputBorderParameter()..withNamedParamInfoAndSameDisplayName('enabledBorder'),
            Parameters.colorParameter
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
          info: InnerObjectParameterInfo(innerObjectName: 'InputDecoration', namedIfHaveAny: 'decoration'));

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
          info: InnerObjectParameterInfo(innerObjectName: 'UnderlineInputBorder'),
          name: 'underline-border');

  static ComplexParameter outlineInputBorderParameter() => ComplexParameter(
          params: [
            Parameters.borderRadiusParameter()..withRequired(true),
            Parameters.borderSideParameter(),
            Parameters.widthParameter()
              ..withNamedParamInfoAndSameDisplayName('gapPadding')
              ..withDefaultValue(0.0)
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
            Parameters.borderSideParameter()..withInfo(NamedParameterInfo('side')),
          ],
          evaluate: (params) {
            return RoundedRectangleBorder(
              borderRadius: params[0].value,
              side: params[1].value,
            );
          },
          info: InnerObjectParameterInfo(innerObjectName: 'RoundedRectangleBorder'),
          name: 'rounded-rectangle-border');

  static ComplexParameter decorationParameter() => ComplexParameter(
        params: [
          colorParameter..withRequired(false),
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
        info: InnerObjectParameterInfo(innerObjectName: 'BoxDecoration', namedIfHaveAny: 'decoration'),
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
              colorParameter..withDefaultValue(const Color(0xffffffff)),
              widthParameter()
                ..withDisplayName('stroke-width')
                ..withDefaultValue(2.0)
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
            evaluate: (params) =>
                Border(left: params[0].value, top: params[1].value, right: params[2].value, bottom: params[3].value),
          ),
        ],
      );

  static ChoiceValueParameter alignmentParameter() => ChoiceValueParameter(
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
      required: true,
      info: NamedParameterInfo('alignment')..isOptional = true);

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

  static Parameter get autoValidateMode => ChoiceValueParameter(
      name: 'auto-validate-mode',
      options: {
        'disabled': AutovalidateMode.disabled,
        'onUserInteraction': AutovalidateMode.onUserInteraction,
        'always': AutovalidateMode.always,
      },
      required: false,
      defaultValue: null,
      info: NamedParameterInfo('autovalidateMode'));

  static ChoiceValueParameter get overflowParameter => ChoiceValueParameter(
      name: 'overflow',
      options: {
        'ellipsis': TextOverflow.ellipsis,
        'fade': TextOverflow.fade,
        'clip': TextOverflow.clip,
        'visible': TextOverflow.visible,
      },
      defaultValue: null,
      required: false,
      info: NamedParameterInfo('overflow'));

  static Parameter stackFitParameter() => ChoiceValueParameter(
      name: 'fit',
      options: {
        'expand': StackFit.expand,
        'loose': StackFit.loose,
        'passThrough': StackFit.passthrough,
      },
      defaultValue: 'loose',
      info: NamedParameterInfo('fit'));

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
        'add_reaction': Icons.add_reaction,
        'add_reaction_outlined': Icons.add_reaction_outlined,
        'add_to_photos': Icons.add_to_photos,
        'delete': Icons.delete,
        'delete_outline': Icons.delete_outline,
        'edit': Icons.edit,
        'search': Icons.search,
        'settings': Icons.settings,
        'settings_applications': Icons.settings_applications,
        'settings_backup_restore': Icons.settings_backup_restore,
        'settings_bluetooth': Icons.settings_bluetooth,
        'settings_brightness': Icons.settings_brightness,
        'settings_cell': Icons.settings_cell,
        'settings_ethernet': Icons.settings_ethernet,
        'settings_input_antenna': Icons.settings_input_antenna,
        'settings_input_component': Icons.settings_input_component,
        'settings_input_composite': Icons.settings_input_composite,
        'settings_input_hdmi': Icons.settings_input_hdmi,
        'settings_input_svideo': Icons.settings_input_svideo,
        'settings_overscan': Icons.settings_overscan,
        'settings_phone': Icons.settings_phone,
        'settings_power': Icons.settings_power,
        'settings_remote': Icons.settings_remote,
        'settings_voice': Icons.settings_voice,
        'settings_system_daydream': Icons.settings_system_daydream,
        'settings_display': Icons.settings_display,
        'update': Icons.update,
        'warning': Icons.warning,
        'warning_outlined': Icons.warning_outlined,
        'warning_rounded': Icons.warning_rounded,
        'warning_sharp': Icons.warning_sharp,
        'arrow_back': Icons.arrow_back,
        'arrow_back_ios': Icons.arrow_back_ios,
        'arrow_forward': Icons.arrow_forward,
        'arrow_forward_ios': Icons.arrow_forward_ios,
        'image': Icons.image,
        'remove': Icons.remove,
        'create': Icons.create,
        'cloud': Icons.cloud,
        'cloud_circle': Icons.cloud_circle,
        'cloud_done': Icons.cloud_done,
        'cloud_download': Icons.cloud_download,
        'cloud_off': Icons.cloud_off,
        'cloud_queue': Icons.cloud_queue,
        'cloud_upload': Icons.cloud_upload,
        'file_download': Icons.file_download,
        'file_upload': Icons.file_upload,
        'folder': Icons.folder,
        'folder_open': Icons.folder_open,
        'folder_shared': Icons.folder_shared,
        'create_new_folder': Icons.create_new_folder,
        'cast': Icons.cast,
        'cast_connected': Icons.cast_connected,
        'computer': Icons.computer,
        'desktop_mac': Icons.desktop_mac,
        'desktop_windows': Icons.desktop_windows,
        'developer_board': Icons.developer_board,
        'device_hub': Icons.device_hub,
        'devices_other': Icons.devices_other,
        'device_unknown': Icons.device_unknown,
        'refresh': Icons.refresh,
        'scanner': Icons.scanner,
        'smartphone': Icons.smartphone,
        'sim_card': Icons.sim_card,
        'shopping_cart': Icons.shopping_cart,
        'speaker': Icons.speaker,
        'speaker_group': Icons.speaker_group,
        'tablet': Icons.tablet,
        'tablet_android': Icons.tablet_android,
        'tablet_mac': Icons.tablet_mac,
        'tv': Icons.tv,
        'watch': Icons.watch,
        'add_circle_outline': Icons.add_circle_outline,
        'remove_circle': Icons.remove_circle,
        'remove_circle_outline': Icons.remove_circle_outline,
        'check_circle': Icons.check_circle,
        'check_circle_outline': Icons.check_circle_outline,
        'radio_button_unchecked': Icons.radio_button_unchecked,
        'radio_button_checked': Icons.radio_button_checked,
        'star_border': Icons.star_border,
        'star_half': Icons.star_half,
        'star': Icons.star,
        'star_outline': Icons.star_outline,
        'thumb_down': Icons.thumb_down,
        'thumb_up': Icons.thumb_up,
        'thumbs_up_down': Icons.thumbs_up_down,
        'thumb_up_outlined': Icons.thumb_up_outlined,
        'thumb_down_outlined': Icons.thumb_down_outlined,
        'event': Icons.event,
        'event_seat': Icons.event_seat,
        'event_seat_outlined': Icons.event_seat_outlined,
        'event_available': Icons.event_available,
        'event_busy': Icons.event_busy,
        'event_note': Icons.event_note,
        'code': Icons.code,
        'info': Icons.info,
        'info_outline': Icons.info_outline,
        'list': Icons.list,
        'list_alt': Icons.list_alt,
        'list_alt_outlined': Icons.list_alt_outlined,
        'list_outlined': Icons.list_outlined,
        'menu': Icons.menu,
        'menu_open': Icons.menu_open,
        'menu_open_outlined': Icons.menu_open_outlined,
        'menu_outlined': Icons.menu_outlined,
        'menu_book': Icons.menu_book,
        'menu_book_outlined': Icons.menu_book_outlined,
        'notifications': Icons.notifications,
        'notifications_active': Icons.notifications_active,
        'notifications_none': Icons.notifications_none,
        'notifications_off': Icons.notifications_off,
        'notifications_paused': Icons.notifications_paused,
        'error': Icons.error,
        'check': Icons.check,
        'indeterminate_check_box': Icons.indeterminate_check_box,
        'wifi': Icons.wifi,
        'wifi_lock': Icons.wifi_lock,
        'comment_rounded': Icons.comment_rounded,
        'comment_sharp': Icons.comment_sharp,
        'apps': Icons.apps,
        'apps_rounded': Icons.apps_rounded,
        'apps_sharp': Icons.apps_sharp,
        'arrow_back_rounded': Icons.arrow_back_rounded,
        'arrow_back_sharp': Icons.arrow_back_sharp,
        'arrow_forward_rounded': Icons.arrow_forward_rounded,
        'arrow_forward_sharp': Icons.arrow_forward_sharp,
        'arrow_downward_rounded': Icons.arrow_downward_rounded,
        'arrow_downward_sharp': Icons.arrow_downward_sharp,
        'arrow_upward_rounded': Icons.arrow_upward_rounded,
        'arrow_upward_sharp': Icons.arrow_upward_sharp,
        'cancel_rounded': Icons.cancel_rounded,
        'check_rounded': Icons.check_rounded,
        'arrow_drop_down_rounded': Icons.arrow_drop_down_rounded,
        'arrow_drop_down_sharp': Icons.arrow_drop_down_sharp,
        'arrow_drop_up_rounded': Icons.arrow_drop_up_rounded,
        'arrow_drop_up_sharp': Icons.arrow_drop_up_sharp,
        'visibility_rounded': Icons.visibility_rounded,
        'visibility_off_rounded': Icons.visibility_off_rounded,
        'visibility_off': Icons.visibility_off,
        'person': Icons.person,
        'person_rounded': Icons.person_rounded,
        'person_sharp': Icons.person_sharp,
        'person_add': Icons.person_add,
        'person_add_rounded': Icons.person_add_rounded,
        'person_add_sharp': Icons.person_add_sharp,
        'person_outline': Icons.person_outline,
        'done': Icons.done,
        'done_all': Icons.done_all,
        'done_all_rounded': Icons.done_all_rounded,
        'done_all_sharp': Icons.done_all_sharp,
        'done_rounded': Icons.done_rounded,
        'done_outline': Icons.done_outline,
        'close_rounded': Icons.close_rounded,
        'close_sharp': Icons.close_sharp,
        'lock': Icons.lock,
        'lock_rounded': Icons.lock_rounded,
        'lock_open': Icons.lock_open,
        'lock_open_rounded': Icons.lock_open_rounded,
        'mail': Icons.mail,
        'mail_rounded': Icons.mail_rounded,
        'mail_outline': Icons.mail_outline,
        'work': Icons.work,
        'work_rounded': Icons.work_rounded,
        'work_outline': Icons.work_outline,
        'home': Icons.home,
        'home_rounded': Icons.home_rounded,
        'home_filled': Icons.home_filled,
        'home_outlined': Icons.home_outlined,
        'lock_outline': Icons.lock_outline,
        'location_on_rounded': Icons.location_on_rounded,
        'location_on_sharp': Icons.location_on_sharp,
        'build': Icons.build,
        'build_rounded': Icons.build_rounded,
        'network_cell': Icons.network_cell,
        'network_wifi': Icons.network_wifi,
        'network_wifi_rounded': Icons.network_wifi_rounded,
        'calendar_month': Icons.calendar_month,
        'calendar_today': Icons.calendar_today,
        'calendar_view_day': Icons.calendar_view_day,
        'calendar_view_day_rounded': Icons.calendar_view_day_rounded,
        'access_time': Icons.access_time,
        'access_time_rounded': Icons.access_time_rounded,
        'access_time_sharp': Icons.access_time_sharp,
        'access_alarm': Icons.access_alarm,
        'access_alarm_rounded': Icons.access_alarm_rounded,
        'account_balance': Icons.account_balance,
        'account_balance_rounded': Icons.account_balance_rounded,
        'account_balance_wallet': Icons.account_balance_wallet,
        'account_balance_wallet_rounded': Icons.account_balance_wallet_rounded,
        'account_box': Icons.account_box,
        'account_box_rounded': Icons.account_box_rounded,
        'account_box_sharp': Icons.account_box_sharp,
        'account_circle': Icons.account_circle,
        'account_circle_rounded': Icons.account_circle_rounded,
        'account_circle_sharp': Icons.account_circle_sharp,
        'add_box': Icons.add_box,
        'add_box_rounded': Icons.add_box_rounded,
        'add_box_sharp': Icons.add_box_sharp,
        'add_circle': Icons.add_circle,
        'add_circle_rounded': Icons.add_circle_rounded,
        'add_circle_sharp': Icons.add_circle_sharp,
        'add_rounded': Icons.add_rounded,
        'add_sharp': Icons.add_sharp,
        'add_shopping_cart': Icons.add_shopping_cart,
        'add_shopping_cart_rounded': Icons.add_shopping_cart_rounded,
        'add_shopping_cart_sharp': Icons.add_shopping_cart_sharp,
        'alarm_add': Icons.alarm_add,
        'alarm_add_rounded': Icons.alarm_add_rounded,
        'alarm_add_sharp': Icons.alarm_add_sharp,
        'alarm_off': Icons.alarm_off,
        'alarm_off_rounded': Icons.alarm_off_rounded,
        'alarm_off_sharp': Icons.alarm_off_sharp,
        'alarm_on': Icons.alarm_on,
        'alarm_on_rounded': Icons.alarm_on_rounded,
        'alarm_on_sharp': Icons.alarm_on_sharp,
        'alarm_rounded': Icons.alarm_rounded,
        'alarm_sharp': Icons.alarm_sharp,
        'cabin': Icons.cabin,
        'cabin_rounded': Icons.cabin_rounded,
        'cabin_sharp': Icons.cabin_sharp,
        'call': Icons.call,
        'call_rounded': Icons.call_rounded,
        'call_sharp': Icons.call_sharp,
        'call_end': Icons.call_end,
        'call_end_rounded': Icons.call_end_rounded,
        'call_end_sharp': Icons.call_end_sharp,
        'call_made': Icons.call_made,
        'call_made_rounded': Icons.call_made_rounded,
        'call_made_sharp': Icons.call_made_sharp,
        'call_merge': Icons.call_merge,
        'call_merge_rounded': Icons.call_merge_rounded,
        'call_merge_sharp': Icons.call_merge_sharp,
        'call_missed': Icons.call_missed,
        'call_missed_rounded': Icons.call_missed_rounded,
        'call_missed_sharp': Icons.call_missed_sharp,
        'call_missed_outgoing': Icons.call_missed_outgoing,
        'call_missed_outgoing_rounded': Icons.call_missed_outgoing_rounded,
        'call_missed_outgoing_sharp': Icons.call_missed_outgoing_sharp,
        'call_received': Icons.call_received,
        'call_received_rounded': Icons.call_received_rounded,
        'call_received_sharp': Icons.call_received_sharp,
        'call_split': Icons.call_split,
        'call_split_rounded': Icons.call_split_rounded,
        'call_split_sharp': Icons.call_split_sharp,
        'call_to_action': Icons.call_to_action,
        'call_to_action_rounded': Icons.call_to_action_rounded,
        'call_to_action_sharp': Icons.call_to_action_sharp,
        'camera': Icons.camera,
        'camera_alt': Icons.camera_alt,
        'camera_alt_rounded': Icons.camera_alt_rounded,
        'camera_alt_sharp': Icons.camera_alt_sharp,
        'camera_front': Icons.camera_front,
        'camera_front_rounded': Icons.camera_front_rounded,
        'camera_front_sharp': Icons.camera_front_sharp,
        'camera_rear': Icons.camera_rear,
        'camera_rear_rounded': Icons.camera_rear_rounded,
        'camera_rear_sharp': Icons.camera_rear_sharp,
        'camera_roll': Icons.camera_roll,
        'camera_roll_rounded': Icons.camera_roll_rounded,
        'camera_roll_sharp': Icons.camera_roll_sharp,
        'camera_rounded': Icons.camera_rounded,
        'camera_sharp': Icons.camera_sharp,
      },
      defaultValue: 'close',
      required: true);

  static Parameter get textAlignParameter => ChoiceValueParameter(
      name: 'text-align',
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

  static SimpleParameter get colorParameter => SimpleParameter<Color>(
        name: 'color',
        defaultValue: AppColors.white,
        inputType: ParamInputType.color,
        info: NamedParameterInfo('color'),
      );

  static ComplexParameter themeDataParameter() => ComplexParameter(
          params: [
            Parameters.backgroundColorParameter(),
            Parameters.colorParameter
              ..withRequired(false)
              ..inputCalculateAs = ((color, forward) => (color as Color).withAlpha(255))
              ..withNamedParamInfoAndSameDisplayName('primaryColor'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('secondaryHeaderColor'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('primaryColorLight'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('primaryColorDark'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('cardColor'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('focusColor'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('hoverColor'),
            Parameters.colorParameter
              ..withRequired(false)
              ..withNamedParamInfoAndSameDisplayName('splashColor'),
            Parameters.colorParameter
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

  static SimpleParameter backgroundColorParameter() => colorParameter
    ..withDisplayName('background-color')
    ..withRequired(false)
    ..withInfo(NamedParameterInfo('backgroundColor'));

  static SimpleParameter foregroundColorParameter() => colorParameter
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
              info: InnerObjectParameterInfo(innerObjectName: 'BorderRadius.circular'),
              evaluate: (value) {
                return BorderRadius.circular(value);
              }),
          ComplexParameter(
            info: InnerObjectParameterInfo(innerObjectName: 'BorderRadius.only'),
            params: [
              SimpleParameter<double>(
                  name: 'topLeft',
                  info: InnerObjectParameterInfo(innerObjectName: 'Radius.circular', namedIfHaveAny: 'topLeft')),
              SimpleParameter<double>(
                  name: 'bottomLeft',
                  info: InnerObjectParameterInfo(innerObjectName: 'Radius.circular', namedIfHaveAny: 'bottomLeft')),
              SimpleParameter<double>(
                  name: 'topRight',
                  info: InnerObjectParameterInfo(innerObjectName: 'Radius.circular', namedIfHaveAny: 'topRight')),
              SimpleParameter<double>(
                  name: 'bottomRight',
                  info: InnerObjectParameterInfo(innerObjectName: 'Radius.circular', namedIfHaveAny: 'bottomRight')),
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

  static gradientParameter() => ChoiceParameter(options: [
        linearGradientParameter(),
        radialGradientParameter(),
      ], name: 'gradient', required: false, info: NamedParameterInfo('gradient'));

  static linearGradientParameter() => ComplexParameter(
          params: [
            colorListParameter(),
            alignmentParameter()..withNamedParamInfoAndSameDisplayName('begin'),
            alignmentParameter()..withNamedParamInfoAndSameDisplayName('end'),
            doubleListParameter()..withNamedParamInfoAndSameDisplayName('stops'),
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
            doubleListParameter()..withNamedParamInfoAndSameDisplayName('stops'),
            alignmentParameter()..withNamedParamInfoAndSameDisplayName('center'),
            tileModeParameter()
          ],
          name: 'radial gradient',
          info: InnerObjectParameterInfo(innerObjectName: 'RadialGradient'),
          evaluate: (params) {
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
            colorParameter,
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
          colorParameter
            ..withInfo(null)
            ..withDefaultValue(AppColors.black),
          colorParameter
            ..withInfo(null)
            ..withDefaultValue(AppColors.white)
        ],
        parameterGenerator: () => colorParameter..withInfo(null),
        info: NamedParameterInfo('colors'),
      );

  static Parameter doubleListParameter() => ListParameter<double>(
      parameterGenerator: () => widthParameter()
        ..withRequired(false)
        ..withInfo(null)
        ..withDisplayName('stop-point'),
      required: false);

  static SimpleParameter directionParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('direction'), name: 'direction', required: false, defaultValue: 0.0);

  static SimpleParameter widthParameter() =>
      SimpleParameter<double>(info: NamedParameterInfo('width'), name: 'width', required: false, defaultValue: 100.0);

  static ComplexParameter offsetParameter() => ComplexParameter(
          info: InnerObjectParameterInfo(namedIfHaveAny: 'offset', innerObjectName: 'Offset'),
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
          info: InnerObjectParameterInfo(namedIfHaveAny: 'preferredSize', innerObjectName: 'Size'),
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

  static SimpleParameter heightParameter() =>
      SimpleParameter<double>(info: NamedParameterInfo('height'), name: 'height', required: false, defaultValue: 100.0);

  static Parameter boxFitParameter() => ChoiceValueParameter(options: {
        'none': BoxFit.none,
        'fill': BoxFit.fill,
        'fitWidth': BoxFit.fitWidth,
        'fitHeight': BoxFit.fitHeight,
        'contain': BoxFit.contain,
        'scaleDown': BoxFit.scaleDown,
        'cover': BoxFit.cover,
      }, defaultValue: 'none', info: NamedParameterInfo('fit'), name: 'box-fit');

  static Parameter filterQualityParameter() => ChoiceValueParameter(options: {
        'none': FilterQuality.none,
        'low': FilterQuality.low,
        'medium': FilterQuality.medium,
        'high': FilterQuality.high,
      }, defaultValue: 'medium', info: NamedParameterInfo('filterQuality'), required: true, name: 'filter-quality');

  static SimpleParameter thicknessParameter() => SimpleParameter<double>(
      info: NamedParameterInfo('thickness'), name: 'thickness', required: false, defaultValue: 1.0);

  static SimpleParameter radiusParameter() =>
      SimpleParameter<double>(info: NamedParameterInfo('radius'), name: 'radius', required: false, defaultValue: 30.0);

  static SimpleParameter<int> flexParameter() =>
      SimpleParameter<int>(info: NamedParameterInfo('flex'), name: 'flex', required: true, defaultValue: 1);

  static SimpleParameter<int> indexParameter() =>
      SimpleParameter<int>(info: NamedParameterInfo('index'), name: 'index', required: true, defaultValue: 0);

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
                colorParameter,
                widthParameter()
                  ..withDisplayName('stroke-width')
                  ..withRequired(true)
                  ..withDefaultValue(2.0)
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
            return RoundedRectangleBorder(borderRadius: params[0].value, side: params[1].value);
          },
          info: InnerObjectParameterInfo(innerObjectName: 'RoundedRectangleBorder'),
        )
      ],
      name: 'Shape Border',
      info: NamedParameterInfo('shape'));

  static SimpleParameter angleParameter() => SimpleParameter<double>(
      defaultValue: 0.0,
      inputType: ParamInputType.simple,
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
      defaultValue: 1.0, required: false, info: NamedParameterInfo('elevation'), name: 'elevation');

  static SimpleParameter get intElevationParameter =>
      SimpleParameter<int>(defaultValue: 1, required: false, info: NamedParameterInfo('elevation'), name: 'elevation');
  static final toolbarHeight = heightParameter()
    ..withRequired(true)
    ..withDisplayName('toolbar-height')
    ..withInfo(NamedParameterInfo('toolbarHeight'))
    ..withDefaultValue(55.0);

  static Parameter textSpanParameter() => ChoiceParameter(options: [
        ComplexParameter(
            params: [
              textParameter()..withInfo(NamedParameterInfo('text')),
              googleFontTextStyleParameter,
            ],
            evaluate: (params) => TextSpan(
                text: params[0].value, style: params[1].value, recognizer: TapGestureRecognizer()..onTap = () {}),
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
              final List<InlineSpan> list = (params[0].value as List).map<InlineSpan>((e) => e as InlineSpan).toList();
              return TextSpan(children: list);
            },
            name: 'Add Multiple Text')
      ], info: InnerObjectParameterInfo(innerObjectName: 'TextSpan', namedIfHaveAny: 'children'));

  static SimpleParameter textParameter() =>
      SimpleParameter<String>(name: 'text', defaultValue: '', inputType: ParamInputType.simple, required: true);

  static CodeParameter<CustomPainter> painterParameter() =>
      CodeParameter<CustomPainter>('painter', NamedParameterInfo('painter'), true,
          actionCode: '''\n void paint(Canvas canvas,Size size){
  // TODO: implement your logic here
  
  }
  
  bool shouldRepaint(painter) => true;
  ''',
          functions: [],
          apiBindCallback: (String api, List<dynamic> args) {}, evaluate: (value) {
        return PainterWrapper(value);
      });

  static SimpleParameter dynamicValueParameter() =>
      SimpleParameter(name: 'value', defaultValue: 0, inputType: ParamInputType.simple, required: true);

  static Parameter imageParameter() => SimpleParameter<ImageData>(
      name: 'Choose image', required: true, defaultValue: ImageData(null, ''), inputType: ParamInputType.image);

  static Parameter googleFontTypeParameter() {
    return ChoiceValueListParameter<String>(
        options: GoogleFonts.asMap().keys.toList(),
        defaultValue: 1068,
        name: 'Font - Family',
        dynamicChild: (value) {
          return Text(
            value,
            style: GoogleFonts.getFont(
              value,
              textStyle: const TextStyle(color: Colors.black, fontSize: 16.0),
            ),
          );
        });
  }

  static BooleanParameter italicParameter() => BooleanParameter(
        displayName: 'italic',
        required: false,
        val: false,
        evaluate: (val) => val == true ? 'FontStyle.italic' : 'FontStyle.normal',
        info: NamedParameterInfo('fontStyle'),
      );

  static BooleanParameter enableParameter() => BooleanParameter(
        displayName: 'enable',
        required: true,
        val: true,
        info: NamedParameterInfo('enabled'),
      );

  static BooleanParameter enableFeedbackParameter() => BooleanParameter(
      displayName: 'enable-feedback', required: false, val: true, info: NamedParameterInfo('enableFeedback'));

  static Parameter get textStyleParameter => ComplexParameter(
        info: InnerObjectParameterInfo(innerObjectName: 'TextStyle', namedIfHaveAny: 'textStyle'),
        params: [
          SimpleParameter<double>(name: 'font-size', info: NamedParameterInfo('fontSize'), defaultValue: 14.0),
          Parameters.colorParameter..withDefaultValue(AppColors.black),
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
          italicParameter(),
          textDecorationParameter(),
          colorParameter
            ..withRequired(false)
            ..withDefaultValue(null)
            ..withNamedParamInfoAndSameDisplayName('decorationColor'),
          textDecorationStyleParameter(),
          heightParameter()..withRequired(false),
          heightParameter()
            ..withNamedParamInfoAndSameDisplayName('wordSpacing')
            ..withRequired(false)
        ],
        name: 'Style',
        evaluate: (params) {
          return TextStyle(
            fontSize: params[0].value,
            color: params[1].value,
            fontWeight: params[2].value,
            fontStyle: params[3].value == true ? FontStyle.italic : FontStyle.normal,
            decoration: params[4].value,
            decorationColor: params[5].value,
            decorationStyle: params[6].value,
            height: params[7].value,
            wordSpacing: params[8].value,
          );
        },
      );

  static Parameter textInputTypeParameter() => ChoiceValueParameter(
        options: {
          'text': TextInputType.text,
          'number': TextInputType.number,
          'emailAddress': TextInputType.emailAddress,
          'phone': TextInputType.phone,
          'multiline': TextInputType.multiline,
          'datetime': TextInputType.datetime,
        },
        getCode: (value) => 'TextInputType.$value',
        fromCodeToKey: (code) {
          return code.substring(code.indexOf('.') + 1);
        },
        defaultValue: 'text',
        name: 'input type',
        info: NamedParameterInfo('keyboardType'),
      );

  static Parameter get googleFontTextStyleParameter => ComplexParameter(
      name: 'TextStyle',
      info: InnerObjectParameterInfo(innerObjectName: 'GoogleFonts.getFont', namedIfHaveAny: 'style'),
      params: [googleFontTypeParameter(), textStyleParameter],
      evaluate: (params) {
        return GoogleFonts.getFont(params[0].value, textStyle: params[1].value);
      });

  static ComplexParameter materialStatePropertyParameter<T>(Parameter parameter, String named) => ComplexParameter(
        params: [parameter],
        evaluate: (params) {
          return MaterialStateProperty.all<T>(params[0].value);
        },
        info: InnerObjectParameterInfo(innerObjectName: 'MaterialStateProperty.all', namedIfHaveAny: named),
      );

  static buttonStyleParameter() => ComplexParameter(
      info: InnerObjectParameterInfo(namedIfHaveAny: 'style', innerObjectName: 'ButtonStyle'),
      params: [
        materialStatePropertyParameter<Color?>(backgroundColorParameter()..withChangeNamed(null), 'backgroundColor'),
        materialStatePropertyParameter<Color?>(foregroundColorParameter()..withChangeNamed(null), 'foregroundColor'),
        alignmentParameter(),
        materialStatePropertyParameter<TextStyle>(googleFontTextStyleParameter..withChangeNamed(null), 'textStyle'),
        materialStatePropertyParameter<EdgeInsets?>(paddingParameter()..withChangeNamed(null), 'padding'),
        materialStatePropertyParameter<BorderSide?>(borderSideParameter()..withChangeNamed(null), 'side'),
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
            return BottomNavigationBarItem(icon: (params[0] as ComponentParameter).build());
          },
          info: InnerObjectParameterInfo(innerObjectName: 'BottomNavigationBarItem'));

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
            return ImageFilter.blur(sigmaX: params[0].value, sigmaY: params[1].value);
          },
          info: InnerObjectParameterInfo(innerObjectName: 'ImageFilter.blur', namedIfHaveAny: 'filter'));

  static Parameter textDecorationParameter() => ChoiceValueParameter(
        name: 'text-decoration',
        options: {
          'lineThrough': TextDecoration.lineThrough,
          'underline': TextDecoration.underline,
          'overline': TextDecoration.overline,
          'none': TextDecoration.none,
        },
        required: false,
        defaultValue: 'none',
        info: NamedParameterInfo('decoration'),
      );

  static Parameter textDecorationStyleParameter() => ChoiceValueParameter(
        name: 'text-decoration-style',
        options: {
          'solid': TextDecorationStyle.solid,
          'dashed': TextDecorationStyle.dashed,
          'dotted': TextDecorationStyle.dotted,
          'wavy': TextDecorationStyle.wavy,
          'double': TextDecorationStyle.double,
        },
        required: false,
        defaultValue: null,
        info: NamedParameterInfo('decorationStyle', isOptional: true),
      );
}
