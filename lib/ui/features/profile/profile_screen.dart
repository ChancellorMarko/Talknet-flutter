import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_talknet_app/repositories/implementations/profile_repository_implementation.dart';
import 'package:flutter_talknet_app/ui/features/profile/profile_view_model.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_button.dart';
import 'package:flutter_talknet_app/ui/widgets/custom_input.dart';
import 'package:flutter_talknet_app/utils/style/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela de perfil do usuário
class ProfileScreen extends StatefulWidget {
  /// Construtor da classe [ProfileScreen]
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;

  @override
  Future<void> initState() async {
    super.initState();
    // Inicializar o ViewModel com o repository
    final repository = ProfileRepositoryImplementation(
      supabase: Supabase.instance.client,
    );
    _viewModel = ProfileViewModel(repository);

    // Adicionar listener para atualizar a UI quando o estado mudar
    _viewModel.addListener(_onViewModelChanged);

    // Carregar o perfil
    await _loadProfile();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    try {
      await _viewModel.loadProfile();
    } on Exception catch (e) {
      if (mounted) {
        _showError('Erro ao carregar perfil: $e');
      }
    }
  }

  /// Mostra opções de escolha de imagem
  Future<void> _showImageOptions() async {
    unawaited(showModalBottomSheet(
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
                  color: AppColors.primaryBlue,
                ),
                title: const Text('Galeria'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _viewModel.pickImage();
                  } on Exception catch(e) {
                    if (mounted) {
                      _showError('Erro ao selecionar imagem: $e');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryBlue
                ),
                title: const Text('Câmera'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _viewModel.takePhoto();
                  } on Exception catch(e) {
                    if (mounted) {
                      _showError('Erro ao tirar foto: $e');
                    }
                  }
                },
              ),
              if (_viewModel.avatarUrl != null ||
                  _viewModel.selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewModel.removeImage();
                  },
                ),
            ],
          ),
        ),
      ),
    ));
  }

  /// Salva o perfil
  Future<void> _saveProfile() async {
    try {
      await _viewModel.saveProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    }
  }

  /// Exibe mensagem de erro
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        titleTextStyle: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 24,
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com gradiente
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: AppColors.backgroundWhite,
                        backgroundImage: _viewModel.selectedImage != null
                            ? FileImage(_viewModel.selectedImage!)
                            : (_viewModel.avatarUrl != null &&
                                          _viewModel.avatarUrl!.isNotEmpty
                                      ? NetworkImage(_viewModel.avatarUrl!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            _viewModel.selectedImage == null &&
                                (_viewModel.avatarUrl == null ||
                                    _viewModel.avatarUrl!.isEmpty)
                            ? Text(
                                _viewModel.nameController.text.isNotEmpty
                                    ? _viewModel.nameController.text[0]
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _viewModel.isSaving ? null : _showImageOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.primaryBlue,
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
                      color: AppColors.textWhite,
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
                    controller: _viewModel.nameController,
                  ),
                  const SizedBox(height: 16),

                  CustomInput(
                    label: 'Idade',
                    hint: 'Digite sua idade',
                    controller: _viewModel.ageController,
                  ),
                  const SizedBox(height: 16),

                  CustomInput(
                    label: 'Bio',
                    hint: 'Conte um pouco sobre você',
                    controller: _viewModel.bioController,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    '${_viewModel.bioController.text.length}/200 caracteres',
                    style: TextStyle(
                      fontSize: 12,
                      color: _viewModel.bioController.text.length > 200
                          ? AppColors.error
                          : AppColors.textLight,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botão de salvar
                  if (_viewModel.isSaving)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Salvando perfil...'),
                        ],
                      ),
                    )
                  else
                    CustomButton(
                      buttonText: 'Salvar Alterações',
                      backgroundColor: AppColors.primaryBlue,
                      buttonAction: _saveProfile,
                    ),

                  const SizedBox(height: 16),

                  // Informações adicionais
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.textWhite,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Seu perfil será visível para outros usuários',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textWhite,
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
