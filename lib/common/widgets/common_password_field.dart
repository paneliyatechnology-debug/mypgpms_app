import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/dimensions/app_dimensions.dart';
import 'common_text_field.dart';

/// Reusable password text field with eye toggle.
class CommonPasswordField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;

  const CommonPasswordField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
  });

  @override
  State<CommonPasswordField> createState() => _CommonPasswordFieldState();
}

class _CommonPasswordFieldState extends State<CommonPasswordField> {
  bool _obscureText = true;

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonTextField(
      label: widget.label,
      hintText: widget.hintText,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textMuted,
          size: AppDimensions.iconS,
        ),
        onPressed: _toggleObscure,
      ),
    );
  }
}

