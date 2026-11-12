import 'package:dym_ui/src/components/dym_avatar.dart';
import 'package:dym_ui/src/components/dym_badges.dart';
import 'package:dym_ui/src/foundation/store_origin.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Carte boutique : couverture, avatar, nom, badge d'origine, quartier.
class DymStoreCard extends StatelessWidget {
  /// Crée une carte boutique.
  const new({
    required this.cover,
    required this.avatar,
    required this.name,
    required this.origin,
    required this.originLabel,
    required this.meta,
    super.key,
    this.width = 200,
    this.onTap,
  });

  /// Photo de couverture.
  final ImageProvider cover;

  /// Avatar de la vendeuse.
  final ImageProvider avatar;

  /// Nom de la boutique.
  final String name;

  /// Origine.
  final StoreOrigin origin;

  /// Libellé de l'origine.
  final String originLabel;

  /// Quartier et distance (« Tokoin · 1,1 km »).
  final String meta;

  /// Largeur de la carte.
  final double width;

  /// Ouvre la page boutique.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    const coverHeight = 84.0;
    const avatarSize = 44.0;
    return SizedBox(
      width: width,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          side: BorderSide(color: c.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: coverHeight + avatarSize / 2,
                child: Stack(
                  children: [
                    Positioned.fill(
                      bottom: avatarSize / 2,
                      child: Image(
                        image: cover,
                        fit: BoxFit.cover,
                        // Photo absente ou réseau coupé : fond de la marque.
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: c.tintVertTendre,
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 40,
                            color: c.brand,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: DymTokenSpace.s3,
                      bottom: 0,
                      child: DymAvatar(image: avatar, size: avatarSize),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DymTokenSpace.s3,
                  DymTokenSpace.s1,
                  DymTokenSpace.s3,
                  DymTokenSpace.s3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.dym.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s1),
                    DymOriginBadge(origin: origin, label: originLabel),
                    const SizedBox(height: DymTokenSpace.s1),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.dym.text.label.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
