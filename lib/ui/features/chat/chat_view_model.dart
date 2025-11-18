import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/interfaces/chat_repository.dart';
import 'package:image_picker/image_picker.dart';

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

  // --- Novas variáveis para as funcionalidades ---
  Map<String, List<Map<String, dynamic>>> _messageReactions = {};
  Map<String, dynamic> _otherUserPresence = {};
  bool _isOtherUserTyping = false;
  String? _editingMessageId;
  final List<String> _commonEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  // --- Getters Públicos ---
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Novos getters
  Map<String, List<Map<String, dynamic>>> get messageReactions =>
      _messageReactions;
  Map<String, dynamic> get otherUserPresence => _otherUserPresence;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String? get editingMessageId => _editingMessageId;
  List<String> get commonEmojis => _commonEmojis;

  StreamSubscription<List<Map<String, dynamic>>>? _reactionsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _presenceSubscription;
  Timer? _typingTimer;

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
      await _reactionsSubscription?.cancel();
      await _presenceSubscription?.cancel();

      // Começa a ouvir o Stream de mensagens daquela conversa
      _messagesSubscription = chatRepository
          .getMessagesStream(_conversationId!)
          .listen(
            (newMessages) {
              _messages = newMessages;
              _isLoading = false;
              notifyListeners();
            },
            onError: (e) {
              _setError('Erro ao carregar mensagens: $e');
            },
          );

      // Começa a ouvir o Stream de reações
      _reactionsSubscription = chatRepository
          .getReactionsStream(_conversationId!)
          .listen(
            (reactions) {
              _updateReactions(reactions);
            },
            onError: (e) {
              print('Erro no stream de reações: $e');
            },
          );

      // Começa a ouvir o Stream de presença
      _presenceSubscription = chatRepository
          .getPresenceStream([otherUserId])
          .listen(
            (presenceList) {
              _updatePresence(presenceList);
            },
            onError: (e) {
              print('Erro no stream de presença: $e');
            },
          );
    } catch (e) {
      _setError('Erro ao iniciar conversa: $e');
    }
  }

  /// 2. Envia uma mensagem
  Future<void> sendMessage() async {
    final content = textController.text.trim();

    // Se estiver editando, salva a edição
    if (_editingMessageId != null) {
      await saveEditedMessage();
      return;
    }

    // Mensagem normal
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
      updateTypingStatus(false); // Para de digitar
      // Envia para o Supabase (o realtime vai atualizar a lista)
      await chatRepository.sendMessage(messageData);
    } catch (e) {
      _setError('Erro ao enviar: $e');
      // Opcional: recolocar o texto no controller se falhar
      textController.text = content;
    }
  }

  // --- Lógica de Mídia ---

  /// 3. Pega uma imagem da galeria
  Future<void> pickAndSendImage() async {
    if (_conversationId == null) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
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
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
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
      _isLoading = true;
      notifyListeners();

      // 1. Faz o upload (usando o método da Parte 2)
      final publicUrl = await chatRepository.uploadMedia(
        file,
        _conversationId!,
      );

      // 2. Registra a mensagem no banco
      final messageData = {
        'conversation_id': _conversationId!,
        'sender_id': currentUserId,
        'content': null, // Sem texto
        'media_url': publicUrl,
        'media_type': mediaType,
      };
      await chatRepository.sendMessage(messageData);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _setError('Erro ao enviar mídia: $e');
    }
  }

  // --- Novas Funcionalidades: Reações, Edição e Presença ---

  /// 6. Adiciona/remove uma reação em uma mensagem
  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      await chatRepository.toggleReaction(messageId, emoji);
    } catch (e) {
      _setError('Erro ao adicionar reação: $e');
    }
  }

  /// 7. Inicia o modo de edição de uma mensagem
  void startEditingMessage(String messageId, String currentContent) {
    _editingMessageId = messageId;
    textController.text = currentContent;
    textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: currentContent.length,
    );
    notifyListeners();
  }

  /// 8. Cancela a edição de mensagem
  void cancelEditing() {
    _editingMessageId = null;
    textController.clear();
    notifyListeners();
  }

  /// 9. Salva a mensagem editada
  Future<void> saveEditedMessage() async {
    if (_editingMessageId == null) return;

    final newContent = textController.text.trim();
    if (newContent.isEmpty) {
      _setError('Mensagem não pode estar vazia');
      return;
    }

    try {
      await chatRepository.editMessage(_editingMessageId!, newContent);
      _editingMessageId = null;
      textController.clear();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao editar mensagem: $e');
    }
  }

  /// 10. Atualiza o status de digitação do usuário
  void updateTypingStatus(bool isTyping) {
    if (_conversationId == null) return;

    // Debounce: só atualiza se o status mudou após um delay
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await chatRepository.setTypingStatus(_conversationId!, isTyping);
      } catch (e) {
        print('Erro ao atualizar status de digitação: $e');
      }
    });
  }

  // --- Métodos Auxiliares Privados ---

  /// Atualiza as reações localmente quando o stream é atualizado
  void _updateReactions(List<Map<String, dynamic>> reactions) {
    _messageReactions = {};
    for (var reaction in reactions) {
      final messageId = reaction['message_id'] as String;
      if (!_messageReactions.containsKey(messageId)) {
        _messageReactions[messageId] = [];
      }
      _messageReactions[messageId]!.add(reaction);
    }
    notifyListeners();
  }

  /// Atualiza a presença do outro usuário
  void _updatePresence(List<Map<String, dynamic>> presenceList) {
    if (presenceList.isNotEmpty) {
      _otherUserPresence = presenceList.firstWhere(
        (presence) => presence['user_id'] == otherUserId,
        orElse: () => {},
      );

      _isOtherUserTyping =
          _otherUserPresence['typing_in_conversation'] == _conversationId;
    } else {
      _otherUserPresence = {};
      _isOtherUserTyping = false;
    }
    notifyListeners();
  }

  /// Define um erro e notifica os listeners
  void _setError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
    print('ChatViewModel Error: $errorMessage');
  }

  /// Verifica se uma mensagem pode ser editada (dentro de 15 minutos)
  bool canEditMessage(Map<String, dynamic> message) {
    try {
      final createdAt = DateTime.parse(message['created_at'].toString());
      final now = DateTime.now();
      final difference = now.difference(createdAt);

      // Permite edição por até 15 minutos (900 segundos)
      return difference.inSeconds <= 900 &&
          message['sender_id'] == currentUserId;
    } catch (e) {
      return false;
    }
  }

  /// Obtém as reações de uma mensagem específica
  List<Map<String, dynamic>> getReactionsForMessage(String messageId) {
    return _messageReactions[messageId] ?? [];
  }

  /// Verifica se o usuário atual reagiu com um emoji específico
  bool hasUserReactedWith(String messageId, String emoji) {
    final reactions = _messageReactions[messageId] ?? [];
    return reactions.any(
      (reaction) =>
          reaction['user_id'] == currentUserId && reaction['emoji'] == emoji,
    );
  }

  /// Atualiza o status online do usuário atual
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      await chatRepository.setTypingStatus(_conversationId ?? '', false);
      // Notifica que o usuário está online/offline
      // O próprio setTypingStatus já atualiza a tabela user_presence
    } catch (e) {
      print('Erro ao atualizar status online: $e');
    }
  }

  @override
  void dispose() {
    // Dispose dos controllers
    textController.dispose();

    // Cancela todas as subscriptions
    _messagesSubscription?.cancel();
    _reactionsSubscription?.cancel();
    _presenceSubscription?.cancel();

    // Cancela o timer de digitação
    _typingTimer?.cancel();

    // Atualiza o status ao sair do chat
    if (_conversationId != null) {
      chatRepository.setTypingStatus(_conversationId!, false);
    }

    super.dispose();
  }
}
