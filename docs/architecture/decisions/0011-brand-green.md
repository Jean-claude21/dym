# 0011 — Couleur de marque : vert profond

**Statut :** Acceptée · 2026-10-02 · Remplace la couleur de marque de 0009 (le reste de 0009 reste valable)

## Contexte

La direction 0009 utilisait le vert gombo `#3F7D32`. En comparant avec la base universelle (v3),
le porteur produit préfère le vert profond `#0B5D3F`, plus net et plus premium. Deux accents étaient
possibles : citron vert (v3) ou jaune plantain (validé dans la trajectoire).

## Décision

- Couleur de marque et d'action : **vert profond `#0B5D3F`** (token `color.brand.primary`).
- Variante foncée : **`#08452F`** (`color.brand.primary-deep`) pour l'app vendeuse et le texte vert.
- Accent conservé : **jaune plantain `#F2C14E`** (option A).
- Les tokens sont nommés par rôle (`primary`) et non plus par couleur (`gombo`).

## Conséquences

Contrastes mesurés (tous ≥ 4,5:1) :

| Couple | Avant | Après |
|---|---|---|
| Blanc / marque | 5.01 | 7.92 |
| Marque / crème | 4.65 | 7.35 |
| Plantain / marque (bouton du mini-panier) | 2.99 | 4.72 |
| Badge « Au marché » | 6.59 | 9.5 |

Changement appliqué en régénérant le thème depuis les tokens, sans modifier aucun composant.
