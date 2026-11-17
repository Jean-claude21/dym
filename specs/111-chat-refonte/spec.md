# Feature Specification: Chat refait de bout en bout

**Feature Branch**: `feat/111-chat-refonte`

**Created**: 2026-11-17

**Status**: Done

**Input**: Demande du porteur (2026-11-17) : « Le chat est à refaire de bout en bout : l'ergonomie
et la manière. Un vocal en cours, on doit voir les secondes ; une vidéo doit être lue dans le chat
directement. On doit répondre à un message, envoyer un document, des émojis, et tout ce qu'il
faut. » Il n'y a pas de maquette : le porteur a délégué la conception (« je conçois et je vérifie sur
capture »). Features : C-chat, V-chat, L-chat (messagerie des trois apps, specs 015, 035, 070, 099,
109).

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Répondre à un message : on glisse la bulle vers la droite, ou appui long puis
  « Répondre ». Un bandeau « Réponse à … » apparaît au-dessus du champ et le message part avec la
  citation. La citation garde l'auteur et un extrait (« Photo », le nom du document…).
- **US2 (P1)** Vocal : tenir le micro pour enregistrer. Les secondes défilent (0:07), avec une onde
  du micro. On glisse à gauche pour annuler, vers le haut pour verrouiller. Un simple tap ouvre un
  enregistrement verrouillé (gants, accessibilité). Un vocal dure 60 s au plus. À la lecture :
  pause et reprise, onde qui avance, temps écoulé, vitesse 1×, 1,5× ou 2×.
- **US3 (P1)** La vidéo se lit dans la bulle : rien n'est chargé avant le tap (réseau 3G). On a la
  pause, la progression, le son coupé et le plein écran. Une photo s'ouvre en plein écran et se
  zoome.
- **US4 (P1)** Envoyer un document : PDF, Word, Excel, PowerPoint, OpenDocument, texte ou CSV, de
  10 Mo au plus. La bulle montre le nom, la taille et le type, et le document s'ouvre d'un tap.
- **US5 (P1)** Émojis : un panneau maison (visages, gestes, cœurs, puis fruits, légumes et
  cuisine) remplace le clavier.
- **US6 (P1)** Réactions : un appui long affiche six réactions rapides, plus toute la grille. Chaque
  personne a une seule réaction ; refaire la même la retire. Les réactions s'affichent sous la bulle
  avec leur nombre.
- **US7 (P1)** Supprimer : « pour moi » à tout moment ; « pour tout le monde » seulement pour son
  propre message, dans l'heure. La bulle devient alors « Ce message a été supprimé ».
- **US8 (P2)** Transférer un texte, un produit ou une position vers une autre de ses conversations,
  avec la mention « Transféré ». Les photos, vidéos, vocaux et documents restent dans leur
  conversation (vie privée).
- **US9 (P1)** États : ✓ envoyé, ✓✓ reçu par l'app de l'autre personne, ✓✓ en couleur quand c'est
  lu. « Awa écrit… » s'affiche dans l'en-tête. Un séparateur « 3 nouveaux messages » se place à
  l'ouverture.
- **US10 (P2)** Liste des conversations : filtres Toutes, Non lues et Commandes. Les fils d'une
  commande en cours sont épinglés en tête.
- **US11 (P2)** Dans une conversation : recherche (textes, documents, produits, avec le mot
  surligné) et « Médias et documents » (onglets).

## Requirements *(mandatory)*

- **FR-001** Migration 0100 :
  - type de message `file` ;
  - `reply_to`, `deleted_at`, `forwarded` ;
  - tables `message_reactions` et `message_hides` (RLS, aucun accès direct) ;
  - `*_delivered_at` ;
  - fonctions `react_message`, `delete_message`, `forward_message`, `mark_delivered` et
    `chat_typing` (un signal toutes les 3 s au plus) ;
  - `send_message` avec la citation ; `message_json` qui masque le contenu supprimé ;
  - `conversation`, qui ajoute `peer_delivered_at` et `my_read_at`.
- **FR-002** Function `/v1/conversations/:id/messages` : `kind: file`, `file {name, size, mime}`,
  `reply_to`. Ajout des types de documents à `media-uploads`.
- **FR-003** `dym_platform` :
  - `DocumentPicker` (`file_picker`) ;
  - `InlineVideo` (`video_player`) ;
  - `AudioPlayback` : position, pause et reprise, vitesse.
- **FR-004** `dym_chat` :
  - champ refait (émojis, menu « + » en grille, vocal tenu ou verrouillé) ;
  - bulles : citation, transféré, supprimé, réactions, document, vidéo, vocal ;
  - glisser pour répondre, appui long ;
  - ✓✓ reçus ;
  - « écrit… » ;
  - « Nouveaux messages » ;
  - recherche et galerie ;
  - filtres de la liste.

  Les trois apps branchent les documents.
- **FR-005** Événements serveur :
  - `chat_reaction_added`, `chat_message_deleted` et `chat_message_forwarded` ;
  - `chat_message_sent` compte aussi les documents et indique une réponse.

  Aucun contenu n'est mesuré.

## Success Criteria

- pgTAP 890 (19) passe.
- Les tests des Functions passent : document, citation, type refusé.
- Les tests de `dym_chat` passent (12 nouveaux).
- Le parcours est vérifié sur l'émulateur.

## Hors périmètre (suite annoncée)

- **Groupes** : espace famille et achat groupé. Ce sera la spec suivante.
- **Aperçu d'un vocal avant envoi** : l'interface de lecture ne lit que des liens. Le vocal
  verrouillé s'envoie directement.
