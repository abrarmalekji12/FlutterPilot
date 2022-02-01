import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constant/font_style.dart';

class CodeViewerWidget extends StatelessWidget {
  final String code;

  const CodeViewerWidget({Key? key, required this.code}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 600,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SelectableText(
                    code,
                    style: AppFontStyle.roboto(15,
                        color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                    },
                    child: const Icon(
                      Icons.copy,
                      color: Color(0xff494949),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
