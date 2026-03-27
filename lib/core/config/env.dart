/// Configurações de ambiente do Camelo Pro.
///
/// Centraliza todas as variáveis de ambiente (Supabase, etc.)
/// para facilitar troca entre dev/staging/prod no futuro.
class Env {
  Env._();

  // ── Supabase ──────────────────────────────────────────────
  static const String supabaseUrl = 'https://mfuzzjdnzsvkebvzolpw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mdXp6amRuenN2a2VidnpvbHB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NzI2MTIsImV4cCI6MjA5MDE0ODYxMn0.'
      'bb2S2bI6NGpWD1x7Gf4HMM5JNcFM4tpC5m4fJmS13NM';

  // ── App ───────────────────────────────────────────────────
  static const String appName = 'Camelo Pro';
  static const String appVersion = '1.0.0';
}
