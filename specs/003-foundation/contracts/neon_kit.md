# Contrat — `neon_kit`

```dart
final neon = NeonClient(
  config: NeonConfig(authUrl: …, dataApiUrl: …, functionsUrl: …),
  sessionStore: store,               // interface ; SecureSessionStore sur l'appareil
);

await neon.auth.sendEmailOtp(email)              → Result<void>
await neon.auth.verifyEmailOtp(email, otp)       → Result<NeonSession>
await neon.auth.signInWithGoogleIdToken(token)   → Result<NeonSession>
await neon.auth.restore()                        → Result<NeonSession?>   // au démarrage
await neon.auth.signOut()                        → Result<void>
neon.auth.sessionChanges                         → Stream<NeonSession?>

neon.data.from('table')                          → PostgrestQueryBuilder (jeton injecté)
await neon.data.run(() => query)                 → Result<T>              // exceptions → Failure
await neon.data.rpc<T>('fn', params: {...})      → Result<T>

await neon.functions.post<T>('slug', body: {...}, idempotencyKey: key)  → Result<T>
await neon.functions.get<T>('slug/path')                                → Result<T>
```

| Règle | Comportement |
|---|---|
| Jeton de la Data API | Renouvelé s'il expire dans moins de 60 s ; un seul renouvellement en vol |
| 401 | Renouvellement puis une nouvelle tentative ; un second 401 donne `UnauthenticatedFailure`, la session est effacée |
| Erreur réseau ou 5xx | Jusqu'à 3 tentatives (300 ms × 2ⁿ + aléa), seulement pour GET, HEAD, PUT, DELETE ou une requête portant `Idempotency-Key` |
| 4xx | Aucune nouvelle tentative ; conversion en `Failure` |
| Corps non JSON | `ServerFailure` |
| Journalisation | Aucun jeton, OTP ou email dans les journaux |
