import 'package:supabase_flutter/supabase_flutter.dart';

/// Lazy singleton Supabase client.
///
/// Initialized once in `main.dart` via [Supabase.initialize]. Access via
/// `SupabaseClientWrapper.instance` anywhere in the data layer. This wrapper
/// exists so tests can override the client.
class SupabaseClientWrapper {
  SupabaseClientWrapper._();
  static final SupabaseClientWrapper _instance = SupabaseClientWrapper._();
  static SupabaseClientWrapper get instance => _instance;

  SupabaseClient get client => Supabase.instance.client;
}
