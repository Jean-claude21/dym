part of 'chat_views.dart';

/// Nom d'un groupe demandé à la création (fenêtre).
Future<String?> askGroupName(BuildContext context, {String? initial}) =>
    showDialog<String>(
      context: context,
      builder: (dialog) => _GroupNameDialog(initial: initial),
    );

class _GroupNameDialog extends StatefulWidget {
  const new({this.initial});

  final String? initial;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final _name = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _name.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.chatNewGroupTitle : l10n.chatRenameGroup,
      ),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.chatGroupNameLabel,
          hintText: l10n.chatGroupNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _name,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(
              widget.initial == null ? l10n.chatCreate : l10n.chatRenameGroup,
            ),
          ),
        ),
      ],
    );
  }
}

/// Infos du groupe (spec 112) : membres, ajout par code DYM, retrait,
/// nom, quitter.
class GroupInfoPage extends StatefulWidget {
  const new({required this.vm, required this.onLeft, super.key});

  final ChatViewModel vm;

  /// Groupe quitté : retour à la liste.
  final VoidCallback onLeft;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.vm.loadGroup());
  }

  Future<void> _add() async {
    final l10n = DymLocalizations.of(context);
    final code = await showDialog<String>(
      context: context,
      builder: (dialog) => _CodeDialog(),
    );
    if (code == null || !mounted) return;
    final problem = await widget.vm.addMember(code);
    if (problem == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (problem) {
          'recipient_unknown' => l10n.chatMemberUnknown,
          'group_full' => l10n.chatGroupFull,
          _ => l10n.errorGeneric,
        }),
      ),
    );
  }

  Future<void> _remove(GroupMember m) async {
    final l10n = DymLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.chatRemoveMember(m.firstName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: TextButton.styleFrom(
              foregroundColor: context.dym.colors.pimentStrong,
            ),
            child: Text(l10n.chatRemoveMember(m.firstName)),
          ),
        ],
      ),
    );
    if (ok ?? false) await widget.vm.removeMember(m.userId);
  }

  Future<void> _leave(String title) async {
    final l10n = DymLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.chatLeaveConfirm(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: TextButton.styleFrom(
              foregroundColor: context.dym.colors.pimentStrong,
            ),
            child: Text(l10n.chatLeaveGroup),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    if (await widget.vm.leaveGroup() && mounted) {
      Navigator.pop(context);
      widget.onLeft();
    }
  }

  Future<void> _rename(String current) async {
    final title = await askGroupName(context, initial: current);
    if (title != null) await widget.vm.renameGroup(title);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final g = widget.vm.group;
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: c.card,
            title: Text(l10n.chatGroupInfo),
            leading: IconButton(
              tooltip: l10n.authBack,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: g == null
              ? Center(child: CircularProgressIndicator(color: c.brand))
              : ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: DymLayout.gutter(context),
                    vertical: DymTokenSpace.s3,
                  ),
                  children: [
                    DymContentWidth.form(
                      child: Column(
                        children: [
                          _Avatar(
                            name: g.title,
                            radius: 40,
                            icon: g.isFamily
                                ? Icons.family_restroom_rounded
                                : Icons.shopping_basket_rounded,
                          ),
                          const SizedBox(height: DymTokenSpace.s2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  g.title,
                                  textAlign: TextAlign.center,
                                  style: t.title.copyWith(fontSize: 24),
                                ),
                              ),
                              if (g.isFamily && g.meAdmin)
                                IconButton(
                                  tooltip: l10n.chatRenameGroup,
                                  onPressed: () => _rename(g.title),
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    color: c.brandDeep,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            [
                              if (g.isFamily)
                                l10n.chatFamilyLabel
                              else
                                l10n.chatGroupBuyLabel,
                              l10n.chatMembers(g.members.length),
                              ?g.storeName,
                            ].join(' · '),
                            textAlign: TextAlign.center,
                            style: t.label.copyWith(color: c.textSecondary),
                          ),
                          const SizedBox(height: DymTokenSpace.s3),
                          if (g.isFamily && g.meAdmin)
                            DymButton(
                              label: l10n.chatAddMember,
                              icon: Icons.person_add_alt_1_rounded,
                              onPressed: _add,
                            ),
                          const SizedBox(height: DymTokenSpace.s2),
                          for (final m in g.members)
                            ListTile(
                              minTileHeight: DymTokenSize.touchMin + 8,
                              contentPadding: EdgeInsets.zero,
                              leading: _Avatar(name: m.firstName, radius: 22),
                              title: Text(
                                m.me ? l10n.chatYouName : m.firstName,
                              ),
                              subtitle: m.admin ? Text(l10n.chatAdmin) : null,
                              trailing: g.isFamily && g.meAdmin && !m.me
                                  ? IconButton(
                                      tooltip: l10n.chatRemoveMember(
                                        m.firstName,
                                      ),
                                      onPressed: () => _remove(m),
                                      icon: Icon(
                                        Icons.person_remove_alt_1_rounded,
                                        color: c.pimentStrong,
                                      ),
                                    )
                                  : null,
                            ),
                          if (g.isFamily && !g.meAdmin) ...[
                            const SizedBox(height: DymTokenSpace.s3),
                            TextButton.icon(
                              onPressed: () => _leave(g.title),
                              style: TextButton.styleFrom(
                                foregroundColor: c.pimentStrong,
                                minimumSize: const Size(
                                  48,
                                  DymTokenSize.touchMin,
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(l10n.chatLeaveGroup),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Code DYM d'un proche.
class _CodeDialog extends StatefulWidget {
  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.chatAddMember),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.peopleCodeTitle),
          ),
          const SizedBox(height: DymTokenSpace.s1),
          Text(
            l10n.chatMemberCodeHelp,
            style: context.dym.text.label.copyWith(
              color: context.dym.colors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _code,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, value.text.trim()),
            child: Text(l10n.chatAddMember),
          ),
        ),
      ],
    );
  }
}
