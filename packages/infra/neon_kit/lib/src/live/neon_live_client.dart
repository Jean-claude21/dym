import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dym_core/dym_core.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Ouvre une connexion WebSocket (remplaçable dans les tests).
typedef LiveConnector = Future<StreamChannel<Object?>> Function(Uri uri);

/// État de la connexion temps réel.
enum LiveStatus { idle, connecting, online, waiting }

/// Client de la passerelle temps réel `GET /v1/live` des Functions (spec 067).
///
/// - jeton frais à chaque connexion (`?access_token=`, seul moyen côté web) ;
/// - reprise après coupure avec le dernier événement reçu (`?after=`) ;
/// - reconnexion progressive (1 s à 30 s, avec aléa) ;
/// - un signal [LiveSignal.resync] à chaque connexion : les écrans rechargent.
///
/// L'app appelle [start] quand elle passe au premier plan avec une session,
/// [stop] en arrière-plan ou à la déconnexion.
class NeonLiveClient implements LiveFeed {
  new({
    required this._functionsUrl,
    required this._token,
    LiveConnector? connect,
    Random? random,
  }) : _connect = connect ?? _webSocket,
       _random = random ?? Random();

  final Uri _functionsUrl;
  final Future<Result<String>> Function() _token;
  final LiveConnector _connect;
  final Random _random;
  final _signals = StreamController<LiveSignal>.broadcast();
  final _status = StreamController<LiveStatus>.broadcast();

  StreamChannel<Object?>? _channel;
  // Annulé dans _closeChannel (arrêt ou coupure).
  // ignore: cancel_subscriptions
  StreamSubscription<Object?>? _sub;
  Timer? _retry;
  int _attempt = 0;
  int? _cursor;
  bool _wanted = false;
  LiveStatus _state = LiveStatus.idle;

  @override
  Stream<LiveSignal> get signals => _signals.stream;

  Stream<LiveStatus> get statuses => _status.stream;

  LiveStatus get status => _state;

  /// Démarre (ou garde) la connexion.
  void start() {
    if (_wanted) return;
    _wanted = true;
    _attempt = 0;
    unawaited(_open());
  }

  /// Ferme la connexion et annule toute reprise.
  Future<void> stop() async {
    _wanted = false;
    _retry?.cancel();
    _retry = null;
    _set(LiveStatus.idle);
    await _closeChannel();
  }

  Future<void> dispose() async {
    await stop();
    await _signals.close();
    await _status.close();
  }

  /// URL de la passerelle (`https` → `wss`).
  Uri uriFor(String token) {
    final base = _functionsUrl;
    final path = base.path.endsWith('/')
        ? '${base.path}v1/live'
        : '${base.path}/v1/live';
    return base.replace(
      scheme: base.scheme == 'http' ? 'ws' : 'wss',
      path: path,
      queryParameters: {'access_token': token, 'after': ?_cursor?.toString()},
    );
  }

  Future<void> _open() async {
    if (!_wanted) return;
    _set(LiveStatus.connecting);
    final token = await _token();
    if (!_wanted) return;
    if (token case Err()) {
      _scheduleRetry();
      return;
    }
    try {
      final channel = await _connect(uriFor(token.valueOrNull!));
      if (!_wanted) {
        unawaited(channel.sink.close());
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onError: (_) => _onLost(),
        onDone: _onLost,
        cancelOnError: true,
      );
    } on Object {
      _scheduleRetry();
    }
  }

  void _onMessage(Object? raw) {
    final Object? data;
    try {
      data = jsonDecode(raw is String ? raw : utf8.decode(raw! as List<int>));
    } on Object {
      return;
    }
    if (data is! Map<String, Object?>) return;
    switch (data['type']) {
      case 'ready':
        _attempt = 0;
        _cursor ??= (data['cursor'] as num?)?.toInt();
        _set(LiveStatus.online);
        _signals.add(const LiveSignal.resync());
      case 'event':
        final id = (data['id'] as num?)?.toInt();
        if (id != null && (_cursor == null || id > _cursor!)) _cursor = id;
        _signals.add(
          LiveSignal.event(
            kind: data['kind'] as String? ?? '',
            entityId: data['entity_id'] as String?,
            payload: (data['payload'] as Map?)?.cast<String, Object?>() ?? {},
          ),
        );
      default:
      // `ping` : signal de vie, rien à faire.
    }
  }

  void _onLost() {
    unawaited(_closeChannel());
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_wanted) return;
    _set(LiveStatus.waiting);
    final seconds = min(30, 1 << min(_attempt, 5));
    _attempt++;
    final jitter = _random.nextInt(500);
    _retry?.cancel();
    _retry = Timer(
      Duration(milliseconds: seconds * 1000 + jitter),
      () => unawaited(_open()),
    );
  }

  Future<void> _closeChannel() async {
    final sub = _sub;
    final channel = _channel;
    _sub = null;
    _channel = null;
    await sub?.cancel();
    // Sans attendre la poignée de fermeture : sur un réseau mort, elle ne
    // vient jamais.
    unawaited(channel?.sink.close());
  }

  void _set(LiveStatus state) {
    // Arrêtée : seul l'état « au repos » reste possible.
    if (!_wanted && state != LiveStatus.idle) return;
    if (_state == state) return;
    _state = state;
    if (!_status.isClosed) _status.add(state);
  }

  static Future<StreamChannel<Object?>> _webSocket(Uri uri) async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    return channel;
  }
}
