import 'package:flutter/material.dart';

bool _isKeyboardOpen = false;
void _handleKeyboardVisibility() {
  final hasFocus = FocusManager.instance.primaryFocus != null;

  if (hasFocus != _isKeyboardOpen) {
    // setState(() {
    //   _isKeyboardOpen = hasFocus;
    // });

    if (_isKeyboardOpen) {
      print("Clavier OUVERT");
    } else {
      print("Clavier FERMÉ");
    }
  }
}