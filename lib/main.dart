import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const ACControlScreen(), theme: ThemeData(primarySwatch: Colors.blue));
  }
}

class ACControlScreen extends StatefulWidget {
  const ACControlScreen({super.key});
  @override
  State<ACControlScreen> createState() => _ACControlScreenState();
}

class _ACControlScreenState extends State<ACControlScreen> {
  final _db = FirebaseDatabase.instance.ref();
  double temp = 0, threshold = 24;
  int cooldown = 0;
  bool acStatus = false;

  @override
  void initState() {
    super.initState();
    _db.onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        temp = data['temperature']?.toDouble() ?? 0;
        threshold = data['threshold']?.toDouble() ?? 24;
        acStatus = data['ac_status'] ?? false;
        cooldown = data['cooldown'] ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCountingDown = acStatus && temp < threshold;

    return Scaffold(
      appBar: AppBar(title: const Text("FPMIPA C Energy Saver")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${temp.toStringAsFixed(1)}°C", style: TextStyle(fontSize: 60, color: Colors.cyan)),
            Text("Suhu Ruangan", style: TextStyle(fontSize: 18)),
            const Divider(height: 50),
            
            // AC Toggle Switch
            Transform.scale(
              scale: 1.5,
              child: Switch(
                value: acStatus,
                onChanged: (val) => _db.update({'ac_status': val}),
                activeColor: Colors.blue,
              ),
            ),
            // Indikator Status AC
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ac_unit, color: acStatus ? Colors.blue : Colors.grey),
                Text(" Status AC: ${acStatus ? 'ON' : 'OFF'}", 
                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              ],
            ),

            const SizedBox(height: 50),

            // Cooldown Timer Display
            if (isCountingDown) ...[
              const Icon(Icons.timer, color: Colors.orange, size: 40),
              Text("Hemat Energi Aktif!", style: TextStyle(color: Colors.orange)),
              Text("Otomatis mati dlm: $cooldown detik", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: 40),

            // Threshold Slider
            Text("Matikan Otomatis Jika di Bawah: ${threshold.toInt()}°C"),
            Slider(
              value: threshold, min: 16, max: 30,
              divisions: 14,
              onChanged: (val) => _db.update({'threshold': val.toInt()}),
            ),
          ],
        ),
      ),
    );
  }
}