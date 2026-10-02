import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Stamp variants — §5 and §7.2 of the DIRTY GARAGE proposal.
enum StampVariant {
  /// 0–69% — olive outline.
  ok,

  /// 70–89% — dirty yellow outline.
  kontrola,

  /// 90–99% — oxide outline.
  termin,

  /// >= 100% — rust FILL with a bone face (4.71:1). Rust is never used as
  /// text on dark, so the overdue state always arrives as a filled stamp.
  zalegle,

  /// Service entry "done" mark on a dark card — bone face in a double rust
  /// frame. Rust never carries text on dark (2.61:1), so it is the frame.
  wykonano,

  /// The same mark on an aged-paper sheet — rust face, double rust frame.
  wykonanoPaper,

  /// Primary photo mark.
  glowne,

  /// Neutral / informational.
  neutral,
}

/// A flat, coded stamp: 2 px frame, rotated -2.5°, Barlow Condensed 800 with
/// heavy tracking (§5). The "worn print" asset version is a later upgrade;
/// this is the flat version the spec calls correct-but-sterile.
///
/// The stamp carries its own padding and is never hard-`Positioned`, so it
/// survives 200% text scaling (§12.5).
class StampBadge extends StatelessWidget {
  const StampBadge({
    super.key,
    required this.label,
    required this.variant,
    this.sublabel,
    this.rotationDegrees = -2.5,
  });

  final String label;
  final StampVariant variant;

  /// Optional mono second line (e.g. the completion date on a paper sheet).
  final String? sublabel;

  final double rotationDegrees;

  /// Maps an interval percentage to its stamp variant (§7.2).
  static StampVariant variantForPercent(double percent) {
    if (percent >= 1.0) return StampVariant.zalegle;
    if (percent >= 0.90) return StampVariant.termin;
    if (percent >= 0.70) return StampVariant.kontrola;
    return StampVariant.ok;
  }

  _StampSkin get _skin {
    switch (variant) {
      case StampVariant.ok:
        return const _StampSkin(
          face: AppColors.oliveLit,
          frame: AppColors.militaryOlive,
        );
      case StampVariant.kontrola:
        return const _StampSkin(
          face: AppColors.dirtyYellow,
          frame: Color(0xFF8E7328),
        );
      case StampVariant.termin:
        return const _StampSkin(
          face: AppColors.oxideLit,
          frame: AppColors.oxideOrange,
        );
      case StampVariant.zalegle:
        return const _StampSkin(
          face: AppColors.bone,
          frame: AppColors.bone,
          fill: AppColors.rustRed,
        );
      case StampVariant.wykonano:
        return const _StampSkin(
          face: AppColors.bone,
          frame: AppColors.rustRed,
          doubleFrame: true,
        );
      case StampVariant.wykonanoPaper:
        // Rust on aged paper is 4.07:1 — AA only at large-text size, so the
        // face is set at 18 px bold rather than the 10.5 px used by the
        // dark-background stamps. The HTML preview sets it at 14 px, which
        // would fail; the spec's own contrast table (§2.2) wins.
        return const _StampSkin(
          face: AppColors.rustRed,
          frame: AppColors.rustRed,
          doubleFrame: true,
          fontSize: 18,
        );
      case StampVariant.glowne:
        return const _StampSkin(face: AppColors.bone, frame: AppColors.bone);
      case StampVariant.neutral:
        return const _StampSkin(face: AppColors.fadedInk, frame: AppColors.steel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = _skin;

    Widget stamp = Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
      decoration: BoxDecoration(
        color: skin.fill,
        border: Border.all(color: skin.frame, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.stamp(size: skin.fontSize, color: skin.face),
          ),
          if (sublabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sublabel!.toUpperCase(),
                style: AppText.micro(size: 9, color: skin.face),
              ),
            ),
        ],
      ),
    );

    if (skin.doubleFrame) {
      stamp = Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(color: skin.frame, width: 1),
        ),
        child: stamp,
      );
    }

    return Transform.rotate(
      angle: rotationDegrees * math.pi / 180,
      child: stamp,
    );
  }
}

class _StampSkin {
  const _StampSkin({
    required this.face,
    required this.frame,
    this.fill,
    this.doubleFrame = false,
    this.fontSize = 10.5,
  });

  final Color face;
  final Color frame;
  final Color? fill;
  final bool doubleFrame;
  final double fontSize;
}
