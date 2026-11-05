// Ports de la recherche IA (spec 018) : base et modèles, injectés pour tester
// sans réseau (fournisseurs derrière une interface, constitution IV).
import type { AiModelConfig } from "../catalog/ports.js";

export type SearchAiUsage = "search_transcription" | "search_from_photo";

export type AiOutcome = "success" | "no_result" | "failure";

/** Règles en SQL : flag `ai_search` du pays, modèle actif, journal. */
export interface SearchAiStore {
  /** Modèle de l'usage ; erreur `feature_disabled` si la fonction est coupée. */
  context(userId: string, usage: SearchAiUsage): Promise<AiModelConfig>;
  record(userId: string, usage: SearchAiUsage, outcome: AiOutcome, latencyMs: number): Promise<void>;
}

/** Transcription d'un court message vocal ; `null` : rien compris. */
export interface Transcriber {
  transcribe(input: { model: AiModelConfig; audio: Uint8Array; mediaType: string }): Promise<string | null>;
}

/** Texte de recherche tiré d'une photo ; `null` : rien de reconnaissable. */
export interface PhotoDescriber {
  describe(input: { model: AiModelConfig; image: Uint8Array; mediaType: string }): Promise<string | null>;
}
