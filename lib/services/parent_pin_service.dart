import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentPinService {
  static const String pinEnabledKey = 'pin_enabled';
  static const String pinCodeKey = 'pin_code';

  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pinEnabledKey) ?? false;
  }

  static Future<String> getPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(pinCodeKey) ?? '';
  }

  static Future<void> savePinSettings({
    required bool enabled,
    required String pinCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pinEnabledKey, enabled);
    await prefs.setString(pinCodeKey, pinCode);
  }

  static Future<bool> requestPinIfNeeded(BuildContext context) async {
    final enabled = await isPinEnabled();
    if (!enabled) return true;

    final savedPin = await getPinCode();
    if (savedPin.isEmpty) return false;

    final controller = TextEditingController();
    bool isCorrect = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('PIN код'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Въведи PIN',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Отказ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == savedPin) {
                  isCorrect = true;
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    return isCorrect;
  }
}