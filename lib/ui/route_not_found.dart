import 'package:flutter/material.dart';

import '../constant/color_assets.dart';
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
              style: AppFontStyle.lato(20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            Text(
              'Please check the url and try again.',
              style: AppFontStyle.lato(15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(ColorAssets.theme),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Go back to login page',
                style: AppFontStyle.lato(15,
                    fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
