import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'binding_strip.dart';

/// The workshop card — §5.
///
/// `dirtyBlack` surface, 1.5 px steel frame, zero radius, hard 4/4 shadow,
/// optional left spine (bay number) or binder perforation.
///
/// Pressing does not fade the card: it physically drops 2 px into its
/// housing and the shadow shrinks to 2/2 over 90 ms (§4).
class WorkshopCard extends StatefulWidget {
  const WorkshopCard({
    super.key,
    required this.child,
    this.onTap,
    this.spineLabel,
    this.binding = false,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 12),
    this.margin = const EdgeInsets.only(bottom: AppGeo.cardGap),
    this.borderColor,
    this.borderWidth = 1.5,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Rotated mono number in the 24 px left spine, e.g. `Nº 01`.
  final String? spineLabel;

  /// Binder perforation instead of a spine — used by the service book.
  final bool binding;

  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? borderColor;
  final double borderWidth;

  @override
  State<WorkshopCard> createState() => _WorkshopCardState();
}

class _WorkshopCardState extends State<WorkshopCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final offset = interactive && _pressed ? 2.0 : 0.0;

    final card = AnimatedContainer(
      duration: AppGeo.pressDuration,
      transform: Matrix4.translationValues(offset, offset, 0),
      decoration: BoxDecoration(
        color: AppColors.dirtyBlack,
        border: Border.all(
          color: widget.borderColor ?? AppColors.steel,
          width: widget.borderWidth,
        ),
        boxShadow: _pressed ? AppGeo.shadowHardSm : AppGeo.shadowHard,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.binding)
              const BindingStrip()
            else if (widget.spineLabel != null)
              SpineStrip(text: widget.spineLabel!),
            Expanded(
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ],
        ),
      ),
    );

    if (!interactive) {
      return Padding(padding: widget.margin, child: card);
    }

    return Padding(
      padding: widget.margin,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: card,
      ),
    );
  }
}

/// Counter plaque from the vehicle overview — label over a big mono number.
class CounterTile extends StatelessWidget {
  const CounterTile({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;

  /// Oxide frame + lit number: used for the open-alerts counter.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 11),
      decoration: BoxDecoration(
        color: AppColors.dirtyBlack,
        border: Border.all(
          color: highlight ? AppColors.oxideOrange : AppColors.steel,
          width: 1.5,
        ),
        boxShadow: AppGeo.shadowHardSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            style: AppText.data(
              size: 25,
              weight: FontWeight.w600,
              color: highlight ? AppColors.oxideLit : AppColors.bone,
            ).copyWith(letterSpacing: 0, height: 1),
          ),
        ],
      ),
    );
  }
}

/// Registration chip — mono on a recessed grease plate (§6 row 2).
class PlateChip extends StatelessWidget {
  const PlateChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
      decoration: BoxDecoration(
        color: AppColors.grease,
        border: Border.all(color: AppColors.steel, width: 1.5),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.data(size: 12.5, weight: FontWeight.w600)
            .copyWith(letterSpacing: 12.5 * 0.1),
      ),
    );
  }
}
