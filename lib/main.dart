import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ble_service.dart';
import 'padel_machine_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BLEService()),
        ChangeNotifierProvider(create: (context) => PadelMachineSettings()),
      ],
      child: const PadelTrainerApp(),
    ),
  );
}

class PadelTrainerApp extends StatelessWidget {
  const PadelTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel Trainer',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'),
      ],
      locale: const Locale('he', 'IL'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
        actions: [
          Consumer<BLEService>(
            builder: (context, ble, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'סוללה: ${ble.batteryLevel}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Increased bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConnectionCard(),
            SizedBox(height: 20),
            SettingsForm(),
            SizedBox(height: 30),
            ActionButtons(),
          ],
        ),
      ),
    );
  }
}

class SettingsForm extends StatelessWidget {
  const SettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<PadelMachineSettings>(
          builder: (context, settings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('הגדרות', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                
                _buildDropdown<StrokeType>(
                  'סוג מכה',
                  settings.strokeType,
                  StrokeType.values,
                  (val) {
                    debugPrint('UI: StrokeType changed to $val');
                    settings.strokeType = val!;
                  },
                  (val) => val.label,
                ),
                
                _buildDropdown<PlayMode>(
                  'מצב',
                  settings.playMode,
                  PlayMode.values,
                  (val) {
                    debugPrint('UI: PlayMode changed to $val');
                    settings.playMode = val!;
                  },
                  (val) => val.label,
                ),
                
                /*_buildDropdown<Direction>(
                  'כיוון',
                  settings.direction,
                  Direction.values,
                  (val) => settings.direction = val!,
                  (val) => val.label,
                ),

                _buildDropdown<Spin>(
                  'Spin',
                  settings.spin,
                  Spin.values,
                  (val) => settings.spin = val!,
                  (val) => val.label,
                ),

                _buildDropdown<Height>(
                  'גובה',
                  settings.height,
                  Height.values,
                  (val) => settings.height = val!,
                  (val) => val.label,
                ),*/

                _buildDropdown<SideDistribution>(
                  'חלוקת צד',
                  settings.sideDistribution,
                  SideDistribution.values,
                      (val) {
                        debugPrint('UI: SideDistribution changed to $val');
                        settings.sideDistribution = val!;
                      },
                      (val) => val.label,
                ),

                _buildDropdown<ServeSide>(
                  'צד',
                  settings.side,
                  ServeSide.values,
                      (val) {
                        debugPrint('UI: ServeSide changed to $val');
                        settings.side = val!;
                      },
                      (val) => val.label,
                ),

                const SizedBox(height: 10),
                Text('כיוון: ${settings.direction}'),
                Slider(
                  value: settings.direction,
                  min: 210, max: 2070, divisions: 62,
                  onChanged: (val) {
                    debugPrint('UI: Direction changed to $val');
                    settings.direction = val;
                  },
                ),

                const SizedBox(height: 10),
                Text('Spin: ${settings.spin}'),
                Slider(
                  value: settings.spin,
                  min: 0, max: 30, divisions: 3,
                  onChanged: (val) {
                    debugPrint('UI: Spin changed to $val');
                    settings.spin = val;
                  },
                ),

                const SizedBox(height: 10),
                Text('גובה: ${settings.height}'),
                Slider(
                  value: settings.height,
                  min: 300, max: 4200, divisions: 13,
                  onChanged: (val) {
                    debugPrint('UI: Height changed to $val');
                    settings.height = val;
                  },
                ),

                const SizedBox(height: 10),
                Text('מהירות: ${settings.speed}'),
                Slider(
                  value: settings.speed,
                  min: 80, max: 180, divisions: 10,
                  onChanged: (val) {
                    debugPrint('UI: Speed changed to $val');
                    settings.speed = val;
                  },
                ),

                const SizedBox(height: 10),
                Text('זמן בין כדור לכדור: ${settings.timeInterval} שניות'),
                Slider(
                  value: settings.timeInterval,
                  min: 1.8,
                  max: 8.8,
                  divisions: 70,
                  onChanged: (val) {
                    debugPrint('UI: TimeInterval changed to $val');
                    settings.timeInterval = val;
                  },
                ),

                const SizedBox(height: 10),
                Text('כמות כדורים: ${settings.ballCount}'),
                Slider(
                  value: settings.ballCount.toDouble(),
                  min: 1,
                  max: 50,
                  onChanged: (val) {
                    debugPrint('UI: BallCount changed to $val');
                    settings.ballCount = val.toInt();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged, String Function(T) itemLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BLEService>(
      builder: (context, ble, child) {
        bool isConnected = ble.connectionState == BluetoothConnectionState.connected;
        
        return Card(
          color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? 'מצב: מחובר' : 'מצב: מנותק',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isConnected ? Colors.green : Colors.red,
                            ),
                          ),
                          if (isConnected)
                            Text(
                              'מכשיר: ${ble.connectedDevice?.platformName ?? ble.connectedDevice?.remoteId.toString() ?? "לא ידוע"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: ble.isScanning 
                        ? null 
                        : (isConnected ? () {
                            debugPrint('UI: Disconnect button pressed');
                            ble.disconnect();
                          } : () {
                            debugPrint('UI: Connect button pressed');
                            ble.startScan();
                          }),
                      child: Text(isConnected ? 'התנתק' : 'התחבר'),
                    ),
                  ],
                ),
                if (ble.isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BLEService, PadelMachineSettings>(
      builder: (context, ble, settings, child) {
        bool isConnected = ble.connectionState == BluetoothConnectionState.connected;
        
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: isConnected ? () {
                  debugPrint('UI: Send to machine button pressed');
                  ble.sendSettings(settings);
                } : null,
                child: const Text('שלח למכונה', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: isConnected ? () {
                debugPrint('UI: Stop machine button pressed');
                ble.stopMachine();
              } : null,
              icon: const Icon(Icons.stop),
              color: Colors.white,
              iconSize: 30,
            ),
          ],
        );
      },
    );
  }
}