import 'package:flutter/material.dart';

enum AppButtonStyle { primary, outline, ghost, destructive }

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final AppButtonStyle style;
  final bool isFullWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = AppButtonStyle.primary,
    this.isFullWidth = false,
    this.height,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    ButtonStyle? buttonStyle;
    
    switch (style) {
      case AppButtonStyle.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.blue[600],
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        );
        break;
      case AppButtonStyle.outline:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? Colors.blue[600],
          side: BorderSide(color: backgroundColor ?? Colors.blue[600]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
        break;
      case AppButtonStyle.ghost:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: foregroundColor ?? Colors.blue[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
        break;
      case AppButtonStyle.destructive:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.red[600],
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        );
        break;
    }

    Widget button;
    if (style == AppButtonStyle.outline) {
      button = OutlinedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    } else if (style == AppButtonStyle.ghost) {
      button = TextButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    } else {
      button = ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height ?? 48,
        child: button,
      );
    }

    if (height != null) {
      return SizedBox(
        height: height,
        child: button,
      );
    }

    return button;
  }
}
