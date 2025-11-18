import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/interfaces/chat_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository chatRepository;
  final String currentUserId;
  final String otherUserId;

  ChatViewModel({
    required this.chatRepository,
    required this.currentUserId,
    required this.otherUserId,
  });

  // --- Controladores e Estado ---
  final TextEditingController textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _conversationId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  // --- Getters Públicos ---
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Lógica Principal ---

  Future<void> loadConversation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _conversationId = await chatRepository.getOrCreateConversation(
        currentUserId,
        otherUserId,
      );

      await _messagesSubscription?.cancel();
      _messagesSubscription = chatRepository
          .getMessagesStream(_conversationId!)
          .listen((newMessages) {
        _messages = newMessages;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _setError('Erro ao carregar mensagens: $e');
      });
    } catch (e) {
      _setError('Erro ao iniciar conversa: $e');
    }
  }

  Future<void> sendMessage() async {
    final content = textController.text.trim();
    if (content.isEmpty || _conversationId == null) {
      return;
    }

    final messageData = {
      'conversation_id': _conversationId!,
      'sender_id': currentUserId,
      'content': content,
      'media_url': null,
      'media_type': 'text',
    };

    try {
      textController.clear();
      await chatRepository.sendMessage(messageData);
    } catch (e) {
      _setError('Erro ao enviar: $e');
      textController.text = content;
    }
  }

  // --- Lógica de Mídia ---
  Future<void> pickAndSendImage() async {
    // ... (seu código existente, sem mudança)
  }
  Future<void> takeAndSendPhoto() async {
    // ... (seu código existente, sem mudança)
  }
  Future<void> _uploadAndSendMedia(File file, String mediaType) async {
    // ... (seu código existente, sem mudança)
  }

  //
  // --- NOVOS MÉTODOS ADICIONADOS ---
  //

  /// Edita uma mensagem
  Future<void> editMessage(String messageId, String newContent) async {
    if (newContent.trim().isEmpty) {
      // Se o usuário apagar todo o texto, consideramos como "apagar"
      return deleteMessage(messageId);
    }
    try {
      await chatRepository.editMessage(messageId, newContent.trim());
    } catch (e) {
      _setError('Falha ao editar mensagem.');
    }
  }

  /// Apaga uma mensagem
  Future<void> deleteMessage(String messageId) async {
    try {
      await chatRepository.deleteMessage(messageId);
    } catch (e) {
      _setError('Falha ao apagar mensagem.');
    }
  }

  // --- Helpers ---
  void _setError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
    print(errorMessage);
  }

  @override
  void dispose() {
    textController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}