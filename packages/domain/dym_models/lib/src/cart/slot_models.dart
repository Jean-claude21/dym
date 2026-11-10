/// Créneaux de livraison (spec 033), proposés par la base.
library;

/// Un créneau horaire (heures locales du pays, « HH:MM »).
class DeliveryWindow {
  const new({required this.id, required this.startsAt, required this.endsAt});

  factory fromJson(Map<String, dynamic> json) => DeliveryWindow(
    id: json['id'] as String,
    startsAt: json['starts_at'] as String,
    endsAt: json['ends_at'] as String,
  );

  final String id;
  final String startsAt;
  final String endsAt;
}

/// Un jour et ses créneaux encore possibles.
class DeliveryDay {
  const new({required this.date, this.windows = const []});

  factory fromJson(Map<String, dynamic> json) => DeliveryDay(
    date: DateTime.parse(json['date'] as String),
    windows: [
      for (final w in json['windows'] as List? ?? const [])
        DeliveryWindow.fromJson(w as Map<String, dynamic>),
    ],
  );

  final DateTime date;
  final List<DeliveryWindow> windows;
}

/// Créneaux du panier : obligatoires s'il contient un arrivage.
class DeliverySlots {
  const new({this.required = false, this.minDate, this.days = const []});

  factory fromJson(Map<String, dynamic> json) => DeliverySlots(
    required: json['required'] as bool? ?? false,
    minDate: switch (json['min_date']) {
      final String d => DateTime.parse(d),
      _ => null,
    },
    days: [
      for (final d in json['days'] as List? ?? const [])
        DeliveryDay.fromJson(d as Map<String, dynamic>),
    ],
  );

  final bool required;
  final DateTime? minDate;
  final List<DeliveryDay> days;
}

/// Créneau choisi pour une commande.
class SlotChoice {
  const new({required this.date, required this.windowId});

  final DateTime date;
  final String windowId;

  Map<String, Object?> toJson() => {
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'window_id': windowId,
  };
}
