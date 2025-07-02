import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FirebaseErrorHandler {
  static String getError(AppLocalizations l10n, String code) {
    switch (code) {
      case 'invalid-email':
        return l10n.invalidEmail;
      case 'user-disabled':
        return l10n.userDisabled;
      case 'user-not-found':
      case 'wrong-password':
        return l10n.wrongEmailOrPassword;
      case 'too-many-requests':
        return l10n.tooManyRequests;
      case 'network-request-failed':
        return l10n.networkRequestFailed;
      case 'email-already-in-use':
        return l10n.emailAlreadyInUse;
      case 'weak-password':
        return l10n.weakPassword;
      default:
        return l10n.wrongEmailOrPassword;
    }
  }
}