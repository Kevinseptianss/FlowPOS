import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool obscureText;

  @override
  void initState() {
    super.initState();
    obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: obscureText,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
        filled: true,
        fillColor: AppPallete.background,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() {
                  obscureText = !obscureText;
                }),
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: AppPallete.primary,
                ),
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter ${widget.label}';
        }

        if (widget.isPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }

        if (widget.validator != null) {
          return widget.validator!(value);
        }

        return null;
      },
    );
  }
}
