import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela de perfil do usuário
class ProfileScreen extends StatefulWidget {
  /// Construtor da classe [ProfileScreen]
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? avatarUrl;
  File? selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    super.dispose();
  }

  /// Carrega os dados do perfil do usuário
  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showError('Usuário não autenticado');
        return;
      }

      // Buscar perfil existente
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          nameController.text = response['full_name'] ?? '';
          bioController.text = response['bio'] ?? '';
          ageController.text = response['age']?.toString() ?? '';
          avatarUrl = response['avatar_url'];
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      setState(() => _isLoading = false);
      _showError('Erro ao carregar perfil: ${e.toString()}');
    }
  }

  /// Seleciona uma imagem da galeria
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
        debugPrint('Imagem selecionada: ${image.path}');
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      _showError('Erro ao selecionar imagem: ${e.toString()}');
    }
  }

  /// Tira uma foto com a câmera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          selectedImage = File(photo.path);
        });
        debugPrint('Foto tirada: ${photo.path}');
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      _showError('Erro ao tirar foto: ${e.toString()}');
    }
  }

  /// Mostra opções de escolha de imagem
  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolher foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF03A9F4),
                ),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF03A9F4)),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (avatarUrl != null || selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedImage = null;
                      avatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Faz upload da imagem para o Supabase Storage
  Future<String?> _uploadImage() async {
    if (selectedImage == null) return avatarUrl;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('Iniciando upload da imagem...');

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$timestamp.jpg';
      final filePath = '$userId/$fileName';

      debugPrint('Caminho do arquivo: $filePath');

      // Ler os bytes do arquivo
      final bytes = await selectedImage!.readAsBytes();
      debugPrint('Tamanho do arquivo: ${bytes.length} bytes');

      // Remover foto antiga se existir
      if (avatarUrl != null && avatarUrl!.isNotEmpty) {
        try {
          final oldPath = avatarUrl!.split('/').last;
          await Supabase.instance.client.storage.from('avatars').remove([
            '$userId/$oldPath',
          ]);
          debugPrint('Foto antiga removida');
        } catch (e) {
          debugPrint('Erro ao remover foto antiga: $e');
          // Continua mesmo se não conseguir remover
        }
      }

      // Upload do arquivo
      final uploadPath = await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      debugPrint('Upload concluído: $uploadPath');

      // Obter URL pública
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      debugPrint('URL pública: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Erro detalhado no upload: $e');
      rethrow;
    }
  }

  /// Salva o perfil do usuário
  Future<void> _saveProfile() async {
    // Validações
    if (nameController.text.trim().isEmpty) {
      _showError('Por favor, digite seu nome completo');
      return;
    }

    if (ageController.text.isNotEmpty) {
      final age = int.tryParse(ageController.text);
      if (age == null || age < 13 || age > 120) {
        _showError('Por favor, digite uma idade válida (13-120)');
        return;
      }
    }

    if (bioController.text.length > 200) {
      _showError('A bio deve ter no máximo 200 caracteres');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('Salvando perfil do usuário: $userId');

      // Upload da imagem se houver (PRIMEIRO)
      String? imageUrl = avatarUrl;
      if (selectedImage != null) {
        debugPrint('Fazendo upload da nova imagem...');
        imageUrl = await _uploadImage();
        debugPrint('Nova URL da imagem: $imageUrl');
      }

      // Preparar dados do perfil
      final profileData = {
        'full_name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'age': ageController.text.isNotEmpty
            ? int.parse(ageController.text)
            : null,
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Dados do perfil: $profileData');

      // Verificar se o perfil já existe
      final existingProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Atualizar perfil existente
        debugPrint('Atualizando perfil existente...');
        await Supabase.instance.client
            .from('profiles')
            .update(profileData)
            .eq('id', userId);
      } else {
        // Criar novo perfil
        debugPrint('Criando novo perfil...');
        await Supabase.instance.client.from('profiles').insert({
          'id': userId,
          ...profileData,
        });
      }

      debugPrint('Perfil salvo com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Aguardar um momento para o usuário ver a mensagem
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
      _showError('Erro ao salvar perfil: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Exibe mensagem de erro
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: const Color(0xFF03A9F4),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com gradiente
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF03A9F4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Colors.white,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : (avatarUrl != null && avatarUrl!.isNotEmpty
                                      ? NetworkImage(avatarUrl!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            selectedImage == null &&
                                (avatarUrl == null || avatarUrl!.isEmpty)
                            ? Text(
                                nameController.text.isNotEmpty
                                    ? nameController.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF03A9F4),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isSaving ? null : _showImageOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF03A9F4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Color(0xFF03A9F4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Toque no ícone para alterar a foto',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Formulário
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações Pessoais',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomInput(
                    label: 'Nome Completo',
                    hint: 'Digite seu nome completo',
                    controller: nameController,
                  ),
                  const SizedBox(height: 16),

                  CustomInput(
                    label: 'Idade',
                    hint: 'Digite sua idade',
                    controller: ageController,
                  ),
                  const SizedBox(height: 16),

                  CustomInput(
                    label: 'Bio',
                    hint: 'Conte um pouco sobre você',
                    controller: bioController,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    '${bioController.text.length}/200 caracteres',
                    style: TextStyle(
                      fontSize: 12,
                      color: bioController.text.length > 200
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botão de salvar
                  _isSaving
                      ? const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Salvando perfil...'),
                            ],
                          ),
                        )
                      : CustomButton(
                          buttonText: 'Salvar Alterações',
                          backgroundColor: AppColors.primaryBlue,
                          buttonAction: _saveProfile,
                        ),

                  const SizedBox(height: 16),

                  // Informações adicionais
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF03A9F4),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Seu perfil será visível para outros usuários',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
