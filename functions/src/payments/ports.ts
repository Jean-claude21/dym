// Paiements (spec 010, décision 0004) : un fournisseur derrière une interface
// commune ; la base décide des états (Postgres est la source de vérité).

import type { Purchase } from "../orders/ports.js";

export type PaymentOutcome = "succeeded" | "failed" | "cancelled";

export interface InitiateInput {
  paymentId: string;
  amountMinor: number;
  currencyCode: string;
  /** Référence courte affichée (PA-XXXXXX). */
  reference: string;
  /** Origine publique de la Function (pages servies par DYM). */
  selfOrigin: string;
  /** Cliente, pour les fournisseurs qui l'exigent (Moneroo) ; jamais journalisée. */
  customer?: { email: string; firstName: string };
}

export interface InitiateResult {
  providerReference: string;
  /** Page de paiement que l'app ouvre. */
  checkoutUrl: string;
}

/** Confirmation traduite dans le vocabulaire DYM. */
export interface NormalizedEvent {
  eventId: string;
  paymentId: string;
  outcome: PaymentOutcome;
  amountMinor: number;
  currencyCode: string;
}

/** Remboursement d'un paiement réussi (spec 013). */
export interface RefundInput {
  refundId: string;
  paymentId: string;
  /** Référence du paiement chez le fournisseur. */
  providerReference: string | null;
  amountMinor: number;
  currencyCode: string;
}

export interface RefundResult {
  ok: boolean;
  providerReference?: string;
  /** Raison technique d'un refus, sans donnée personnelle. */
  error?: string;
}

export interface PaymentProvider {
  /** `payment_providers.code`. */
  readonly code: string;
  /** Le fournisseur exige la cliente (email, prénom) à l'initiation. */
  readonly needsCustomer?: boolean;
  initiate(input: InitiateInput): Promise<InitiateResult>;
  /** Absent : le fournisseur ne sait pas rembourser (refus enregistré). */
  refund?(input: RefundInput): Promise<RefundResult>;
  /** Signature du corps brut (en-têtes en minuscules). */
  verifyWebhook(rawBody: string, headers: Record<string, string | undefined>): boolean;
  /** `null` : corps illisible. */
  normalizeEvent(rawBody: string): NormalizedEvent | null;
  /**
   * Avis incomplet (Moneroo) : relit le paiement chez le fournisseur.
   * `null` : rien à appliquer (paiement encore en cours).
   */
  resolveEvent?(rawBody: string): Promise<NormalizedEvent | null>;
}

/** Paiement à afficher sur la page du simulateur. */
export interface PaymentSummary {
  id: string;
  providerCode: string;
  status: string;
  amountMinor: number;
  currencyCode: string;
  /** Décimales et symbole du référentiel (affichage). */
  minorUnits: number;
  symbol: string;
  reference: string;
}

/** Règles en SQL (fonctions `app.*`). */
export interface PaymentStore {
  initiated(paymentId: string, providerReference: string, checkoutUrl: string): Promise<Purchase>;
  initiationFailed(paymentId: string, error: string): Promise<Purchase>;
  applyEvent(input: {
    provider: string;
    eventId: string;
    payload: unknown;
    signatureValid: boolean;
    paymentId: string | null;
    outcome: string | null;
    amountMinor: number | null;
    currencyCode: string | null;
  }): Promise<string>;
  retry(input: {
    userId: string;
    purchaseId: string;
    idempotencyKey: string;
    paymentMethodId: string | null;
    providers: string[];
  }): Promise<{ replayed: boolean; purchase: Purchase }>;
  switchToCash(userId: string, purchaseId: string): Promise<Purchase>;
  summary(paymentId: string): Promise<PaymentSummary | null>;
  /** Email et prénom de la cliente d'un paiement (fournisseurs qui l'exigent). */
  customer?(paymentId: string): Promise<{ email: string; firstName: string } | null>;
}
