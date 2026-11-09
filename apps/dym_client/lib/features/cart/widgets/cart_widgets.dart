import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Rend le panier accessible aux écrans de découverte (ajout, mini-panier).
/// Absent (galerie, tests de découverte) : pas d'ajout ni de mini-panier.
class CartScope extends InheritedWidget {
  const new({
    required this.service,
    required this.onOpenCart,
    required super.child,
    super.key,
  });

  final CartService service;

  /// Ouvre le panier (écran 05).
  final VoidCallback onOpenCart;

  static CartScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>();

  @override
  bool updateShouldNotify(CartScope oldWidget) =>
      service != oldWidget.service || onOpenCart != oldWidget.onOpenCart;
}

/// Ajoute une variante depuis un écran de découverte ; message en cas de
/// refus (rupture, autre pays, hors ligne).
Future<void> addToCart(
  BuildContext context,
  String variantId, {
  int quantity = 1,
  bool confirm = false,
}) async {
  final scope = CartScope.maybeOf(context);
  if (scope == null) return;
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await scope.service.add(variantId, quantity: quantity);
  final message = switch (result) {
    Ok() => confirm ? l10n.cartAdded : null,
    Err(failure: NetworkFailure()) => l10n.errorOffline,
    Err(failure: ValidationFailure(message: 'other_country')) =>
      l10n.cartOtherCountry,
    Err(failure: ValidationFailure()) => l10n.cartUnavailable,
    Err() => l10n.errorGeneric,
  };
  if (message != null) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Quantité d'une variante dans le panier courant.
int cartQuantityOf(CartView cart, String? variantId) {
  if (variantId == null) return 0;
  for (final store in cart.stores) {
    for (final line in store.lines) {
      if (line.variantId == variantId) return line.quantity;
    }
  }
  return 0;
}

/// Mini-panier flottant (caché à 0 article), borné par `DymMiniCartBar`.
class MiniCart extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CartScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    final l10n = DymLocalizations.of(context);
    return ValueListenableBuilder<CartView>(
      valueListenable: scope.service.cart,
      builder: (context, cart, _) {
        final currency = cart.currency?.toCurrency();
        if (currency == null) return const SizedBox.shrink();
        return DymMiniCartBar(
          itemCount: cart.itemCount,
          total: Money(cart.totalMinor, currency),
          summary: l10n.cartMiniSummary(cart.storeCount, cart.itemCount),
          actionLabel: l10n.cartView,
          onTap: scope.onOpenCart,
        );
      },
    );
  }
}

/// Écran avec le mini-panier posé en bas du contenu.
class WithMiniCart extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: child),
      const Positioned(left: 16, right: 16, bottom: 12, child: MiniCart()),
    ],
  );
}

/// En-tête des écrans du panier : retour, titre, sous-titre.
class CartHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.onBack,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return DymContentWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.authBack,
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: t.display.copyWith(fontSize: 24),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: t.label.copyWith(
                        color: c.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Carte blanche des écrans du panier.
class CartCard extends StatelessWidget {
  const new({required this.child, super.key, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DymTokenSpace.s3),
    decoration: BoxDecoration(
      color: color ?? context.dym.colors.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
    ),
    child: child,
  );
}

/// Pastille d'alerte (rupture, boutique fermée…) : icône + texte.
class CartIssue extends StatelessWidget {
  const new({required this.label, super.key, this.blocking = true});

  final String label;
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final color = blocking ? c.pimentStrong : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: DymTokenSpace.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocking ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: DymTokenSpace.s1),
          Expanded(
            child: Text(
              label,
              style: context.dym.text.label.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé d'un problème de ligne.
String lineIssueLabel(DymLocalizations l10n, CartLine line, CartLineIssue i) =>
    switch (i) {
      CartLineIssue.unavailable => l10n.cartIssueUnavailable,
      CartLineIssue.stock => l10n.cartIssueStock(line.stockQuantity ?? 0),
      CartLineIssue.priceChanged => l10n.cartIssuePriceChanged,
      CartLineIssue.unknown => l10n.errorGeneric,
    };

/// Libellé d'un problème de boutique.
String storeIssueLabel(DymLocalizations l10n, CartStoreIssue i) => switch (i) {
  CartStoreIssue.suspended => l10n.cartIssueSuspended,
  CartStoreIssue.closed => l10n.cartIssueClosed,
  CartStoreIssue.notDelivered => l10n.cartIssueNotDelivered,
  CartStoreIssue.pickupUnavailable => l10n.cartIssuePickupUnavailable,
  CartStoreIssue.paymentNotAccepted => l10n.cartIssuePaymentNotAccepted,
  CartStoreIssue.unknown => l10n.errorGeneric,
};

/// Message d'un refus de commande.
String orderErrorLabel(DymLocalizations l10n, OrderError error) =>
    switch (error) {
      OrderError.empty => l10n.orderErrorEmpty,
      OrderError.blocked => l10n.cartBlocked,
      OrderError.addressRequired => l10n.orderErrorAddressRequired,
      OrderError.totalChanged => l10n.orderErrorTotalChanged,
      OrderError.paymentUnavailable => l10n.orderErrorPaymentUnavailable,
      OrderError.ownStore => l10n.orderErrorOwnStore,
      OrderError.offline => l10n.errorOffline,
      OrderError.generic => l10n.errorGeneric,
    };

/// Nom affiché d'une adresse (libellé libre, sinon son type).
String addressTitle(DymLocalizations l10n, AddressKind kind, String? label) =>
    label ??
    switch (kind) {
      AddressKind.home => l10n.addressKindHome,
      AddressKind.work => l10n.addressKindWork,
      AddressKind.other => l10n.addressKindOther,
    };

/// Icône d'un type d'adresse.
IconData addressIcon(AddressKind kind) => switch (kind) {
  AddressKind.home => Icons.home_rounded,
  AddressKind.work => Icons.work_rounded,
  AddressKind.other => Icons.location_on_rounded,
};

/// Ligne « libellé … montant » d'un récapitulatif.
class SumRow extends StatelessWidget {
  const new({
    required this.label,
    required this.amount,
    super.key,
    this.strong = false,
  });

  final String label;
  final Money? amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? t.title.copyWith(fontSize: 20)
                  : t.label.copyWith(fontSize: 15, color: c.textSecondary),
            ),
          ),
          if (amount != null)
            MoneyText(
              amount!,
              size: strong ? 22 : 15,
              color: strong ? c.brandDeep : c.textPrimary,
            ),
        ],
      ),
    );
  }
}
