import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  final Logger _logger = Logger('PermissionService');
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  Future<bool> requestStoragePermission() async {
    // Временно упростим для теста
    _logger.info('Запрос разрешений');
    
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    }
    
    return true;
  }
  
  Future<bool> checkPermissions() async {
    _logger.info('Проверка разрешений');
    
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status == PermissionStatus.granted;
    }
    
    return true;
  }
  
  Future<PermissionStatus> getCurrentPermissionStatus() async {
    if (Platform.isAndroid) {
      return await Permission.storage.status;
    }
    return PermissionStatus.granted;
  }
  
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
  
  Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Доступ к файлам'),
        content: const Text('Приложению нужен доступ к файлам для поиска книг.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Разрешить'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
  
  Future<void> openAppSettingsWithInstruction(BuildContext context) async {
    await openAppSettings();
  }
}