import 'dart:html' as html;
import 'dart:math';
import 'package:flutter/material.dart';

class CustomDropdownButton<T> extends StatefulWidget {
  final TextStyle style;
  final Icon? icon;
  final T? value;
  final Widget? hint;
  final bool enable;
  final Widget Function(BuildContext, T) selectedItemBuilder;
  final List<CustomDropdownMenuItem<T>> items;
  final void Function(T) onChanged;

  const CustomDropdownButton({
    required this.style,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.selectedItemBuilder,
    this.icon,
    Key? key,
    this.enable = true,
  }) : super(key: key);

  @override
  _CustomDropdownButtonState<T> createState() => _CustomDropdownButtonState();
}

class _CustomDropdownButtonState<T> extends State<CustomDropdownButton<T>> {
  // T? selected;
  GlobalKey globalKey = GlobalKey();
  OverlayEntry? overlayEntry;
  int state = 0;

  @override
  void initState() {
    super.initState();
    // selected = widget.value;
    overlayEntry = OverlayEntry(builder: (context) {

      return GestureDetector(
        onTap: () {
          overlayEntry?.remove();
          setState(() {
            state = 2;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: getLeftPosition(),
                top: getTopPosition(),
                child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1),
                    curve: Curves.bounceOut,
                    duration: const Duration(milliseconds: 100),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Transform.translate(
                          offset: Offset(0, -100 * (1 - value)),
                          child: SizedBox(
                            width: getWidth(),
                            height: getCalculatedHeight(),
                            child: Card(
                              elevation: 5,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.builder(
                                itemCount: widget.items.length,
                               itemBuilder: (context,i){
                                return InkWell(
                                   child: Padding(
                                     padding: const EdgeInsets.all(8.0),
                                     child: widget.items[i].child,
                                   ),
                                   onTap: () {
                                     widget.onChanged(widget.items[i].value);
                                     overlayEntry?.remove();
                                     setState(() {
                                       state = 2;
                                     });
                                   },
                                   borderRadius: BorderRadius.circular(10),
                                   splashColor: Colors.grey,
                                 );
                               },
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
      );
    });
    html.window.onResize.listen((event) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        overlayEntry?.markNeedsBuild();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        key: globalKey,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.grey,
        onTap: widget.enable
            ? () {
          if (!(overlayEntry?.mounted ?? false)) {
            Overlay.of(context)?.insert(overlayEntry!);
            setState(() {
              state = 1;
            });
          }
        }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: widget.value != null
                    ? widget.selectedItemBuilder(context, widget.value!)
                    : widget.hint ?? Container(),
              ),
              const SizedBox(
                width: 5,
              ),
              TweenAnimationBuilder(
                key: ValueKey(state),
                curve: Curves.bounceInOut,
                builder: (context, double value, child) {
                  return Transform.rotate(
                    angle: ((state == 1) ? pi * value : pi * (value - 1)),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xffb3b3b3),
                      size: 30,
                    ),
                  );
                },
                tween: Tween<double>(begin: 0, end: 1),
                duration: state == 0
                    ? const Duration(milliseconds: 0)
                    : const Duration(milliseconds: 150),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double getLeftPosition() {
    final RenderBox renderBox =
    globalKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final size=MediaQuery.of(context).size;
    if(position.dx+200>size.width) {
      return size.width-230;
    }
    return position.dx;
  }

  double getWidth() {
    final RenderBox renderBox =
    globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    return renderBox.size.width;
  }

  double getCalculatedHeight() {
    final size=MediaQuery.of(context).size;
    final itemsHeight=widget.items.length*30.0;
    final topPosition=getTopPosition();
    if(topPosition+itemsHeight>size.height){
      return size.height-(topPosition);
    }
    // buttonSize = renderBox.size;
    return itemsHeight;
  }
  double getTopPosition() {
    final RenderBox renderBox =
    globalKey.currentContext!.findRenderObject()! as RenderBox;
    // buttonSize = renderBox.size;
    final size=MediaQuery.of(context).size;

    final Offset position = renderBox.localToGlobal(Offset.zero);

    if(position.dy+renderBox.size.height+(50*widget.items.length)>size.height) {
      return size.height-(50*widget.items.length)>0?size.height-(50*widget.items.length):position.dy;
    }
    return position.dy + renderBox.size.height;
  }
}

class CustomDropdownMenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;

  const CustomDropdownMenuItem({
    required this.value,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      child: child,
    );
  }
}
