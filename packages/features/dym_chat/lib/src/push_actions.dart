import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';

/// Gestes faits depuis une notification sans ouvrir d'écran (spec 097) :
/// répondre à un message (texte saisi dans la notification), refuser un
/// appel. Vrai si le geste est fait ; sinon l'app ouvre l'écran concerné.
Future<bool> quickChatAction(
  Map<String, String> data, {
  required MessagingRepository messages,
  required CallRepository calls,
}) async {
  final conversation = data['conversation_id'];
  switch (data['action']) {
    case 'reply':
      final text = data['reply']?.trim() ?? '';
      if (conversation == null || text.isEmpty) return false;
      final sent = await messages.sendText(
        conversation,
        text,
        idempotencyKey: Uuid.v4(),
      );
      return sent.isOk;
    case 'decline':
      final call = data['call_id'];
      if (call == null) return false;
      await calls.answer(call, accept: false);
      return true;
  }
  return false;
}
