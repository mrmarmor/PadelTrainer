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
  Timer? _batteryTimer;

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
    debugPrint('BLE: Starting scan...');
    if (_isScanning) {
      debugPrint('BLE: Already scanning, ignoring.');
      return;
    }

    await requestPermissions();

    _isScanning = true;
    notifyListeners();

    try {
      // Web Bluetooth API דורש requestDevice() עם user gesture
      if (kIsWeb) {
        await _scanWeb();
      } else {
        await _scanMobile();
      }
    } catch (e) {
      print('Scan error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _scanWeb() async {
    debugPrint('BLE: Starting Web scan...');
    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          debugPrint('BLE: Found device: ${r.device.platformName} (${r.device.remoteId})');
          if (r.device.platformName.contains("PT") ||
              r.advertisementData.serviceUuids.contains(Guid(serviceUuid))) {
            debugPrint('BLE: Target machine found, connecting...');
            connectToDevice(r.device);
            FlutterBluePlus.stopScan();
            break;
          }
        }
      });
    } catch (e) {
      debugPrint('BLE: Web scan error: $e');
    }
  }

  Future<void> _scanMobile() async {
    debugPrint('BLE: Starting Mobile scan...');
    //FlutterBluePlus.startScan(timeout: const Duration(seconds: 30), withServices: [Guid(serviceUuid)]);
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

    FlutterBluePlus.scanResults.listen((results) {
      debugPrint('BLE: Found devices: ${results.length}');
      for (ScanResult r in results) {
        debugPrint('BLE: Found device: ${r.device.platformName} (${r.device.remoteId})');
        if (r.device.platformName.contains("PT")) {
          debugPrint('BLE: Target machine found, connecting...');
          connectToDevice(r.device);
          FlutterBluePlus.stopScan();
          break;
        }
      }
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
    debugPrint('BLE: Connecting to ${device.platformName} (${device.remoteId})...');
    try {
      await device.connect(timeout: const Duration(seconds: 35), license: License.nonprofit);
      _connectedDevice = device;
      debugPrint('BLE: Connected to ${device.platformName}');

      _connectionSubscription = device.connectionState.listen((state) {
        debugPrint('BLE: Connection state changed to: $state');
        _connectionState = state;
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('BLE: Device disconnected unexpectedly.');
          _cleanupConnection();
        }
        notifyListeners();
      });

      debugPrint('BLE: Discovering services...');
      List<BluetoothService> services = await device.discoverServices();

      // ⭐⭐⭐ הדפס את כל Services
      debugPrint('========== DEVICE: ${device.platformName} ==========');
      debugPrint('Total Services: ${services.length}');
      for (var service in services) {
        debugPrint('\n🔵 SERVICE UUID: ${service.uuid}');
        for (var char in service.characteristics) {
          debugPrint('   📝 Characteristic: ${char.uuid}');
          debugPrint('      Read: ${char.properties.read}, Write: ${char.properties.write}, Notify: ${char.properties.notify}');

          final svc = service.uuid.toString().toLowerCase();
          final chr = char.uuid.toString().toLowerCase();
          if (svc == serviceUuid.substring(4, 8) && chr == notifyUuid.substring(4, 8)) {
            debugPrint('   ✅ enabling notifications on fff1...');
            await char.setNotifyValue(true);
            _notifySubscription = char.onValueReceived.listen(_handleNotification);

            //ask for battery level every 10 seconds:
            await requestBattery();
            _batteryTimer?.cancel();
            _batteryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
              requestBattery();
            });
          }
        }
      }
      debugPrint('==========================================\n');
    } catch (e) {
      debugPrint("BLE: Connection error: $e");
      _cleanupConnection();
    }
  }

  void _handleNotification(List<int> data) {
    debugPrint('BLE: Received Notification: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    if (data.length >= 6 && data[0] == 0xBB && data[1] == 0x03) {
      _batteryLevel = data[2];
      debugPrint('BLE: Battery level updated: $_batteryLevel%');
      notifyListeners();
    }
  }

  void _cleanupConnection() {
    debugPrint('BLE: Cleaning up connection...');
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectedDevice = null;
    _connectionState = BluetoothConnectionState.disconnected;
    _batteryLevel = 0;
    notifyListeners();
  }

  Future<void> disconnect() async {
    debugPrint('BLE: Manually disconnecting...');
    await _connectedDevice?.disconnect();
    _cleanupConnection();
  }

  Future<void> sendSettings(PadelMachineSettings settings) async {
    debugPrint('BLE: Preparing to send settings...');
    debugPrint('Settings: Speed=${settings.speed}, Interval=${settings.timeInterval}, Spin=${settings.spin}, Direction=${settings.direction}, Height=${settings.height}, Mode=${settings.playMode}');
    
    if (_connectedDevice == null || _connectionState != BluetoothConnectionState.connected) {
      debugPrint('BLE: Cannot send settings - device not connected.');
      return;
    }

    // Implementation of Pusun protocol commands
    // AA [Command] [Data] [End]
    
    // 1. Set Velocity (0x63) - Map 0.0-1.0 to 80-180(the real values)
    //int velocity = (80 + (settings.speed * 100)).toInt();
    await _writeCommand(0x63, [settings.speed.toInt(), 0, 0, 0, 0, 0]);

    // 2. Set Frequency (0x61) - Map 1-5s to 18-88. 1s -> 10, 5s -> 50. the real range is 18-88.
    //int freq = (settings.timeInterval * 10).clamp(18, 88);
    await _writeCommand(0x61, [(settings.timeInterval*10).toInt(), 0, 0, 0, 0, 0]);

    // 3. Set Spin (0x62)
    //int spinType = 1; // 0-none, 1-top, 2-back
    //int spinValue = 0;
    /*switch (settings.spin) {
      case Spin.none: spinType = 0; spinValue = 0; break;
      case Spin.topLight: spinValue = 10; break;
      case Spin.topMedium: spinValue = 20; break;
      case Spin.topHeavy: spinValue = 30; break;
    }*/
    await _writeCommand(0x62, [settings.spin == 0? 0:1, settings.spin.toInt(), 0, 0, 0, 0]);

    // 3.5 Set Position (0x6C)
    int lr = settings.direction.toInt();//settings.side == ServeSide.left ? 210 : 2070;
    int ud = settings.height.toInt();
    //if (settings.height == Height.low) ud = 500;
    //if (settings.height == Height.high) ud = 4000;

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

    //ensure protocol contains 10 bytes: AA(permanent start) + command + 7 data + A5(permanent start)
    final payload = List<int>.filled(7, 0);
    for (int i = 0; i < data.length && i < 7; i++) {
      payload[i] = data[i] & 0xFF;
    }
    final packet = [0xAA, command, ...payload, 0xA5];

//    List<int> packet = [0xAA/*permanent start*/, command, ...data, 0xA5/*permanent end*/];
    debugPrint('BLE: Writing Command [0x${command.toRadixString(16).padLeft(2, '0')}]: ${packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    
    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    bool written = false;
    for (var service in services) {
      if (serviceUuid.substring(4, 8) == service.uuid.toString()) {
        for (var char in service.characteristics) {
          if (writeUuid.substring(4, 8) == char.uuid.toString()) {
            try {
              await char.write(packet, withoutResponse: false);
              written = true;
              debugPrint('BLE: Packet written successfully.');
              await Future.delayed(const Duration(milliseconds: 50)); // docs say send every 50ms
            } catch (e) {
              debugPrint('BLE: Error writing packet: $e');
            }
          }
        }
      }
    }
    if (!written) {
      debugPrint('BLE: ERROR - Write characteristic not found or write failed.');
    }
  }

  Future<void> requestBattery() async {
    await _writeCommand(0x67, []);   // → aa 67 00 00 00 00 00 00 00 a5
  }

  Future<void> stopMachine() async {
    debugPrint('BLE: Sending STOP command...');
    _batteryTimer?.cancel();
    _batteryTimer = null;
    await _writeCommand(0x6B, [0, 0, 0, 0, 0, 0]);
  }
}