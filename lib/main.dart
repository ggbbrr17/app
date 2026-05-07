import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          "🚨 ERROR:\n${details.exception}",
          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

  runZonedGuarded(() {
    runApp(const GlyphMobileApp());
  }, (error, stack) {
    debugPrint("🚨 ERROR ZONED: $error");
  });
}

class GlyphMobileApp extends StatelessWidget {
  const GlyphMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glyph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

class GlassOrbPainter extends CustomPainter {
  final double animationValue;
  final Offset offset;
  final bool isThinking;
  final bool isPressed;
  final bool isRecording;

  GlassOrbPainter({
    required this.animationValue,
    required this.offset,
    this.isThinking = false,
    this.isPressed = false,
    this.isRecording = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + offset;
    final baseRadius = size.width * 0.22; // Orbe más pequeño
    final pulse = math.sin(animationValue * 2 * math.pi) * 0.03;
    final currentRadius = baseRadius * (1.0 + pulse + (isPressed ? 0.1 : 0.0));

    if (isThinking) {
      // --- FIGURA GEOMÉTRICA FUTURISTA (Acoplamiento Elegante) ---
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.cyanAccent.withValues(alpha: 0.7);

      for (int i = 0; i < 3; i++) {
        // Rotación armónica
        final double rotation = animationValue * 2 * math.pi * (i % 2 == 0 ? 1 : -1) + (i * math.pi / 4);
        // Movimiento de acople y desacople
        final double scale = 0.6 + math.sin(animationValue * 4 * math.pi + i).abs() * 0.4;
        final double radius = currentRadius * scale;
        
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(rotation);
        
        // Arcos perfectamente delineados
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          0,
          math.pi * 1.5,
          false,
          paint..strokeWidth = 1.5 - (i * 0.2)..color = Colors.white.withValues(alpha: 0.5 + i * 0.2)
        );
        
        // Hexágono central que gira
        if (i == 1) {
           final Path poly = Path();
           final int sides = 6;
           for(int j=0; j<=sides; j++) {
              final double a = j * 2 * math.pi / sides;
              final Offset p = Offset(math.cos(a) * radius * 0.5, math.sin(a) * radius * 0.5);
              if (j == 0) poly.moveTo(p.dx, p.dy);
              else poly.lineTo(p.dx, p.dy);
           }
           canvas.drawPath(poly, Paint()..style=PaintingStyle.stroke..color=Colors.cyanAccent.withValues(alpha: 0.8)..strokeWidth=0.8);
        }
        
        canvas.restore();
      }
    } else {
      // --- EFECTO REFLEJO DE AGUA ---
      // Gota base con muy baja opacidad
      canvas.drawCircle(center, currentRadius, Paint()..color = Colors.white.withValues(alpha: 0.03)..style = PaintingStyle.fill);

      // Distorsión líquida (anillos sutiles)
      for(int i = 0; i < 3; i++) {
         final double phase = (animationValue * 3 * math.pi) + (i * 2);
         final double r = currentRadius * (0.8 + math.sin(phase) * 0.1);
         canvas.drawCircle(center, r, Paint()..style=PaintingStyle.stroke..color=Colors.cyanAccent.withValues(alpha: 0.05)..strokeWidth=1.5);
      }

      // Reflejo de luz asimétrico
      final glossPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(math.cos(animationValue * 2 * math.pi) * 0.3, math.sin(animationValue * 2 * math.pi) * 0.3),
          colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent],
          radius: 0.7,
        ).createShader(Rect.fromCircle(center: center, radius: currentRadius));
      canvas.drawCircle(center, currentRadius, glossPaint);
      
      // Borde cristalino sutil
      canvas.drawCircle(center, currentRadius, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = Colors.white.withValues(alpha: 0.2));
    }
  }

  @override
  bool shouldRepaint(covariant GlassOrbPainter oldDelegate) => true;
}

class AnimatedHamburger extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const AnimatedHamburger({super.key, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack, top: isOpen ? 23 : 16, child: AnimatedRotation(duration: const Duration(milliseconds: 500), turns: isOpen ? 0.125 : 0, child: Container(width: 26, height: 2.5, color: Colors.white))),
            AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: isOpen ? 0.0 : 1.0, child: Container(width: 16, height: 2.5, color: Colors.white)),
            AnimatedPositioned(duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack, bottom: isOpen ? 23 : 16, child: AnimatedRotation(duration: const Duration(milliseconds: 500), turns: isOpen ? -0.125 : 0, child: Container(width: 26, height: 2.5, color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class MeshGradientBackground extends StatelessWidget {
  final Animation<double> animation;
  const MeshGradientBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value * 2 * math.pi;
        return Container(
          decoration: const BoxDecoration(color: Color(0xFF020204)),
          child: Stack(
            children: [
              _buildAurora(context, const Color(0xFF00E5FF), 0.1, 0.2, t, 1.4),
              _buildAurora(context, const Color(0xFFD4FF00), 0.9, 0.5, t + 2.0, 1.6),
              _buildAurora(context, const Color(0xFF9C27B0), 0.4, 0.8, t + 4.0, 1.5),
              // Reflejo Acuático
              Positioned(
                bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.3,
                child: Opacity(
                  opacity: 0.3,
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.cyanAccent.withValues(alpha: 0.1)])))),
                ),
              ),
              BackdropFilter(filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35), child: Container(color: Colors.black.withValues(alpha: 0.15))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAurora(BuildContext context, Color color, double x, double y, double t, double sizeMult) {
    final size = MediaQuery.of(context).size;
    final dx = math.sin(t) * 150;
    final dy = math.cos(t) * 150;
    return Positioned(
      left: (x * size.width) + dx - (250 * sizeMult),
      top: (y * size.height) + dy - (250 * sizeMult),
      child: Container(
        width: 500 * sizeMult,
        height: 500 * sizeMult,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: 0.55), Colors.transparent], stops: const [0.2, 1.0])),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController, _waveController, _menuAnimationController;
  late Animation<Offset> _menuOffsetAnimation;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  AppLifecycleState _notificationState = AppLifecycleState.resumed;
  bool _isMenuOpen = false, _isRecording = false, _isOrbPressed = false, _showTextField = false, _showHistory = false;
  Offset _orbOffset = Offset.zero;
  Duration _recordDuration = Duration.zero;
  Timer? _timer, _notificationPollingTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _pendingImageBase64, _pendingImageName;
  final List<List<Map<String, dynamic>>> _chatSessions = [];

  final String apiUrl = "https://service-cv3f.onrender.com/api/v1/ask";
  final String notificationUrl = "https://service-cv3f.onrender.com/api/v1/notifications";
  final String secret = "glyph123";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _menuAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _menuOffsetAnimation = Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeOut));
    _initializeNotifications();
    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _checkForNotifications());
  }

  Future<void> _checkForNotifications() async {
    try {
      final r = await http.get(Uri.parse(notificationUrl), headers: {"X-Glyph-Secret": secret});
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        for (var note in (data['notifications'] ?? [])) {
          setState(() {
            _messages.add({"role": "glyph", "text": note['message'] ?? "", "isThought": note['type'] == "autonomous_thought"});
            if (_notificationState != AppLifecycleState.resumed) _showNotification('Glyph', note['message'] ?? "");
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()));
  }

  Future<void> _showNotification(String title, String body) async {
    await flutterLocalNotificationsPlugin.show(0, title, body, const NotificationDetails(iOS: DarwinNotificationDetails()));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _notificationPollingTimer?.cancel();
    _pulseController.dispose(); _waveController.dispose(); _menuAnimationController.dispose();
    _audioPlayer.dispose(); _audioRecorder.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _playWaterSound() async {
    try { await _audioPlayer.play(AssetSource('water_click.mp3')); } catch (_) {}
  }

  Future<void> _pickImage() async {
    _playWaterSound();
    FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null) {
      final bytes = await File(res.files.single.path!).readAsBytes();
      setState(() { _isMenuOpen = false; _showTextField = true; _pendingImageBase64 = base64Encode(bytes); _pendingImageName = res.files.single.name; });
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final path = p.join((await getTemporaryDirectory()).path, 'audio_${DateTime.now().ms}.m4a');
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<String?> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    return path != null ? base64Encode(await File(path).readAsBytes()) : null;
  }

  Future<void> _sendMultimodalData({String question = "", String? base64Image, String? base64Audio}) async {
    setState(() => _isThinking = true);
    try {
      String history = _messages.take(10).map((m) => "${m['role'].toString().toUpperCase()}: ${m['text']}").join("\n");
      final body = {"question": question, "history": history, "base64_image": base64Image, "base64_audio": base64Audio};
      final res = await http.post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json", "X-Glyph-Secret": secret}, body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          if (data['metacognition']?.toString().isNotEmpty ?? false) _messages.add({"role": "glyph", "text": data['metacognition'], "isThought": true});
          _messages.add({"role": "glyph", "text": data['message'] ?? "..."});
        });
        _scrollToBottom();
      }
    } finally { setState(() => _isThinking = false); }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImageBase64 == null) return;
    final img = _pendingImageBase64;
    _unfocus(); // Cierre automático del teclado
    setState(() {
      _messages.add({"role": "user", "text": text, "image": img});
      _pendingImageBase64 = null; _pendingImageName = null;
    });
    _controller.clear();
    _scrollToBottom();
    _sendMultimodalData(question: text, base64Image: img);
  }

  void _startNewChat() {
    if (_messages.isNotEmpty) setState(() { _chatSessions.add(List.from(_messages)); _messages.clear(); _isMenuOpen = false; _menuAnimationController.reverse(); });
  }

  void _unfocus() {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() => _showTextField = false);
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg["role"] == "user";
    final isThought = msg["isThought"] ?? false;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isThought ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: isUser ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isThought ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg["image"] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(msg["image"]), width: 180, fit: BoxFit.cover),
                ),
              ),
            if (msg["text"].toString().isNotEmpty)
              Text(msg["text"], style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontStyle: isThought ? FontStyle.italic : FontStyle.normal)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: GestureDetector(
        onTap: _unfocus,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
          MeshGradientBackground(animation: _waveController),
          Positioned.fill(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 100, bottom: 250),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
            ),
          ),
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedHamburger(isOpen: _isMenuOpen, onTap: _toggleMenu),
                IconButton(icon: Icon(_showHistory ? Icons.chat_bubble : Icons.history, color: Colors.white), onPressed: () => setState(() => _showHistory = !_showHistory)),
              ],
            ),
          ),
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: IgnorePointer(
              ignoring: _showTextField,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _orbOffset += d.delta),
                onPanEnd: (d) => setState(() => _orbOffset = Offset.zero),
                onTap: () {
                  setState(() => _showTextField = !_showTextField);
                  if (_showTextField) _focusNode.requestFocus();
                  else _focusNode.unfocus();
                },
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) async {
                  final audio = await _stopRecording();
                  if (audio != null) _sendMultimodalData(question: "Analiza este audio.", base64Audio: audio);
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showTextField ? 0.0 : 1.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: _showTextField ? 0.5 : 1.0,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => CustomPaint(painter: GlassOrbPainter(animationValue: _pulseController.value, offset: _orbOffset, isThinking: _isThinking, isRecording: _isRecording, isPressed: _isOrbPressed), size: const Size(200, 200)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            bottom: _showTextField ? 100 : 80,
            left: 30, right: 30,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _showTextField ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: _showTextField ? 1.0 : 0.8,
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Totalmente transparente
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: false,
                          onSubmitted: (_) => _handleSend(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: "", // Limpio
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.cyanAccent, size: 22),
                        onPressed: _handleSend,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.black54,
                child: SlideTransition(
                  position: _menuOffsetAnimation,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        ListTile(leading: const Icon(Icons.add, color: Colors.white70), title: const Text("Nuevo Chat", style: TextStyle(color: Colors.white70)), onTap: _startNewChat),
                        ListTile(leading: const Icon(Icons.image, color: Colors.white70), title: const Text("Añadir Imagen", style: TextStyle(color: Colors.white70)), onTap: _pickImage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_showHistory)
            Positioned.fill(
              child: Container(
                color: Colors.transparent, // Totalmente transparente
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("HISTORIAL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          GestureDetector(
                            onTap: () => setState(() => _showHistory = false),
                            child: SizedBox(
                              width: 48, height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(angle: 0.785, child: Container(width: 26, height: 2.5, color: Colors.white)),
                                  Transform.rotate(angle: -0.785, child: Container(width: 26, height: 2.5, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 30), itemCount: _chatSessions.length, itemBuilder: (c, i) => ListTile(contentPadding: EdgeInsets.zero, title: Text(_chatSessions[i].first["text"], style: const TextStyle(color: Colors.white70)), onTap: () => setState(() { _messages.clear(); _messages.addAll(_chatSessions[i]); _showHistory = false; })))),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  void _toggleMenu() { setState(() { _isMenuOpen = !_isMenuOpen; if (_isMenuOpen) _menuAnimationController.forward(); else _menuAnimationController.reverse(); }); }
}

extension DateExt on DateTime { int get ms => millisecondsSinceEpoch; }
