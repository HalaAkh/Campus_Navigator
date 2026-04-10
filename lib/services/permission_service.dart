import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBluetoothAndLocation() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );
  }

  static Future<bool> hasPermissions() async {
    final bt = await Permission.bluetoothScan.status;
    final loc = await Permission.locationWhenInUse.status;
    return bt.isGranted && loc.isGranted;
  }
}
