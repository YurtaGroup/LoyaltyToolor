import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper around SupabaseClient.
/// Call [initialize] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  /// Must match values from your Supabase project dashboard.
  /// TODO: Move to env / --dart-define for production.
  static const _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }
}
