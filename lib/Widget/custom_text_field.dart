// custom_text_field.dart

import 'package:flutter/material.dart';
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.only(bottom: 5),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Inter',
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          labelStyle: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 0, 0, 0),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 0, 0, 0),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
      ),
    );
  }
}
