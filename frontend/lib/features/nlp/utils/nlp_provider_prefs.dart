import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';

class NlpProviderPrefs {
  static const String _providerKey = 'nlp_provider_selected';

  static String getProvider() {
    final prefs = getIt<SharedPreferences>();
    return prefs.getString(_providerKey) ?? 'huggingface';
  }

  static Future<void> setProvider(String provider) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_providerKey, provider);
  }
}
