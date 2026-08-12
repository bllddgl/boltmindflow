/// Supabase connection configuration.
///
/// In production, pass these via `--dart-define` at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// As a fallback (dev/preview), the values from `.env` are inlined so the
/// app runs without extra configuration.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ogmbrromezbltwugermj.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9nbWJycm9tZXpibHR3dWdlcm1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4ODE5NTAsImV4cCI6MjA5OTQ1Nzk1MH0.oO_6NbF5llHLWQDGGz2UHiGFby0LJB6aQTcLXxVm6bg',
  );
}
