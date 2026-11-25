import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/typography/app_text_styles.dart';

/// Reusable clean numeric keypad matching the Figma design.
class CommonKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;

  const CommonKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.keypadBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3'], ['', 'ABC', 'DEF']),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
          const SizedBox(height: 8),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits, List<String> letters) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _KeypadButton(
              digit: digits[index],
              subtitle: letters[index],
              onTap: () => onDigitPressed(digits[index]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        const Expanded(
          child: SizedBox.shrink(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _KeypadButton(
              digit: '0',
              subtitle: '',
              onTap: () => onDigitPressed('0'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _KeypadButton(
              isBackspace: true,
              onTap: onBackspacePressed,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? digit;
  final String? subtitle;
  final bool isBackspace;
  final VoidCallback onTap;

  const _KeypadButton({
    this.digit,
    this.subtitle,
    this.isBackspace = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.keypadKey,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          height: 48.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.keypadBorder, width: 0.8),
          ),
          child: Center(
            child: isBackspace
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: AppColors.textPrimary,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        digit ?? '',
                        style: AppTextStyles.keypadDigit.copyWith(
                          fontSize: 20,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: AppTextStyles.keypadLetters.copyWith(
                            fontSize: 8.5,
                            height: 1.0,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

