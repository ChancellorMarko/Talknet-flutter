/// Validador de email
String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'O email precisa ser preenchido';
  }
  if (!RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(value)) {
    return 'Email inválido';
  }
  return null;
}
