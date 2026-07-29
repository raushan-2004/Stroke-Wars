import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';

/// A premium styled game text field supporting consistent validation state.
class SWTextField extends StatelessWidget {
  /// Creates an [SWTextField].
  const SWTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  /// Editing controller.
  final TextEditingController? controller;

  /// Input placeholder text.
  final String? hintText;

  /// Optional prefix icon widget.
  final Widget? prefixIcon;

  /// Optional suffix icon widget.
  final Widget? suffixIcon;

  /// Toggles text masking (obscuring).
  final bool obscureText;

  /// Virtual keyboard input configuration.
  final TextInputType? keyboardType;

  /// Input change handler.
  final ValueChanged<String>? onChanged;

  /// Field validator callback.
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: typography.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: typography.body.copyWith(color: colors.textMuted),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: SWRadius.l,
          borderSide: BorderSide(
            color: colors.border,
            width: SWTokens.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SWRadius.l,
          borderSide: BorderSide(
            color: colors.border,
            width: SWTokens.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SWRadius.l,
          borderSide: BorderSide(
            color: colors.borderActive,
            width: SWTokens.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SWRadius.l,
          borderSide: BorderSide(
            color: colors.danger,
            width: SWTokens.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SWRadius.l,
          borderSide: BorderSide(
            color: colors.danger,
            width: SWTokens.borderMedium,
          ),
        ),
      ),
    );
  }
}
