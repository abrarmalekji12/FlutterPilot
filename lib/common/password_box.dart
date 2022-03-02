import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordBox extends StatefulWidget {
  final void Function(String) onChanged;
  final String text;
  final String? Function(String)? validator;
  final TextEditingController controller;

  const PasswordBox({Key? key,required this.onChanged, this.text='Password',required this.controller,this.validator}) : super(key: key);

  @override
  State<PasswordBox> createState() => _PasswordBoxState();
}

class _PasswordBoxState extends State<PasswordBox> {
  bool showPassword=true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: showPassword,
      validator: (value) {
        return value!.length < 5
            ? 'Invalid password'
            : (widget.validator?.call(value));
      },
      onChanged:widget.onChanged,
      style: GoogleFonts.getFont(
        'Roboto',
        textStyle: const TextStyle(
          fontSize: 19,
          color: Color(0xffababa9),
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      readOnly: false,
      decoration: InputDecoration(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 5,
        ),
        labelText: widget.text,
        labelStyle: GoogleFonts.getFont(
          'Roboto',
          textStyle: const TextStyle(
            fontSize: 19,
            color: Color(0xffababa9),
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
          ),
        ),
        helperStyle: GoogleFonts.getFont(
          'ABeeZee',
          textStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xff000000),
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
        hintStyle: GoogleFonts.getFont(
          'ABeeZee',
          textStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xff000000),
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
        errorStyle: GoogleFonts.getFont(
          'ABeeZee',
          textStyle: const TextStyle(
            fontSize: 13,
            color: Colors.red,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
        border: UnderlineInputBorder(
          borderRadius:
          BorderRadius.circular(0),
          borderSide: BorderSide.none,
        ),
        iconColor:
        const Color(0xffffffff),
        prefixText: '',
        prefixStyle: GoogleFonts.getFont(
          'ABeeZee',
          textStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xff000000),
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
        suffixText: '',
        suffixStyle: GoogleFonts.getFont(
          'ABeeZee',
          textStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xff000000),
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            onTap: () {
              showPassword=!showPassword;
              setState(() {

              });
            },
            child: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              size: 22,
              color: const Color(0XFFBDBCC2),
            ),
          ),
        ),
        enabledBorder:
        UnderlineInputBorder(
          borderRadius:
          BorderRadius.circular(0),
          borderSide: BorderSide.none,
        ),
        fillColor:
        const Color(0xfffdce84),
        enabled: true,
      ),
    );
  }
}
