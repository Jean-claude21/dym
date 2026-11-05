import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';

/// Délais de préparation proposés (minutes ; la base accepte 5 à 240).
const storePrepChoices = [15, 30, 45, 60];

/// Nom du jour (1 = lundi).
String weekdayName(DymLocalizations l10n, int weekday) => switch (weekday) {
  1 => l10n.weekday1,
  2 => l10n.weekday2,
  3 => l10n.weekday3,
  4 => l10n.weekday4,
  5 => l10n.weekday5,
  6 => l10n.weekday6,
  _ => l10n.weekday7,
};

/// `HH:MM` → heure.
TimeOfDay parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Heure → `HH:MM`.
String formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Heure affichée selon la langue (« 07:00 », « 7:00 AM »).
String displayTime(BuildContext context, String value) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      parseTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Délai lisible (« 30 min », « 1 h »).
String prepLabel(DymLocalizations l10n, int minutes) =>
    minutes >= 60 && minutes % 60 == 0
    ? l10n.storePrepHours(minutes ~/ 60)
    : l10n.storePrepMinutes(minutes);

/// Résumé des horaires : « Lundi au samedi, 07:00 – 19:00 » quand les jours
/// ouverts sont consécutifs avec les mêmes heures, sinon le nombre de jours.
String hoursSummary(BuildContext context, List<StoreHours> hours) {
  final l10n = DymLocalizations.of(context);
  if (hours.isEmpty) return l10n.storeHoursClosed;
  final days = [...hours]..sort((a, b) => a.weekday.compareTo(b.weekday));
  final first = days.first;
  final same = days.every(
    (h) => h.opensAt == first.opensAt && h.closesAt == first.closesAt,
  );
  final consecutive = days.last.weekday - first.weekday == days.length - 1;
  if (!same || !consecutive) return l10n.storeHoursDays(days.length);
  final opens = displayTime(context, first.opensAt);
  final closes = displayTime(context, first.closesAt);
  if (days.length == 1) {
    return l10n.storeHoursSingle(
      weekdayName(l10n, first.weekday),
      opens,
      closes,
    );
  }
  return l10n.storeHoursRange(
    weekdayName(l10n, first.weekday),
    '${days.last.weekday}',
    opens,
    closes,
  );
}
