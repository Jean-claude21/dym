import { describe, expect, it } from "vitest";
import { WALLET, walletProvider } from "../src/payments/wallet.js";

describe("wallet (spec 025)", () => {
  const provider = walletProvider();

  it("porte le code du référentiel", () => {
    expect(provider.code).toBe(WALLET);
  });

  it("n'est jamais initié : la base règle le paiement", async () => {
    await expect(
      provider.initiate({
        paymentId: "p",
        amountMinor: 100,
        currencyCode: "XOF",
        reference: "PA-1",
        selfOrigin: "https://x",
      }),
    ).rejects.toThrow();
  });

  it("accepte les remboursements (rendus au wallet par la base)", async () => {
    await expect(
      provider.refund?.({
        refundId: "r",
        paymentId: "p",
        providerReference: null,
        amountMinor: 100,
        currencyCode: "XOF",
      }),
    ).resolves.toEqual({ ok: true });
  });

  it("refuse tout webhook", () => {
    expect(provider.verifyWebhook("{}", {})).toBe(false);
    expect(provider.normalizeEvent("{}")).toBeNull();
  });
});
