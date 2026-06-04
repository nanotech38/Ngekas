import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ngekas/const/app_theme_const.dart';

enum FieldType { text, password, currency, number, email, multiline }

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FieldType type;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool isRequired;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.type = FieldType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.maxLines,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  TextInputType get _keyboardType {
    switch (widget.type) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.currency:
      case FieldType.number:
        return const TextInputType.numberWithOptions(decimal: false);
      case FieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> get _inputFormatters {
    if (widget.type == FieldType.currency) {
      return [
        FilteringTextInputFormatter.digitsOnly,
        _CurrencyInputFormatter(),
      ];
    }
    if (widget.type == FieldType.number) {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppTextStyle.labelLg.copyWith(
                color: _isFocused ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: widget.type == FieldType.password ? _obscureText : false,
          keyboardType: _keyboardType,
          inputFormatters: _inputFormatters,
          maxLines: widget.type == FieldType.password
              ? 1
              : (widget.maxLines ??
                    (widget.type == FieldType.multiline ? 4 : 1)),
          textInputAction:
              widget.textInputAction ??
              (widget.type == FieldType.multiline
                  ? TextInputAction.newline
                  : TextInputAction.next),
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: AppTextStyle.bodyLg.copyWith(
            color: AppColors.textPrimary,
            fontWeight: AppFontWeight.medium,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontWeight: AppFontWeight.regular,
              fontSize: AppFontSize.md,
            ),
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.background,
            prefixIcon: _buildPrefixIcon(colorScheme),
            suffixIcon: _buildSuffixIcon(colorScheme),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _buildBorder(AppColors.border),
            enabledBorder: _buildBorder(AppColors.border),
            focusedBorder: _buildBorder(AppColors.primary, width: 2),
            errorBorder: _buildBorder(AppColors.error),
            focusedErrorBorder: _buildBorder(AppColors.error, width: 2),
            disabledBorder: _buildBorder(AppColors.surfaceVariant),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: AppFontSize.sm,
              fontWeight: AppFontWeight.medium,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildPrefixIcon(ColorScheme colorScheme) {
    if (widget.type == FieldType.currency) {
      return Container(
        constraints: const BoxConstraints(minWidth: 48),
        alignment: Alignment.center,
        child: Text(
          'Rp',
          style: TextStyle(
            color: _isFocused ? AppColors.primary : AppColors.textMuted,
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.base,
          ),
        ),
      );
    }

    IconData? icon = widget.prefixIcon;
    if (icon == null) {
      switch (widget.type) {
        case FieldType.email:
          icon = Icons.email_outlined;
          break;
        case FieldType.password:
          icon = Icons.lock_outline;
          break;
        case FieldType.number:
          icon = Icons.tag_rounded;
          break;
        default:
          return null;
      }
    }

    return Icon(
      icon,
      color: _isFocused ? AppColors.primary : AppColors.textDisabled,
      size: 20,
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    if (widget.type == FieldType.password) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _isFocused ? AppColors.primary : AppColors.textDisabled,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffixWidget;
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digits = newValue.text.replaceAll('.', '');
    final formatted = _format(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }
}
