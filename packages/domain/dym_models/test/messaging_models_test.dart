import 'package:dym_models/dym_models.dart';
import 'package:test/test.dart';

void main() {
  test('groupe famille (spec 112) : sans boutique, lisible', () {
    final c = Conversation.fromJson(const {
      'id': 'g1',
      'store_id': null,
      'store_name': '',
      'store_origin': null,
      'store_active': true,
      'client_first_name': 'Awa',
      'last_message_at': null,
      'last_message': {
        'id': 'm1',
        'conversation_id': 'g1',
        'author_role': 'client',
        'kind': 'text',
        'body': 'Qui passe au marché ?',
        'created_at': '2026-11-17T10:00:00Z',
        'author_name': 'Mia',
        'mine': false,
        'reactions': [
          {
            'emoji': '👍',
            'count': 1,
            'roles': ['client'],
            'mine': true,
          },
        ],
      },
      'unread': 1,
      'order_id': null,
      'courier_name': null,
      'closed': false,
      'kind': 'family',
      'title': 'La famille',
      'group_offer_id': null,
      'members_count': 3,
    });
    expect(c.isFamily, isTrue);
    expect(c.storeId, '');
    expect(c.groupTitle, 'La famille');
    expect(c.membersCount, 3);
    final m = c.lastMessage!;
    expect(m.authorName, 'Mia');
    expect(m.fromMe(ChatRole.client), isFalse);
    expect(m.reactionOf(ChatRole.client), '👍');
  });
}
