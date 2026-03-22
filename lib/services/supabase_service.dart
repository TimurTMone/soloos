import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase client.
/// All modules access Supabase through this single service.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static String? get userId => client.auth.currentUser?.id;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ── Auth ─────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    if (res.user != null && displayName != null) {
      await client.from('profiles').upsert({
        'id': res.user!.id,
        'display_name': displayName,
      });
    }
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => client.auth.signOut();

  // ── Generic CRUD helpers ─────────────────────────────────────────────────

  /// Fetch all rows for the current user from a table.
  static Future<List<Map<String, dynamic>>> getAll(String table,
      {String orderBy = 'created_at', bool ascending = false}) async {
    final data = await client
        .from(table)
        .select()
        .order(orderBy, ascending: ascending);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Insert a row. Automatically adds user_id.
  static Future<Map<String, dynamic>> insert(
      String table, Map<String, dynamic> row) async {
    row['user_id'] = userId;
    final data = await client.from(table).insert(row).select().single();
    return Map<String, dynamic>.from(data);
  }

  /// Update a row by id.
  static Future<void> update(
      String table, String id, Map<String, dynamic> fields) async {
    fields['updated_at'] = DateTime.now().toIso8601String();
    await client.from(table).update(fields).eq('id', id);
  }

  /// Delete a row by id.
  static Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  /// Upsert a row (insert or update).
  static Future<void> upsert(
      String table, Map<String, dynamic> row) async {
    row['user_id'] = userId;
    await client.from(table).upsert(row);
  }
}
