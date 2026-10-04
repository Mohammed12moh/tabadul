import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://bqdvcotcnjdxbchkqpsl.supabase.co';

  // Publishable key فقط - لا تضع Secret key داخل التطبيق أبداً
  static const String publishableKey =
      'sb_publishable_drGAQy5gGeiIZqbUIDLTUQ_n77VwBM1';

  static Future<void> init() async {
    await Supabase.initialize(url: url, anonKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
