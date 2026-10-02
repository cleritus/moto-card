import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum GarageButtonVariant {
  /// Oxide fill, 2 px bone frame, grease label, hard 4/4 shadow (§5).
  primary,

  /// No fill, 1.5 px steel frame, paper label, `→` instead of an icon (§5).
  ghost,

  /// Ghost geometry, oxide-lit label — destructive actions. Rust is never
  /// used as text on dark (§2.2), so "delete" is lit oxide, not red.
  danger,
}

/// Primary / secondary button with the physical press state from §4: the
/// button drops 2 px into its housing and the shadow shrinks to 2/2 over
/// 90 ms, instead of fading to 80% opacity.
class GarageButton extends StatefulWidget {
  const GarageButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GarageButtonVariant.primary,
    this.isLoading = false,
    this.trailingArrow = false,
    this.expand = true,
  });

  const GarageButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingArrow = false,
    this.expand = true,
  }) : variant = GarageButtonVariant.ghost;

  const GarageButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingArrow = false,
    this.expand = true,
  }) : variant = GarageButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final GarageButtonVariant variant;
  final bool isLoading;

  /// Appends ` →` — the secondary button's "icon".
  final bool trailingArrow;

  final bool expand;

  @override
  State<GarageButton> createState() => _GarageButtonState();
}

class _GarageButtonState extends State<GarageButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final primary = widget.variant == GarageButtonVariant.primary;

    final Color face;
    final Color fill;
    final BoxBorder border;
    switch (widget.variant) {
      case GarageButtonVariant.primary:
        face = enabled ? AppColors.grease : AppColors.fadedInk;
        fill = enabled ? AppColors.oxideOrange : AppColors.hairline;
        border = Border.all(
          color: enabled ? AppColors.bone : AppColors.steel,
          width: 2,
        );
      case GarageButtonVariant.ghost:
        face = enabled ? AppColors.agedPaper : AppColors.steel;
        fill = Colors.transparent;
        border = Border.all(color: AppColors.steel, width: 1.5);
      case GarageButtonVariant.danger:
        face = enabled ? AppColors.oxideLit : AppColors.steel;
        fill = Colors.transparent;
        border = Border.all(color: AppColors.steel, width: 1.5);
    }

    final offset = _pressed && enabled ? 2.0 : 0.0;
    final text = widget.trailingArrow ? '${widget.label}  →' : widget.label;

    final child = widget.isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: face),
          )
        : Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppText.button(size: primary ? 16 : 14.5, color: face),
          );

    final button = AnimatedContainer(
      duration: AppGeo.pressDuration,
      transform: Matrix4.translationValues(offset, offset, 0),
      height: primary ? 52 : 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fill,
        border: border,
        boxShadow: primary && enabled
            ? (_pressed ? AppGeo.shadowHardSm : AppGeo.shadowHard)
            : null,
      ),
      child: child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? widget.onPressed : null,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

/// Compact oxide button used in screen headers (`+ DO GARAŻU`).
class SmallButton extends StatelessWidget {
  const SmallButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.oxideOrange,
          border: Border.all(color: AppColors.bone, width: 1.5),
          boxShadow: AppGeo.shadowHardSm,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppText.button(size: 13.5, color: AppColors.grease),
        ),
      ),
    );
  }
}

/// Square 54×54 action block that sits where a FAB would — oxide fill, bone
/// frame, hard shadow, `+` in condensed. No floating pill, no radius.
class GarageFab extends StatelessWidget {
  const GarageFab({super.key, required this.onPressed, this.glyph = '+'});

  final VoidCallback onPressed;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.oxideOrange,
          border: Border.all(color: AppColors.bone, width: 2),
          boxShadow: AppGeo.shadowHard,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            glyph,
            style: AppText.button(size: 30, color: AppColors.grease)
                .copyWith(letterSpacing: 0, height: 1),
          ),
        ),
      ),
    );
  }
}

/// Text action for app bars — no Material icon, just a condensed label.
class BarAction extends StatelessWidget {
  const BarAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label.toUpperCase(),
          style: AppText.button(
            size: 13.5,
            color: danger ? AppColors.oxideLit : AppColors.agedPaper,
          ),
        ),
      ),
    );
  }
}
