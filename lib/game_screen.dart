import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String playerId;

  const GameScreen({Key? key, required this.roomId, required this.playerId}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DatabaseReference _roomRef;
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _roomRef = FirebaseDatabase.instance
        .refFromURL("https://abdo-c1d4e-default-rtdb.europe-west1.firebasedatabase.app/")
        .child('rooms/${widget.roomId}');
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    _roomRef.child('messages').push().set({
      'sender': widget.playerId,
      'text': _msgController.text.trim(),
      'timestamp': ServerValue.timestamp,
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('غرفة: ${widget.roomId}')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blueGrey[50],
              child: StreamBuilder(
                stream: _roomRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map data = snapshot.data!.snapshot.value as Map;
                  String p2Status = data['player2'] != null ? "متصل" : "في انتظار اللاعب الثاني...";

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("حالة الشريك: $p2Status", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      widget.playerId == "player1"
                          ? const Text("تلميحك: الرمز الأول هو ⭐", style: TextStyle(fontSize: 18, color: Colors.blue))
                          : const Text("تلميحك: الرقم المالي هو 7", style: TextStyle(fontSize: 18, color: Colors.green)),
                    ],
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: _roomRef.child('messages').onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                        return const Center(child: Text("لا توجد رسائل بعد.. ابدأ التواصل!"));
                      }

                      Map msgsMap = snapshot.data!.snapshot.value as Map;
                      List messages = msgsMap.values.toList();

                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          bool isMe = messages[index]['sender'] == widget.playerId;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[300] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(messages[index]['text'] ?? ''),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: const InputDecoration(
                            hintText: "اكتب رسالة لشريكك...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
