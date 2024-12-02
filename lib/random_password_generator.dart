import 'dart:math';

class PasswordGenerator {
  static String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    String customSymbols = '!@#\$%^&*()-_+=<>?',
  }) {
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';

    String chars = '';
    List<String> requiredChars = [];

    if (includeLowercase) {
      chars += lowercase;
      requiredChars.add(lowercase[Random().nextInt(lowercase.length)]);
    }
    if (includeUppercase) {
      chars += uppercase;
      requiredChars.add(uppercase[Random().nextInt(uppercase.length)]);
    }
    if (includeNumbers) {
      chars += numbers;
      requiredChars.add(numbers[Random().nextInt(numbers.length)]);
    }
    if (includeSymbols) {
      chars += customSymbols;
      requiredChars.add(customSymbols[Random().nextInt(customSymbols.length)]);
    }

    if (chars.isEmpty) {
      throw ArgumentError('At least one character type must be selected');
    }

    Random random = Random.secure();
    List<String> password = List.generate(length - requiredChars.length,
        (_) => chars[random.nextInt(chars.length)]);
    password.addAll(requiredChars);
    password.shuffle();

    return password.join('');
  }
}
