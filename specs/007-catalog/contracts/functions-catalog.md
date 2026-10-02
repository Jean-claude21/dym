# Contrat — Functions du catalogue

Erreurs normalisées : [`specs/003-foundation/contracts/functions-http.md`](../../003-foundation/contracts/functions-http.md).
Cette spec ajoute le code `unavailable` (503) : un service externe n'est pas configuré ou est en
échec. L'app passe alors au repli prévu, sans réessayer automatiquement, et sans valeur inventée.

Toutes les routes exigent `Authorization: Bearer <JWT Neon Auth>`.

## `POST /v1/catalog/photo-uploads`

Corps : `{ "content_type": "image/jpeg" | "image/webp" }`

Réponse 200 :

```json
{
  "object_key": "stores/<store_id>/products/<uuid>.jpg",
  "upload_url": "https://…?X-Amz-Signature=…",
  "public_url": "https://…/product-photos/stores/<store_id>/products/<uuid>.jpg",
  "expires_in": 300
}
```

L'app envoie ensuite la photo par `PUT upload_url`, avec l'en-tête `Content-Type` et sans jeton.
Erreurs :
- 404 : aucune boutique ;
- 403 : boutique suspendue ;
- 422 : type refusé ;
- 503 : stockage non configuré.

## `POST /v1/catalog/suggestions`

Corps : `{ "object_key": "stores/<store_id>/products/<uuid>.jpg" }`

Réponse 200 :

```json
{ "suggestion_id": "<uuid>", "name": "Jus de bissap 50 cl", "category_id": "<uuid> | null", "description": "… | null" }
```

Le modèle est celui de `ai_models` (usage `product_from_photo`, actif). La proposition est
conservée dans `app.ai_product_suggestions`. L'app transmet `suggestion_id` à `save_product` ;
la publication compare la fiche et la proposition (`ai_product_suggestion_accepted`).

Erreurs :
- 403 : photo d'une autre boutique ;
- 422 : clé invalide ;
- 503 : modèle inactif, fournisseur absent ou en échec.
