import type { PaymentProvider } from "./ports.js";

/** `payment_providers.code` du wallet DYM (spec 025). */
export const WALLET = "wallet";

/**
 * Wallet DYM : rail interne, sans service externe. Le paiement est réglé par la
 * base dès la création de la commande (`app.wallet_settle_payment`) ; il n'est
 * donc jamais initié ici. Un remboursement est accepté : la base le rend au
 * wallet quand il passe à « réussi » (grand livre, `app.ledger_refund_paid`).
 */
export function walletProvider(): PaymentProvider {
  return {
    code: WALLET,
    initiate() {
      return Promise.reject(new Error("wallet : réglé par la base, jamais initié"));
    },
    refund() {
      return Promise.resolve({ ok: true });
    },
    verifyWebhook() {
      return false;
    },
    normalizeEvent() {
      return null;
    },
  };
}
