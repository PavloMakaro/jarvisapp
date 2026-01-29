import 'package:flutter/services.dart';

class AndroidTools {
  static const platform = MethodChannel('com.example.flutter_app/tools');

  Future<Map<String, dynamic>> executeTool(String tool, Map<String, dynamic> args) async {
    try {
      final String result = await platform.invokeMethod(tool, args);
      return {'status': 'success', 'result': result};
    } on PlatformException catch (e) {
      return {'status': 'error', 'message': e.message};
    }
  }

  // Helper methods for direct calling if needed
  Future<void> toggleFlashlight(bool on) async {
    await platform.invokeMethod('flashlight', {'state': on ? 'on' : 'off'});
  }
}
