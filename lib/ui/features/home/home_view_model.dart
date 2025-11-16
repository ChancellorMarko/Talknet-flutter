import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/interfaces/home_repository.dart';
import 'package:flutter_talknet_app/services/home_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this.homeRepository) {
    _homeService = HomeService();
  }

  final HomeRepository homeRepository;
  late final HomeService _homeService;

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUserData;
  bool _isLoading = true;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get users => _users;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters de dados do usuário
  String get currentUserName {
    return _currentUserData?['full_name'] as String? ?? _homeService.getCurrentUserName();
  }

  String get currentUserAvatar {
    return _currentUserData?['avatar_url'] as String;
  }

  // Setters privados
  void _setUsers(List<Map<String, dynamic>> value) {
    _users = value;
    notifyListeners();
  }

  void _setCurrentUserData(Map<String, dynamic>? value) {
    _currentUserData = value;
    notifyListeners();
  }

  void _setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Verifica se o usuário está autenticado
  bool checkAuthentication() {
    return _homeService.isUserAuthenticated();
  }

  /// Carrega os dados iniciais (usuário atual + lista de usuários)
  Future<void> loadInitialData() async {
    try {
      _setIsLoading(true);
      _setError(null);

      final currentUserId = _homeService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Carregar dados do usuário atual e lista de usuários em paralelo
      final results = await Future.wait([
        homeRepository.getCurrentUserData(currentUserId),
        homeRepository.getUsers(currentUserId),
      ]);

      _setCurrentUserData(results[0] as Map<String, dynamic>?);
      _setUsers(results[1]! as List<Map<String, dynamic>>);
      _setIsLoading(false);
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      _setError('Erro ao carregar usuários');
      _setIsLoading(false);
      rethrow;
    }
  }

  /// Recarrega apenas a lista de usuários
  Future<void> reloadUsers() async {
    try {
      _setIsLoading(true);
      _setError(null);

      final currentUserId = _homeService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      final users = await homeRepository.getUsers(currentUserId);
      _setUsers(users);
      _setIsLoading(false);
    } catch (e) {
      debugPrint('Erro ao recarregar usuários: $e');
      _setError('Erro ao carregar usuários');
      _setIsLoading(false);
      rethrow;
    }
  }

  /// Faz logout do usuário
  Future<void> logout() async {
    await _homeService.logout();
  }

  /// Retorna dados de um usuário específico da lista
  Map<String, dynamic>? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user['id'] == userId);
    } catch (e) {
      return null;
    }
  }
}