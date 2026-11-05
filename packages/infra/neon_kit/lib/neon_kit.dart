/// Client Dart générique pour Neon : Auth (Better Auth REST), Data API
/// (PostgREST) et Functions. Aucune notion métier.
library;

export 'package:postgrest/postgrest.dart'
    show PostgrestClient, PostgrestFilterBuilder, PostgrestQueryBuilder;

export 'src/auth/neon_auth_client.dart';
export 'src/config.dart';
export 'src/data/neon_data_client.dart';
export 'src/errors.dart' show failureFrom;
export 'src/functions/neon_functions_client.dart' show NeonFunctionsClient;
export 'src/jwt.dart';
export 'src/neon_client.dart';
export 'src/retry.dart' show RetryPolicy;
export 'src/session.dart';
export 'src/storage/object_uploader.dart';
