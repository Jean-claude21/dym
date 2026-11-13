import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Lignes collées depuis un tableur : une ligne par produit, colonnes
/// séparées par une tabulation, un point-virgule ou une virgule ; une ligne
/// d'en-tête (« nom », « name ») est ignorée.
List<ImportRow> parseImportText(String text) {
  final rows = <ImportRow>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final sep = line.contains('\t') ? '\t' : (line.contains(';') ? ';' : ',');
    final cells = [for (final c in line.split(sep)) c.trim()];
    final first = cells.first.toLowerCase();
    if (rows.isEmpty && (first == 'nom' || first == 'name')) continue;
    String at(int i) => i < cells.length ? cells[i] : '';
    rows.add(
      ImportRow(
        name: at(0),
        price: at(1),
        unit: at(2),
        category: at(3),
        stock: at(4),
      ),
    );
  }
  return rows;
}

/// Import en masse du catalogue (spec 081) : coller, vérifier, importer.
class ImportProductsViewModel extends BaseViewModel {
  new({required this.service});

  final CatalogService service;

  String text = '';
  List<ImportRow> _rows = const [];
  ImportReport? _check;
  ImportReport? _done;
  Failure? _failure;

  List<ImportRow> get rows => _rows;

  /// Aperçu du serveur pour le texte actuel (nul : à vérifier).
  ImportReport? get check => _check;

  /// Import terminé.
  ImportReport? get done => _done;
  Failure? get failure => _failure;
  bool get canCheck => parseImportText(text).isNotEmpty && !isBusy;
  bool get canImport => (_check?.valid ?? 0) > 0 && !isBusy && _done == null;

  void setText(String value) {
    text = value;
    _check = null;
    _failure = null;
    notifyListeners();
  }

  Future<void> verify() async {
    _rows = parseImportText(text);
    if (_rows.isEmpty) return;
    _failure = null;
    final result = await runBusyFuture(
      service.importProducts(_rows, dry: true),
    );
    switch (result) {
      case Ok(:final value):
        _check = value;
      case Err(:final failure):
        _failure = failure;
    }
    notifyListeners();
  }

  Future<void> import() async {
    if (!canImport) return;
    final result = await runBusyFuture(
      service.importProducts(_rows, dry: false),
    );
    switch (result) {
      case Ok(:final value):
        _done = value;
      case Err(:final failure):
        _failure = failure;
    }
    notifyListeners();
  }
}

class ImportProductsView extends StackedView<ImportProductsViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final CatalogService service;
  final VoidCallback onBack;

  @override
  ImportProductsViewModel viewModelBuilder(BuildContext context) =>
      ImportProductsViewModel(service: service);

  @override
  Widget builder(
    BuildContext context,
    ImportProductsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    String reason(String code) => switch (code) {
      'name_invalid' => l10n.importNameInvalid,
      'price_invalid' => l10n.importPriceInvalid,
      'category_unknown' => l10n.importCategoryUnknown,
      'unit_unknown' => l10n.importUnitUnknown,
      'stock_invalid' => l10n.importStockInvalid,
      _ => l10n.errorGeneric,
    };
    final check = vm.check;
    final done = vm.done;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(DymLayout.gutter(context)),
          children: [
            DymContentWidth.form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.authBack,
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          l10n.importTitle,
                          style: t.display.copyWith(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  Text(l10n.importHelp, style: t.body),
                  const SizedBox(height: DymTokenSpace.s2),
                  Container(
                    padding: const EdgeInsets.all(DymTokenSpace.s3),
                    decoration: BoxDecoration(
                      color: c.tintVertTendre,
                      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    ),
                    child: Text(
                      l10n.importExample,
                      style: t.label.copyWith(
                        color: c.brandDeep,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  if (done == null) ...[
                    TextField(
                      minLines: 8,
                      maxLines: 16,
                      onChanged: vm.setText,
                      decoration: InputDecoration(
                        labelText: l10n.importPasteLabel,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymButton(
                      label: l10n.importCheck,
                      icon: Icons.fact_check_outlined,
                      variant: DymButtonVariant.secondary,
                      loading: vm.isBusy && check == null,
                      onPressed: vm.canCheck ? vm.verify : null,
                    ),
                  ],
                  if (vm.failure != null) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      vm.failure is NetworkFailure
                          ? l10n.errorOffline
                          : l10n.errorGeneric,
                      style: t.label.copyWith(color: c.pimentStrong),
                    ),
                  ],
                  if (check != null && done == null) ...[
                    const SizedBox(height: DymTokenSpace.s3),
                    Text(
                      l10n.importSummary(check.valid, check.errors.length),
                      style: t.title.copyWith(fontSize: 18),
                    ),
                    for (final e in check.errors)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: c.pimentStrong,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.importLineError(e.line, reason(e.reason)),
                                style: t.label.copyWith(color: c.pimentStrong),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymButton(
                      label: l10n.importRun(check.valid),
                      icon: Icons.upload_rounded,
                      loading: vm.isBusy,
                      onPressed: vm.canImport ? vm.import : null,
                    ),
                  ],
                  if (done != null) ...[
                    DymStateView(
                      kind: DymStateKind.empty,
                      icon: Icons.check_circle_outline_rounded,
                      title: l10n.importDone(done.valid),
                      message: l10n.importDoneHint,
                      actionLabel: l10n.importBackToCatalog,
                      onAction: onBack,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
