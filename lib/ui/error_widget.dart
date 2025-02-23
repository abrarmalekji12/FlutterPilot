import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/error/error_bloc.dart';
import '../constant/font_style.dart';
import '../injector.dart';
import '../runtime_provider.dart';
import 'fvb_code_editor.dart';

class ConsoleWidget extends StatefulWidget {
  final RuntimeMode mode;

  const ConsoleWidget({Key? key, required this.mode}) : super(key: key);

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class ConsoleFilter {
  bool event = true;
  bool error = true;
  bool verbose = true;
}

final ConsoleFilter _filter = ConsoleFilter();

class _ConsoleWidgetState extends State<ConsoleWidget> {
  late EventLogBloc _errorBloc;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _errorBloc = context.read<EventLogBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(6),
          color: theme.background1,
          border: Border.all(
            color: Colors.grey.shade400,
            width: 0.3,
          )),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Console',
                  style: AppFontStyle.lato(16,
                      color: theme.text1Color, fontWeight: FontWeight.bold),
                ),
                BlocBuilder<EventLogBloc, ErrorState>(
                  builder: (context, state) {
                    if (_errorBloc.consoleMessages.isNotEmpty) {
                      return InkWell(
                        onTap: () {
                          _errorBloc.add(ClearMessageEvent(widget.mode));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          child: const Icon(Icons.clear_all),
                        ),
                      );
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
          Wrap(
            children: [
              FilterTile(
                  value: _filter.verbose,
                  onChange: (value) {
                    setState(() {
                      _filter.verbose = value;
                    });
                  },
                  title: 'Verbose'),
              const SizedBox(
                width: 8,
              ),
              FilterTile(
                  value: _filter.error,
                  onChange: (value) {
                    setState(() {
                      _filter.error = value;
                    });
                  },
                  title: 'Error'),
              const SizedBox(
                width: 8,
              ),
              FilterTile(
                  value: _filter.event,
                  onChange: (value) {
                    setState(() {
                      _filter.event = value;
                    });
                  },
                  title: 'Event'),
            ],
          ),
          const Divider(
            thickness: 0.5,
            height: 16,
          ),
          Expanded(
            child: SelectionArea(
              child: BlocBuilder<EventLogBloc, ErrorState>(builder: (_, state) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  _controller.jumpTo(_controller.position.maxScrollExtent);
                });
                final list = _errorBloc.consoleMessages[widget.mode]
                        ?.where((element) =>
                            (element.type == ConsoleMessageType.event &&
                                _filter.event) ||
                            (element.type == ConsoleMessageType.error &&
                                _filter.error) ||
                            (element.type == ConsoleMessageType.info &&
                                _filter.verbose))
                        .toList(growable: false) ??
                    [];
                return Align(
                  alignment: Alignment.topCenter,
                  child: ListView.separated(
                    separatorBuilder: (_, __) => Divider(
                      height: 4,
                      color: theme.line,
                      thickness: 0.4,
                    ),
                    shrinkWrap: true,
                    controller: _controller,
                    itemCount: list.length,
                    itemBuilder: (_, index) {
                      return ConsoleMessageTile(consoleMessage: list[index]);
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChange;
  final String title;

  const FilterTile(
      {Key? key,
      required this.value,
      required this.onChange,
      required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (value) {
            if (value != null) {
              onChange.call(value);
            }
          },
          visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          title,
          style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
        )
      ],
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
          child: Text(
            consoleMessage.message,
            style: AppFontStyle.lato(13,
                color: getConsoleMessageColor(consoleMessage.type),
                fontWeight: consoleMessage.type == ConsoleMessageType.event
                    ? FontWeight.w700
                    : FontWeight.w500),
          ),
        ),
        Text(consoleMessage.time,
            style: AppFontStyle.lato(12,
                color: theme.line, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
