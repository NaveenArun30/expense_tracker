import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../../../services/security_service.dart';

class BiometricAuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricAuthScreen({super.key, required this.onAuthenticated});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final List<String> _enteredPin = [];
  bool _isBioEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final securityService = RepositoryProvider.of<SecurityService>(context);
    final enabled = await securityService.isBiometricsEnabled();
    setState(() {
      _isBioEnabled = enabled;
    });

    if (enabled) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final securityService = RepositoryProvider.of<SecurityService>(context);
    final authenticated = await securityService.authenticateWithBiometrics();
    if (authenticated) {
      widget.onAuthenticated();
    }
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_enteredPin.length < 4) {
        _enteredPin.add(digit);
        _error = null;
      }
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePress() {
    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin.removeLast();
        _error = null;
      }
    });
  }

  Future<void> _verifyPin() async {
    final securityService = RepositoryProvider.of<SecurityService>(context);
    final pin = _enteredPin.join();
    final isValid = await securityService.verifyPin(pin);

    if (isValid) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _enteredPin.clear();
        _error = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Enter PIN',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please verify your identity to continue',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? AppConstants.primaryColor
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 12, // 0-9, bio, delete
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      // Bottom left - Biometrics if enabled
                      return _isBioEnabled
                          ? IconButton(
                              onPressed: _authenticateWithBiometrics,
                              icon: const Icon(Icons.fingerprint, size: 32),
                              color: AppConstants.primaryColor,
                            )
                          : const SizedBox.shrink();
                    }
                    if (index == 11) {
                      // Bottom right - Backspace
                      return IconButton(
                        onPressed: _onDeletePress,
                        icon: const Icon(Icons.backspace_outlined),
                        color: Colors.grey[700],
                      );
                    }

                    // Digits 0-9. index 10 is 0.
                    final digit = index == 10 ? '0' : '${index + 1}';
                    return InkWell(
                      onTap: () => _onDigitPress(digit),
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
