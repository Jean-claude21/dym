import 'package:dio/dio.dart';

/// Hors navigateur : adaptateur par défaut (le cookie est rejoué en en-tête).
HttpClientAdapter? credentialsAdapter() => null;
