import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'binding_strip.dart';

/// The only place in the app where paper is the background (§8, §12.1).
///
/// Aged paper, dark ink (10.63:1), binder perforation on the left, its own
/// hard shadow and a margin on the dark canvas — it is a document sitting on
/// the screen, never a full-screen light field at night.
///
/// NOTE: the `paper-fiber` grain tile from §11 (P1 asset) does not exist yet,
/// so this renders as flat paper. The surface under the text is meant to be
/// clean anyway (§12.4); the grain belongs on the edges.
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(18, 16, 18, 0),
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final List<Widget> children;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: const BoxDecoration(
        color: AppColors.agedPaper,
        boxShadow: AppGeo.shadowPaper,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BindingStrip.paper(),
            Expanded(
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Double rule for the paper sheet — 2 px dark over a 1 px light hairline.
class PaperRule extends StatelessWidget {
  const PaperRule({super.key, this.margin = const EdgeInsets.fromLTRB(0, 12, 0, 2)});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: 2, child: ColoredBox(color: Color(0xFF45402F))),
          SizedBox(height: 2),
          SizedBox(height: 1, child: ColoredBox(color: Color(0xFF9C8F72))),
        ],
      ),
    );
  }
}

/// Signature line closing a paper document.
class PaperSignatureLine extends StatelessWidget {
  const PaperSignatureLine({super.key, required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF8E8064), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left.toUpperCase(),
            style: AppText.micro(color: AppColors.paperInkFaded),
          ),
          Text(
            right.toUpperCase(),
            style: AppText.micro(color: AppColors.paperInkFaded),
          ),
        ],
      ),
    );
  }
}
