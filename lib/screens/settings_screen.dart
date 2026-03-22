import 'package:flutter/material.dart';
import '../services/parent_pin_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pinEnabled = false;
  String pinCode = '';

  @override
  void initState() {
    super.initState();
    loadPinSettings();
  }

  Future<void> loadPinSettings() async {
    final enabled = await ParentPinService.isPinEnabled();
    final code = await ParentPinService.getPinCode();

    if (!mounted) return;

    setState(() {
      pinEnabled = enabled;
      pinCode = code;
    });
  }

  Future<void> showSetPinDialog({bool isChanging = false}) async {
    final controller = TextEditingController(text: isChanging ? pinCode : '');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isChanging ? 'Смени PIN' : 'Създай PIN'),
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
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) return;

                await ParentPinService.savePinSettings(
                  enabled: pinEnabled,
                  pinCode: value,
                );

                if (!mounted) return;

                setState(() {
                  pinCode = value;
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Запази'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> confirmCurrentPin() async {
    final savedPin = await ParentPinService.getPinCode();

    if (savedPin.isEmpty) return false;

    final controller = TextEditingController();
    bool isCorrect = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Потвърди PIN'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Въведи текущия PIN',
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

  Future<void> togglePin(bool value) async {
    if (value) {
      if (pinCode.isEmpty) {
        setState(() {
          pinEnabled = true;
        });

        await showSetPinDialog();

        await ParentPinService.savePinSettings(
         enabled: true,
          pinCode: pinCode,
        );
      } else {
        setState(() {
          pinEnabled = true;
        });

        await ParentPinService.savePinSettings(
          enabled: true,
          pinCode: pinCode,
        );
      }
    } else {
      final confirmed = await confirmCurrentPin();

      if (!confirmed) {
        if (!mounted) return;

        setState(() {
          pinEnabled = true;
        });
        return;
      }

      setState(() {
        pinEnabled = false;
      });

      await ParentPinService.savePinSettings(
        enabled: false,
        pinCode: pinCode,
      );
    }
  }
  Widget buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSection(
              title: 'Родителски контрол',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Включи PIN защита'),
                    value: pinEnabled,
                    onChanged: togglePin,
                  ),
                  if (pinEnabled) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Смени PIN'),
                      subtitle: const Text(
                        'PIN ще се изисква при промяна на задачи.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showSetPinDialog(isChanging: true),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            buildSection(
              title: 'Профили на деца',
              child: const Text(
                'Тук по-късно ще добавим управление на няколко деца.',
              ),
            ),
            const SizedBox(height: 16),
            buildSection(
              title: 'Език и визуален стил',
              child: const Text(
                'Тук по-късно ще добавим език, тема и други настройки.',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}