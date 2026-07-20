import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'padel_machine_model.dart';
import 'dart:typed_data';

class BLEService extends ChangeNotifier {
  static const String serviceUuid = "0000fff0-0000-1000-8000-00805f9b34fb";//connect
  static const String writeUuid = "0000fff2-0000-1000-8000-00805f9b34fb";//send
  static const String notifyUuid = "0000fff1-0000-1000-8000-00805f9b34fb";//receive
//  static const String serviceUuid = "d0611e78-bbb4-4591-a5f8-487910ae4366";
//  static const String writeUuid = "8667556c-9a37-4c91-84ed-54ee27d90049";
//  static const String notifyUuid = "8667556c-9a37-4c91-84ed-54ee27d90049";

  BluetoothDevice? _connectedDevice;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  int _batteryLevel = 0;
  bool _isScanning = false;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothConnectionState get connectionState => _connectionState;
  int get batteryLevel => _batteryLevel;
  bool get isScanning => _isScanning;

  StreamSubscription? _connectionSubscription;
  StreamSubscription? _notifySubscription;

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    
    await requestPermissions();
    
    _isScanning = true;
    notifyListeners();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10), withServices: [Guid(serviceUuid)]);
    
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.contains("PT") || r.advertisementData.serviceUuids.contains(Guid(serviceUuid))) {
  //      if (r.advertisementData.serviceUuids.contains(Guid(serviceUuid))) {
          connectToDevice(r.device);
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
  }

  /*Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 35), license: License.nonprofit);
      _connectedDevice = device;

      _connectionSubscription = device.connectionState.listen((state) {
        _connectionState = state;
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
        notifyListeners();
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == notifyUuid) {
              await char.setNotifyValue(true);
              _notifySubscription = char.onValueReceived.listen((value) {
                _handleNotification(value);
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Connection error: $e");
      _cleanupConnection();
    }
  }*/
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 35), license: License.nonprofit);
      _connectedDevice = device;

      _connectionSubscription = device.connectionState.listen((state) {
        _connectionState = state;
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
        notifyListeners();
      });

      List<BluetoothService> services = await device.discoverServices();

      // ⭐⭐⭐ הדפס את כל Services
      debugPrint('========== DEVICE: ${device.platformName} ==========');
      debugPrint('Total Services: ${services.length}');
      for (var service in services) {
        debugPrint('\n🔵 SERVICE UUID: ${service.uuid}');
        for (var char in service.characteristics) {
          debugPrint('   📝 Characteristic: ${char.uuid}');
          debugPrint('      Read: ${char.properties.read}, Write: ${char.properties.write}, Notify: ${char.properties.notify}');
        }
      }
      debugPrint('==========================================\n');

      // ... שאר הקוד
    } catch (e) {
      debugPrint("Connection error: $e");
      _cleanupConnection();
    }
  }

  void _handleNotification(List<int> data) {
    if (data.length >= 6 && data[0] == 0xBB && data[1] == 0x03) {
      _batteryLevel = data[2];
      notifyListeners();
    }
  }

  void _cleanupConnection() {
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectedDevice = null;
    _connectionState = BluetoothConnectionState.disconnected;
    _batteryLevel = 0;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanupConnection();
  }

  Future<void> sendSettings(PadelMachineSettings settings) async {
    if (_connectedDevice == null || _connectionState != BluetoothConnectionState.connected) return;

    // Implementation of Pusun protocol commands
    // AA [Command] [Data] [End]
    
    // 1. Set Velocity (0x63) - Map 0.0-1.0 to 80-180(the real values)
    int velocity = (80 + (settings.speed * 100)).toInt();
    await _writeCommand(0x63, [velocity, 0, 0, 0, 0, 0]);

    // 2. Set Frequency (0x61) - Map 1-5s to 18-88. 1s -> 10, 5s -> 50. the real range is 18-88.
    int freq = (settings.timeInterval * 10).clamp(18, 88);
    await _writeCommand(0x61, [freq, 0, 0, 0, 0, 0]);

    // 3. Set Spin (0x62)
    int spinType = 1; // 0-none, 1-top, 2-back
    int spinValue = 0;
    switch (settings.spin) {
      case Spin.none: spinType = 0; spinValue = 0; break;
      case Spin.topLight: spinValue = 10; break;
      case Spin.topMedium: spinValue = 20; break;
      case Spin.topHeavy: spinValue = 30; break;
    }
    await _writeCommand(0x62, [spinType, spinValue, 0, 0, 0, 0]);

    // 3.5 Set Position (0x6C)
    int lr = settings.side == ServeSide.left ? 210 : 2070;
    int ud = 2200; // Medium
    if (settings.height == Height.low) ud = 500;
    if (settings.height == Height.high) ud = 4000;
    
    await _writeCommand(0x6C, [
      (lr >> 8) & 0xFF, lr & 0xFF,
      (ud >> 8) & 0xFF, ud & 0xFF,
      0, 0
    ]);

    // 4. Start Serving (0x6A)
    // Map stroke types and modes to machine modes
    int machineMode = 1; // 1:fixed, 2:horizontal, 4:random
    if (settings.playMode == PlayMode.random) {
      machineMode = 4;
    } else if (settings.sideDistribution == SideDistribution.alternating) {
      machineMode = 2;
    }
    await _writeCommand(0x6A, [machineMode, 0, 0, 0, 0, 0]);
  }

  Future<void> _writeCommand(int command, List<int> data) async {
    if (_connectedDevice == null) return;
    
    List<int> packet = [0xAA/*permanent start*/, command, ...data, 0xA5/*permanent end*/];
    
    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == writeUuid) {
            await char.write(packet, withoutResponse: true);
            await Future.delayed(const Duration(milliseconds: 50)); // docs say send every 50ms
          }
        }
      }
    }
  }

  Future<void> stopMachine() async {
    await _writeCommand(0x6B, [0, 0, 0, 0, 0, 0]);
  }
}