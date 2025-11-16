import 'package:flutter_talknet_app/repositories/interfaces/home_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository implementention de home repository
class HomeRepositoryImplementation implements HomeRepository {
  /// Construtor de [HomeRepositoryImplementation]
  HomeRepositoryImplementation({required this.supabase});

  /// Instancia do cliente da supabase
  final SupabaseClient supabase;

  @override
  Future<List<Map<String, dynamic>>> getUsers(String currentUserId) async {
    final response = await supabase
        .from('profiles')
        .select('id, full_name, bio, age, avatar_url')
        .neq('id', currentUserId)
        .order('full_name');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserData(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('id, full_name, bio, age, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }
}
