import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Industrial list row with a red left accent bar.
/// [primary] is the bold main text, [secondary] a grey sub-line,
/// [trailing] sits on the right (cost / time), [badge] is optional
/// (e.g. reminder status). [tertiary] is an optional third grey line.
class DataListTile extends StatelessWidget {
  const DataListTile({
    super.key,
    required this.primary,
    this.secondary,
    this.tertiary,
    this.trailing,
    this.badge,
    this.onTap,
  });

  final String primary;
  final String? secondary;
  final String? tertiary;
  final String? trailing;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: AppColors.darkPrimary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                primary,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkOnBackground,
                                ),
                              ),
                            ),
                            if (badge != null) badge!,
                            if (trailing != null)
                              Text(
                                trailing!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkOnSurface,
                                ),
                              ),
                          ],
                        ),
                        if (secondary != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            secondary!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkLabel,
                            ),
                          ),
                        ],
                        if (tertiary != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            tertiary!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkLabel,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.darkAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
