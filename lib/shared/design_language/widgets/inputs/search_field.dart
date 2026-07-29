import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/inputs/text_field.dart';

/// A specialized search input widget with clear text buttons.
class SWSearchField extends StatefulWidget {
  /// Creates an [SWSearchField].
  const SWSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search lobby, players...',
    this.onChanged,
  });

  /// Input editing controller.
  final TextEditingController? controller;

  /// Placeholder hint text.
  final String hintText;

  /// Search query change handler callback.
  final ValueChanged<String>? onChanged;

  @override
  State<SWSearchField> createState() => _SWSearchFieldState();
}

class _SWSearchFieldState extends State<SWSearchField> {
  late final TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearState);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_updateClearState);
    }
    super.dispose();
  }

  void _updateClearState() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _showClear) {
      setState(() => _showClear = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;

    return SWTextField(
      controller: _controller,
      hintText: widget.hintText,
      prefixIcon: SWIcon(
        Icons.search_rounded,
        color: colors.textMuted,
        size: 20.r,
      ),
      suffixIcon: _showClear
          ? IconButton(
              icon: SWIcon(SWIcons.close, color: colors.textMuted, size: 18.r),
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
            )
          : null,
      onChanged: widget.onChanged,
    );
  }
}
