import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../constant/string_constant.dart';

class SearchTextField extends StatefulWidget {
  final FocusNode focusNode;
  final String hint;
  final String text;
  final Color focusColor;

  const SearchTextField(
      {required this.onTextChange,
      required this.focusNode,
      required this.hint,
      required this.focusColor,
      this.text = '',Key? key}):super(key: key);

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState();

  final Function(String) onTextChange;
}

class _SearchTextFieldState extends State<SearchTextField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _searchController.text = widget.text;
  }

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        keyboardType: TextInputType.multiline,
        focusNode: widget.focusNode,
        //textInputAction: TextInputAction.newline,
        maxLines: 1,
        onChanged: widget.onTextChange,
        autofocus: false,
        style: AppFontStyle.roboto(15, color: Colors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
            focusColor: Colors.white,
            hoverColor: Colors.white,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(10.0),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.theme, width: 2),
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            //fillColor: readonly ? Colors.white : Colors.white,
            //errorStyle: TextStyle( color: Theme.of(context).backgroundColor, fontSize: 20),
            filled: true,
            hintText: widget.hint,
            hintStyle: AppFontStyle.roboto(
              15,
              color: const Color(0xffC4C4C4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.focusColor, width: 1.5),
              borderRadius: const BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.focusColor, width: 1.5),
              borderRadius: const BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            suffixIcon: Transform.scale(
              scale: 0.45,
              child: Image.asset(
                Strings.SEARCH_ICON,
                width: 15,
                height: 15,
                fit: BoxFit.fitWidth,
              ),
            )
            // suffixIcon: IconButton(
            //   icon: const Icon(
            //     Icons.clear_rounded,
            //     size: 20,
            //     color: Colors.black,
            //   ),
            //   onPressed: () {
            //     _searchController.clear();
            //     var currentFocus = FocusScope.of(context);
            //     if (currentFocus.canRequestFocus) {
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     }
            //   },
            // ),
            ),
      ),
    );
  }
}
