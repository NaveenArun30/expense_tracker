import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_constants.dart';
import '../../services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricsEnabled = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final securityService = context.read<SecurityService>();
    final bioEnabled = await securityService.isBiometricsEnabled();
    final hasPin = await securityService.hasPin();

    if (mounted) {
      setState(() {
        _biometricsEnabled = bioEnabled;
        _hasPin = hasPin;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final securityService = context.read<SecurityService>();
    if (value) {
      final available = await securityService.isBiometricsAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrics not available on this device'),
            ),
          );
        }
        return;
      }
    }

    await securityService.setBiometricsEnabled(value);
    setState(() => _biometricsEnabled = value);
  }

  Future<void> _setPin() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const _SetPinDialog(),
    );

    if (pin != null && mounted) {
      await context.read<SecurityService>().setPin(pin);
      setState(() => _hasPin = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
    }
  }

  Future<void> _removePin() async {
    await context.read<SecurityService>().removePin();
    setState(() {
      _hasPin = false;
      _biometricsEnabled = false; // Disable bio if PIN is removed (as fallback)
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN removed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Security',
          style: TextStyle(color: AppConstants.textOnPrimary),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('PIN Protection'),
                    subtitle: Text(_hasPin ? 'PIN is set' : 'Not configured'),
                    trailing: Switch(
                      value: _hasPin,
                      onChanged: (val) {
                        if (val) {
                          _setPin();
                        } else {
                          _removePin();
                        }
                      },
                      activeColor: AppConstants.primaryColor,
                    ),
                  ),
                  if (_hasPin)
                    ListTile(
                      title: const Text('Change PIN'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _setPin,
                    ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Biometric Authentication'),
                    subtitle: const Text('Use Fingerprint or Face ID'),
                    trailing: Switch(
                      value: _biometricsEnabled,
                      onChanged: _hasPin
                          ? _toggleBiometrics
                          : null, // Require PIN first
                      activeColor: AppConstants.primaryColor,
                    ),
                  ),
                  if (!_hasPin)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Set a PIN first to enable Biometrics.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
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

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog();

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set PIN'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Enter 4-digit PIN',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.length == 4) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
