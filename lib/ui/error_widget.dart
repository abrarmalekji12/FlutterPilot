import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/error/error_bloc.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import 'action_code_editor.dart';

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget({Key? key}) : super(key: key);

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  late ErrorBloc _errorBloc;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _errorBloc = context.read<ErrorBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.lightGrey,
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Console',
                  style: AppFontStyle.roboto(14,
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                BlocBuilder<ErrorBloc, ErrorState>(
                  builder: (context, state) {
                    if (_errorBloc.consoleMessages.isNotEmpty) {
                      return InkWell(
                          onTap: () {
                            _errorBloc.add(ClearMessageEvent());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'clear',
                              style: AppFontStyle.roboto(12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500),
                            ),
                          ));
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: BlocBuilder<ErrorBloc, ErrorState>(builder: (_, state) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                _controller.jumpTo(0);
              });
              return ListView.separated(
                separatorBuilder: (_, __) => const Divider(
                  height: 4,
                ),
                shrinkWrap: true,
                controller: _controller,
                itemCount: _errorBloc.consoleMessages.length,
                itemBuilder: (_, index) {
                  return ConsoleMessageTile(
                      consoleMessage: _errorBloc.consoleMessages[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class ConsoleMessageTile extends StatelessWidget {
  final ConsoleMessage consoleMessage;
  const ConsoleMessageTile({Key? key, required this.consoleMessage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SelectableText(
            consoleMessage.message,
            style: AppFontStyle.roboto(
                consoleMessage.type == ConsoleMessageType.event ? 10 : 14,
                color: getConsoleMessageColor(consoleMessage.type),
                fontWeight: consoleMessage.type == ConsoleMessageType.event
                    ? FontWeight.w700
                    : FontWeight.w500),
          ),
        ),
        Text(consoleMessage.time,
            style: AppFontStyle.roboto(12,
                color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
