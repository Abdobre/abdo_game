import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseDatabase.instance.databaseURL = 
      "https://abdo-c1d4e-default-rtdb.europe-west1.firebasedatabase.app/";

  runApp(const AbdoGame());
}

class AbdoGame extends StatelessWidget {
  const AbdoGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لعبة عبدو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomController = TextEditingController();

  void _createRoom() {
    String roomId = (1000 + DateTime.now().millisecond % 9000).toString();
    DatabaseReference ref = FirebaseDatabase.instance.ref('rooms/$roomId');

    ref.set({
      'player1': 'Player_1',
      'status': 'waiting',
    }).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(roomId: roomId, playerId: 'player1'),
        ),
      );
    });
  }

  void _joinRoom() {
    String roomId = _roomController.text.trim();
    if (roomId.isEmpty) return;

    DatabaseReference ref = FirebaseDatabase.instance.ref('rooms/$roomId');
    ref.get().then((snapshot) {
      if (snapshot.exists) {
        ref.update({'player2': 'Player_2', 'status': 'playing'});
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(roomId: roomId, playerId: 'player2'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الغرفة غير موجودة!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لعبة عبدو - الرئيسية')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('إنشاء غرفة جديدة', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _roomController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أدخل كود الغرفة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
              ),
              child: const Text('انضمام للغرفة', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
