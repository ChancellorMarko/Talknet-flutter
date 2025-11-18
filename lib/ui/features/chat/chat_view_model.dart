import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/interfaces/chat_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository chatRepository;
  final String currentUserId;
  final String otherUserId; // ID do usuário com quem estamos conversando

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

  /// 1. Inicializa a conversa
  /// Busca o ID da conversa (ou cria um) e começa a ouvir as mensagens.
  Future<void> loadConversation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Usa a RPC que criamos na Parte 2
      _conversationId = await chatRepository.getOrCreateConversation(
        currentUserId,
        otherUserId,
      );

      // Limpa a inscrição antiga, se houver
      await _messagesSubscription?.cancel();

      // Começa a ouvir o Stream de mensagens daquela conversa
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

  /// 2. Envia uma mensagem
  Future<void> sendMessage() async {
    final content = textController.text.trim();
    if (content.isEmpty || _conversationId == null) {
      return; // Não envia mensagem vazia
    }

    final messageData = {
      'conversation_id': _conversationId!,
      'sender_id': currentUserId,
      'content': content,
      'media_url': null,
      'media_type': 'text',
    };

    try {
      // Limpa o campo de texto IMEDIATAMENTE
      textController.clear();
      // Envia para o Supabase (o realtime vai atualizar a lista)
      await chatRepository.sendMessage(messageData);
    } catch (e) {
      _setError('Erro ao enviar: $e');
      // Opcional: recolocar o texto no controller se falhar
      textController.text = content;
    }
  }

  // --- Lógica de Mídia (Requisito do PDF) ---

  /// 3. Pega uma imagem da galeria
  Future<void> pickAndSendImage() async {
    if (_conversationId == null) return;
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _uploadAndSendMedia(File(image.path), 'image');
      }
    } catch (e) {
      _setError('Erro ao selecionar imagem: $e');
    }
  }

  /// 4. Tira uma foto com a câmera
  Future<void> takeAndSendPhoto() async {
    if (_conversationId == null) return;
    try {
      final XFile? photo =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _uploadAndSendMedia(File(photo.path), 'image');
      }
    } catch (e) {
      _setError('Erro ao tirar foto: $e');
    }
  }

  /// 5. Faz o upload e registra a mensagem de mídia
  Future<void> _uploadAndSendMedia(File file, String mediaType) async {
    if (_conversationId == null) return;

    try {
      // 1. Faz o upload (usando o método da Parte 2)
      final publicUrl =
          await chatRepository.uploadMedia(file, _conversationId!);

      // 2. Registra a mensagem no banco
      final messageData = {
        'conversation_id': _conversationId!,
        'sender_id': currentUserId,
        'content': null, // Sem texto
        'media_url': publicUrl,
        'media_type': mediaType,
      };
      await chatRepository.sendMessage(messageData);
    } catch (e) {
      _setError('Erro ao enviar mídia: $e');
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
    _messagesSubscription?.cancel(); // Muito importante!
    super.dispose();
  }
}