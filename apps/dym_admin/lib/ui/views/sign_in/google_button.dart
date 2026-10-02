// Bouton Google : rendu par le SDK Google sur le web (obligatoire sur le
// web), absent ailleurs (tests sur VM).
export 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart';
