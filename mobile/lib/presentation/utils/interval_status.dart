import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../domain/entities/reminder.dart';
import '../widgets/stamp_badge.dart';

/// Interval state thresholds — §7.2.
enum IntervalState { ok, kontrola, termin, zalegle }

/// Derived view of a mileage reminder's interval (§7.1).
///
/// ```
/// used      = vehicle.mileage - lastDoneMileage
/// percent   = used / intervalKm            // may exceed 100%
/// remaining = dueMileage - vehicle.mileage // negative = overdue
/// ```
///
/// This is presentation-only maths over fields that already exist on
/// [Reminder]; nothing here touches the model or the API.
@immutable
class IntervalStatus {
  const IntervalStatus({
    required this.title,
    required this.used,
    required this.intervalKm,
    required this.percent,
    required this.remaining,
  });

  final String title;

  /// Kilometres burned out of the interval. Clamped at 0.
  final int used;

  /// Interval length in kilometres.
  final int intervalKm;

  /// `used / intervalKm`, may exceed 1.0.
  final double percent;

  /// Kilometres left; negative means overdue.
  final int remaining;

  /// Builds a status for a reminder, or null when the data is not there:
  /// needs a mileage reminder with an interval, a baseline and a vehicle
  /// odometer reading. Reminders created before `intervalKm` existed simply
  /// do not render an interval.
  static IntervalStatus? forReminder(Reminder reminder, int? vehicleMileage) {
    if (reminder.isCompleted) return null;
    if (reminder.type != ReminderType.mileage) return null;
    if (vehicleMileage == null) return null;

    final interval = reminder.intervalKm;
    if (interval == null || interval <= 0) return null;

    // Fall back to dueMileage - intervalKm when the reminder has never been
    // ticked off, so an interval set on creation still shows a bar.
    final baseline = reminder.lastDoneMileage ??
        (reminder.dueMileage != null ? reminder.dueMileage! - interval : null);
    if (baseline == null) return null;

    final used = (vehicleMileage - baseline).clamp(0, 1 << 30).toInt();
    return IntervalStatus(
      title: reminder.title,
      used: used,
      intervalKm: interval,
      percent: used / interval,
      remaining: baseline + interval - vehicleMileage,
    );
  }

  IntervalState get state {
    if (percent >= 1.0) return IntervalState.zalegle;
    if (percent >= 0.90) return IntervalState.termin;
    if (percent >= 0.70) return IntervalState.kontrola;
    return IntervalState.ok;
  }

  bool get isOverdue => state == IntervalState.zalegle;

  /// Kilometres past the due point; 0 when not overdue.
  int get overdueBy => remaining < 0 ? -remaining : 0;

  /// Percentage rounded for display, e.g. `112`.
  int get percentLabel => (percent * 100).round();

  /// Bar / arc FILL colour. Never used for text.
  Color get fillColor {
    switch (state) {
      case IntervalState.ok:
        return AppColors.militaryOlive;
      case IntervalState.kontrola:
        return AppColors.dirtyYellow;
      case IntervalState.termin:
        return AppColors.oxideOrange;
      case IntervalState.zalegle:
        return AppColors.rustRed;
    }
  }

  /// Text colour for the percentage. Always an AA-passing "lit" token.
  Color get textColor {
    switch (state) {
      case IntervalState.ok:
        return AppColors.oliveLit;
      case IntervalState.kontrola:
        return AppColors.dirtyYellow;
      case IntervalState.termin:
      case IntervalState.zalegle:
        return AppColors.oxideLit;
    }
  }

  StampVariant get stampVariant {
    switch (state) {
      case IntervalState.ok:
        return StampVariant.ok;
      case IntervalState.kontrola:
        return StampVariant.kontrola;
      case IntervalState.termin:
        return StampVariant.termin;
      case IntervalState.zalegle:
        return StampVariant.zalegle;
    }
  }

  String get stampLabel {
    switch (state) {
      case IntervalState.ok:
        return 'OK';
      case IntervalState.kontrola:
        return 'KONTROLA';
      case IntervalState.termin:
        return 'TERMIN';
      case IntervalState.zalegle:
        return 'ZALEGŁE';
    }
  }

  /// The worst interval of a set — the one the hero gauge shows (§7.3 B).
  static IntervalStatus? worst(Iterable<IntervalStatus> all) {
    IntervalStatus? worst;
    for (final s in all) {
      if (worst == null || s.percent > worst.percent) worst = s;
    }
    return worst;
  }
}
