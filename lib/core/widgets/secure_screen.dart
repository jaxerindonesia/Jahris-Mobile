import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecureScreen extends StatefulWidget {
  const SecureScreen({required this.child, super.key});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const _channel = MethodChannel('id.jaxer.jahris_mobile/secure_screen');
  static int _activeScreens = 0;

  @override
  void initState() {
    super.initState();
    _activeScreens++;
    _setSecure(true);
  }

  @override
  void dispose() {
    _activeScreens--;
    if (_activeScreens <= 0) {
      _activeScreens = 0;
      _setSecure(false);
    }
    super.dispose();
  }

  Future<void> _setSecure(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // Platform selain Android tidak memakai FLAG_SECURE.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
