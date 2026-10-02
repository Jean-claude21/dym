import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Navigateur : le cookie de session de Neon Auth est envoyé par le
/// navigateur lui-même (`withCredentials`) ; l'en-tête `Cookie` est interdit.
HttpClientAdapter? credentialsAdapter() =>
    BrowserHttpClientAdapter()..withCredentials = true;
