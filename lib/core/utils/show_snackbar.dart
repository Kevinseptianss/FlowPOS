import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showSnackbar(BuildContext context, String message) {
  // Silent logging for developers, no UI popup as per user preference
  debugPrint('--- [FLOWPOS ALERT] ---');
  debugPrint(message);
  debugPrint('-----------------------');
  
  // ScaffoldMessenger calls removed to hide "ugly" UI snacks
}
