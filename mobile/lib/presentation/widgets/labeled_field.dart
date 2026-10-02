import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Form field with the label ABOVE the box — no floating label, no Material
/// animation (§5, "pole formularza"). Mono uppercase caption, grease well,
/// 1.5 px steel frame, zero radius; focus paints a 2 px dirtyYellow ring
/// like a dashboard warning light (§4).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.topGap = 22,
  });

  final String label;
  final Widget child;

  /// Optional mono note on the right of the label row, e.g. `OPCJONALNE`.
  final String? hint;

  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label.toUpperCase(), style: AppText.label()),
              ),
              if (hint != null)
                Text(
                  hint!.toUpperCase(),
                  style: AppText.micro(size: 9, color: AppColors.steel),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Password reveal control — a mono word, not a Material eye icon.
class RevealToggle extends StatelessWidget {
  const RevealToggle({super.key, required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: 64,
        child: Text(
          obscured ? 'POKAŻ' : 'UKRYJ',
          style: AppText.micro(size: 9.5, color: AppColors.fadedInk),
        ),
      ),
    );
  }
}

/// Section rule used inside forms: `FORMULARZ 02-A` style heading with the
/// double rule under it.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    this.code,
    this.topGap = 26,
  });

  final String title;
  final String? code;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(title.toUpperCase(), style: AppText.h2())),
              if (code != null)
                Text(code!.toUpperCase(), style: AppText.micro()),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: 2, child: ColoredBox(color: AppColors.steel)),
              SizedBox(height: 3),
              SizedBox(height: 1, child: ColoredBox(color: AppColors.hairline)),
            ],
          ),
        ],
      ),
    );
  }
}
