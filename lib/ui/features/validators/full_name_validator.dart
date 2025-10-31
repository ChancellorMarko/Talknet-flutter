/// Validador de nome completo
String? fullNameValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O nome completo precisa ser preenchido';
  }
  return null;
}
