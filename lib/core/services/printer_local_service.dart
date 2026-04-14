import 'package:hive_flutter/hive_flutter.dart';

class PrinterSettings {
  final String? deviceName;
  final String? deviceAddress;
  final int charsPerLine;

  PrinterSettings({
    this.deviceName,
    this.deviceAddress,
    this.charsPerLine = 32,
  });
}

class PrinterLocalService {
  static const String _boxName = 'printer_settings';
  static const String _deviceNameKey = 'device_name';
  static const String _deviceAddressKey = 'device_address';
  static const String _charsPerLineKey = 'chars_per_line';

  final Box _box;

  PrinterLocalService(this._box);

  static Future<PrinterLocalService> init() async {
    final box = await Hive.openBox(_boxName);
    return PrinterLocalService(box);
  }

  Future<void> saveSettings({
    required String? deviceName,
    required String? deviceAddress,
    required int charsPerLine,
  }) async {
    await _box.put(_deviceNameKey, deviceName);
    await _box.put(_deviceAddressKey, deviceAddress);
    await _box.put(_charsPerLineKey, charsPerLine);
  }

  PrinterSettings getSettings() {
    return PrinterSettings(
      deviceName: _box.get(_deviceNameKey) as String?,
      deviceAddress: _box.get(_deviceAddressKey) as String?,
      charsPerLine: _box.get(_charsPerLineKey, defaultValue: 32) as int,
    );
  }

  Future<void> clearSettings() async {
    await _box.clear();
  }
}
