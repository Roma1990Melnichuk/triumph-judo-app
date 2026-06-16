import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const AppBackButton({super.key, this.onPressed, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Image.asset(
        'assets/images/back_button.png',
        width: size,
        height: size,
      ),
      padding: EdgeInsets.zero,
    );
  }
}
