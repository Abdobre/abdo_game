import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization info: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لعبة الألغاز التعاونية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amber,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  bool _isLoading = false;

  void _createRoom() async {
    String name = _playerNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar("يرجى إدخال اسمك أولاً");
      return;
    }

    setState(() => _isLoading = true);
    String roomId = (1000 + Random().nextInt(9000)).toString();

    List<Map<String, String>> puzzles = [
      {
        'question': 'ما هو الشيء الذي كلما أخذت منه كُبُر؟',
        'hintA': 'تلميح للاعب 1: تجده في الأرض عند الحفر.',
        'hintB': 'تلميح للاعب 2: ليس شيئاً ماديًا تتملكه بل فراغ.',
        'answer': 'الحفرة'
      },
      {
        'question': 'شيء يمكنه اختراق الزجاج دون أن يكسره؟',
        'hintA': 'تلميح للاعب 1: ينزل من السماء في النهار.',
        'hintB': 'تلميح للاعب 2: يضيء المكان بدون صوت.',
        'answer': 'الضوء'
      },
      {
        'question': 'ما هو الشيء الذي يمشي بلا أرجُل ويدخل الأذنين فقط؟',
        'hintA': 'تلميح للاعب 1: ينتقل عبر الهواء في موجات.',
        'hintB': 'تلميح للاعب 2: تسمعه ولا تستطيع لمسه.',
        'answer': 'الصوت'
      }
    ];

    var selectedPuzzle = puzzles[Random().nextInt(puzzles.length)];

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'player1': name,
        'player2': null,
        'status': 'waiting',
        'puzzle': selectedPuzzle,
        'solved': false,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameRoomScreen(
            roomId: roomId,
            playerName: name,
            isPlayer1: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar("تعذر الاتصال بـ Firebase: تأكد من تنزيل google-services.json أو تفعيل شبكة الإنترنت");
    }
  }

  void _joinRoom() async {
    String roomId = _roomIdController.text.trim();
    String playerName = _playerNameController.text.trim();

    if (roomId.isEmpty || playerName.isEmpty) {
      _showSnackBar("يرجى إدخال الاسم ورقم الغرفة المكون من 4 أرقام");
      return;
    }

    setState(() => _isLoading = true);

    try {
      DocumentSnapshot roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!roomDoc.exists) {
        setState(() => _isLoading = false);
        _showSnackBar("الغرفة غير موجودة!");
        return;
      }

      var data = roomDoc.data() as Map<String, dynamic>;
      if (data['player2'] != null) {
        setState(() => _isLoading = false);
        _showSnackBar("الغرفة ممتلئة بالفعل!");
        return;
      }

      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'player2': playerName,
        'status': 'playing',
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameRoomScreen(
            roomId: roomId,
            playerName: playerName,
            isPlayer1: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar("خطأ في الاتصال بالغرفة");
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لعبة الألغاز التعاونية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.extension, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 20),
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(
                labelText: 'اسمك',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _createRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء غرفة جديدة'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                  ),
            const SizedBox(height: 30),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('أو انضم لغرفة'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roomIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم الغرفة (4 أرقام)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _joinRoom,
              icon: const Icon(Icons.login),
              label: const Text('الانضمام للغرفة'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameRoomScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isPlayer1;

  const GameRoomScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isPlayer1,
  });

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  void _sendMessage() {
    String msg = _chatController.text.trim();
    if (msg.isEmpty) return;

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'sender': widget.playerName,
      'text': msg,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _chatController.clear();
  }

  void _submitAnswer(String correctAnswer) async {
    String answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    if (answer.toLowerCase() == correctAnswer.toLowerCase()) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'solved': true});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('إجابة خاطئة! تناقش مع شريكك وجرب ثانيةً.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('غرفة رقم: ${widget.roomId}'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var roomData = snapshot.data!.data() as Map<String, dynamic>?;

          if (roomData == null) {
            return const Center(child: Text('تم إغلاق الغرفة'));
          }

          bool isWaiting = roomData['status'] == 'waiting';
          var puzzle = roomData['puzzle'];
          bool isSolved = roomData['solved'] ?? false;

          if (isWaiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'في انتظار انضمام اللاعب الثاني...\nشارك الكود (${widget.roomId}) مع صديقك',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurpleAccent),
                ),
                child: Column(
                  children: [
                    Text(
                      'اللغز: ${puzzle['question']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.isPlayer1
                            ? puzzle['hintA']
                            : puzzle['hintB'],
                        style: const TextStyle(
                            fontSize: 15, color: Colors.amberAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              if (isSolved)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.green.withOpacity(0.3),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'مبروك! تم حل اللغز بنجاح 🎉',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _answerController,
                          decoration: const InputDecoration(
                            hintText: 'اكتب الإجابة المشتركة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _submitAnswer(puzzle['answer']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('إرسال الحل'),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 25),

              const Text(
                'الدردشة والتنسيق بين اللاعبين 💬',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    if (!chatSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = chatSnapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var msg = docs[index].data() as Map<String, dynamic>;
                        bool isMe = msg['sender'] == widget.playerName;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.deepPurpleAccent
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['sender'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
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
                        controller: _chatController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة لشريكك...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
