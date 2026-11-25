import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/typography/app_text_styles.dart';

/// Professional reusable phone number input field with country code picker
/// and clean error display matching the Figma design system.
class CommonPhoneField extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String countryCode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCountryCodeTap;
  final bool enabled;

  const CommonPhoneField({
    super.key,
    this.label,
    this.controller,
    this.validator,
    this.countryCode = '+91',
    this.hintText = 'e.g. 98764 52598',
    this.onChanged,
    this.onCountryCodeTap,
    this.enabled = true,
  });

  @override
  State<CommonPhoneField> createState() => _CommonPhoneFieldState();
}

class _CommonPhoneFieldState extends State<CommonPhoneField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator != null
          ? (_) => widget.validator!(widget.controller?.text)
          : null,
      builder: (FormFieldState<String> fieldState) {
        final hasError = fieldState.hasError;

        Color borderColor;
        double borderWidth = 1.0;
        if (hasError) {
          borderColor = AppColors.error;
          borderWidth = 1.2;
        } else if (_isFocused) {
          borderColor = AppColors.borderFocused;
          borderWidth = 1.2;
        } else {
          borderColor = AppColors.border;
          borderWidth = 1.0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            Container(
              height: 56.0,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.white
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Row(
                children: [
                  // Country Code Section
                  InkWell(
                    onTap: widget.enabled ? widget.onCountryCodeTap : null,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.countryCode,
                            style: AppTextStyles.input.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 15.0,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 20.0,
                            color: Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    width: 1.0,
                    height: 28.0,
                    color: hasError
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),

                  // Phone Number Input
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        fieldState.didChange(value);
                        widget.onChanged?.call(value);
                      },
                      style: AppTextStyles.input.copyWith(
                        fontSize: 15.0,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.hint.copyWith(
                          fontSize: 14.0,
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6.0),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  fieldState.errorText ?? '',
                  style: AppTextStyles.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
