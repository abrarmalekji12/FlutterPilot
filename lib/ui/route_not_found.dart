import 'package:flutter/material.dart';

import '../constant/app_colors.dart';
import '../constant/font_style.dart';

class RouteNotFound extends StatelessWidget {
  const RouteNotFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Route not found',
              style: AppFontStyle.roboto(16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Text(
              'Please check the url and try again.',
              style: AppFontStyle.roboto(15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(AppColors.theme),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '');
              },

              child: Text(
                'Go back to main page',
                style: AppFontStyle.roboto(15, fontWeight: FontWeight.w500,color: Colors.white),
              ),

            ),
          ],
        ),
      ),
    );
  }
}
