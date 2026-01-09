import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';


class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = outlined ? Colors.white : AppColors.text; // black button like ref
    final fg = outlined ? AppColors.text : Colors.white;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: outlined ? const BorderSide(color: AppColors.stroke) : BorderSide.none,
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

