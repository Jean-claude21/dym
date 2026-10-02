// Ports des commandes (spec 009) : la base décide de tout (montants, refus,
// idempotence) ; la route ne fait que valider et transmettre.

export type Fulfillment = "delivery" | "pickup";

export interface OrderRequest {
  addressId: string | null;
  modes: Record<string, Fulfillment>;
  paymentMethodId: string;
  substitutionAllowed: boolean;
  expectedTotalMinor: number | null;
}

/** Achat tel que servi par `app.purchase_json` (sans commission). */
export type Purchase = Record<string, unknown> & { id: string };

export interface PlacedOrder {
  /** Vrai : la clé avait déjà servi ; l'achat existant est rendu. */
  replayed: boolean;
  purchase: Purchase;
}

/** Refus de `app.place_order` : erreur HTTP 422 dont le message est le code. */
export interface OrderStore {
  placeOrder(userId: string, idempotencyKey: string, request: OrderRequest): Promise<PlacedOrder>;
}
