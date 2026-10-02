// Ports du catalogue : base, stockage d'objets et modèle d'IA, injectés pour
// tester sans réseau (fournisseurs derrière une interface, constitution IV).

/** Modèle configuré dans `ai_models` (usage `product_from_photo`). */
export interface AiModelConfig {
  provider: string;
  model: string;
  params: Record<string, unknown>;
}

export interface SuggestionContext {
  storeId: string;
  /** `null` : modèle inactif, saisie manuelle. */
  model: AiModelConfig | null;
  /** Rayons actifs (libellé français, parent compris). */
  categories: { id: string; label: string }[];
}

export interface ProductSuggestion {
  name: string;
  categoryId: string | null;
  description: string | null;
}

/** Règles en SQL : propriété, boutique suspendue, rayons actifs. */
export interface CatalogStore {
  /** Boutique où `userId` peut déposer des photos (erreur HTTP sinon). */
  photoUploadStore(userId: string): Promise<string>;
  suggestionContext(userId: string, objectKey: string): Promise<SuggestionContext>;
  recordSuggestion(input: {
    userId: string;
    objectKey: string;
    model: string;
    suggestion: ProductSuggestion;
  }): Promise<string>;
}

/** Stockage d'objets : URL présignée d'envoi, URL publique de lecture. */
export interface PhotoSigner {
  presignPut(key: string, contentType: string, expiresInSeconds: number): Promise<string>;
  publicUrl(key: string): string;
}

/** Proposition d'une fiche à partir d'une photo. */
export interface ProductSuggester {
  suggest(input: {
    model: AiModelConfig;
    imageUrl: string;
    categories: { id: string; label: string }[];
  }): Promise<ProductSuggestion>;
}
