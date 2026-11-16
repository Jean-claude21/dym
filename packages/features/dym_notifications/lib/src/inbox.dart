import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Notifications d'une app (spec 097) : texte rendu par la base dans la
/// langue de la personne. Remplaçable en test.
abstract interface class NotificationInboxService {
  Future<Result<List<AppNotification>>> list();

  Future<Result<int>> unread();

  Future<void> markRead(List<String> ids);
}

class NeonNotificationInboxService implements NotificationInboxService {
  new(this._repository, {required this.app});

  final NotificationRepository _repository;

  /// `vendor` ou `delivery`.
  final String app;

  @override
  Future<Result<List<AppNotification>>> list() =>
      _repository.appNotifications(app);

  @override
  Future<Result<int>> unread() => _repository.unreadAppCount(app);

  @override
  Future<void> markRead(List<String> ids) async {
    if (ids.isNotEmpty) await _repository.markRead(ids);
  }
}

/// Notifications en mémoire (tests, galerie).
class MemoryNotificationInboxService implements NotificationInboxService {
  new([List<AppNotification> items = const []]) : items = [...items];

  final List<AppNotification> items;
  final read = <String>[];

  @override
  Future<Result<List<AppNotification>>> list() async => Ok([...items]);

  @override
  Future<Result<int>> unread() async =>
      Ok(items.where((n) => n.unread && !read.contains(n.id)).length);

  @override
  Future<void> markRead(List<String> ids) async => read.addAll(ids);
}

class NotificationInboxViewModel extends BaseViewModel {
  new({required this.service});

  final NotificationInboxService service;
  List<AppNotification>? items;
  Failure? failure;

  Future<void> load() async {
    failure = null;
    switch (await service.list()) {
      case Ok(:final value):
        items = value;
        // Ouvrir la boîte vaut lecture.
        unawaited(
          service.markRead([
            for (final n in value)
              if (n.unread) n.id,
          ]),
        );
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }
}

/// Boîte de notifications : la plus récente en haut, non lues marquées ;
/// toucher ouvre l'écran concerné ([onOpen]).
class NotificationInboxView extends StackedView<NotificationInboxViewModel> {
  const new({required this.service, required this.onOpen, super.key});

  final NotificationInboxService service;
  final ValueChanged<AppNotification> onOpen;

  @override
  NotificationInboxViewModel viewModelBuilder(BuildContext context) =>
      NotificationInboxViewModel(service: service);

  @override
  void onViewModelReady(NotificationInboxViewModel viewModel) =>
      unawaited(viewModel.load());

  static IconData _icon(String kind) => switch (kind) {
    final k when k.startsWith('incoming_call') || k.startsWith('call_') =>
      Icons.call_rounded,
    final k when k.contains('message') => Icons.chat_bubble_outline_rounded,
    final k when k.contains('mission') || k.contains('courier') =>
      Icons.two_wheeler_rounded,
    final k when k.contains('stock') => Icons.inventory_2_outlined,
    final k when k.contains('review') => Icons.star_outline_rounded,
    final k when k.contains('dispute') => Icons.gavel_rounded,
    _ => Icons.receipt_long_outlined,
  };

  @override
  Widget builder(
    BuildContext context,
    NotificationInboxViewModel vm,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final c = context.dym.colors;
    final t = context.dym.text;
    final items = vm.items;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: items == null
          ? (vm.failure == null
                ? const Center(child: CircularProgressIndicator())
                : DymStateView(
                    kind: DymStateKind.error,
                    title: vm.failure is NetworkFailure
                        ? l10n.errorOffline
                        : l10n.errorLoadMessage,
                    message: '',
                    actionLabel: l10n.retry,
                    onAction: vm.load,
                  ))
          : items.isEmpty
          ? DymStateView(
              kind: DymStateKind.empty,
              title: l10n.notificationsEmptyTitle,
              message: l10n.inboxEmptyMessage,
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(color: c.hairline, height: 1),
                itemBuilder: (context, i) {
                  final n = items[i];
                  return ListTile(
                    minVerticalPadding: DymTokenSpace.s3,
                    leading: CircleAvatar(
                      backgroundColor: n.unread ? c.tintVertTendre : c.muted,
                      child: Icon(_icon(n.kind), color: c.brandDeep),
                    ),
                    title: Text(
                      n.title ?? '',
                      style: t.body.copyWith(
                        fontWeight: n.unread
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(n.body ?? ''),
                    trailing: Text(
                      MaterialLocalizations.of(context)
                                  .formatShortDate(n.createdAt.toLocal()) ==
                              MaterialLocalizations.of(context)
                                  .formatShortDate(DateTime.now())
                          ? TimeOfDay.fromDateTime(n.createdAt.toLocal())
                                .format(context)
                          : MaterialLocalizations.of(context)
                                .formatShortMonthDay(n.createdAt.toLocal()),
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                    onTap: () => onOpen(n),
                  );
                },
              ),
            ),
    );
  }
}

/// Cloche de l'app : nombre de non-lues, relu à chaque retour à l'écran.
class NotificationBell extends StatefulWidget {
  const new({required this.service, required this.onTap, super.key});

  final NotificationInboxService service;
  final Future<void> Function() onTap;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _read());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _read() async {
    if (await widget.service.unread() case Ok(:final value) when mounted) {
      setState(() => _unread = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () async {
        await widget.onTap();
        await _read();
      },
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 99 ? '99+' : '$_unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
