import 'package:flutter/material.dart';
import 'package:youtube_downloader/constant/constant.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({super.key, required this.text, required this.onTap});
  final String text;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
