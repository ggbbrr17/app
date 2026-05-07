import 'dart:io'; // For File operations
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
  
  // Capturador de errores de bajo nivel (sin dependencia de MaterialApp)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.white,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Text(
            "🚨 FALLO CRÍTICO:\n${details.exception}",
            style: const TextStyle(color: Colors.black, fontSize: 13, decoration: TextDecoration.none, fontFamily: 'monospace'),
            textAlign: TextAlign.center,
          ),
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
    final baseRadius = size.width * 0.35;
    
    // Pulsing and morphing logic
    final pulse = math.sin(animationValue * 2 * math.pi) * 0.05;
    final morph = isThinking ? math.sin(animationValue * 4 * math.pi) * 0.1 : 0.0;
    final currentRadius = baseRadius * (1.0 + pulse + morph + (isPressed ? 0.1 : 0.0));

    // 1. Shadow / Glow
    final glowColor = isRecording 
        ? Colors.redAccent 
        : (isThinking ? Colors.cyanAccent : Colors.white);
        
    final shadowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, currentRadius + 10, shadowPaint);

    // 2. Base Sphere (Translucent White)
    final spherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isRecording ? Colors.redAccent : Colors.white).withValues(alpha: 0.8),
          (isRecording ? Colors.red.shade900 : Colors.white).withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));
    
    canvas.drawCircle(center, currentRadius, spherePaint);

    // 3. Specular Highlight (The "Glass" look)
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.1, 0.5],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius * 0.9, highlightPaint);
    
    // 4. Subtle Rim Light
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(center, currentRadius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant GlassOrbPainter oldDelegate) => true;
}

class MeshGradientBackground extends StatelessWidget {
  final Animation<double> animation;
  const MeshGradientBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Base Gradient
            Container(color: const Color(0xFF0A0A0F)),
            
            // Animated Blobs
            _buildBlob(context, const Color(0xFF1A237E), 0.2, 0.3, 1.5), // Deep Blue
            _buildBlob(context, const Color(0xFFC6FF00), 0.7, 0.6, 1.2), // Lime Green
            _buildBlob(context, const Color(0xFF7B1FA2), 0.4, 0.8, 1.8), // Violet
            
            // Frosted Glass Layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlob(BuildContext context, Color color, double x, double y, double sizeMult) {
    final size = MediaQuery.of(context).size;
    final t = animation.value * 2 * math.pi;
    
    // Movement logic
    final dx = math.sin(t + x * 10) * 50;
    final dy = math.cos(t + y * 10) * 50;
    
    return Positioned(
      left: (x * size.width) + dx - (150 * sizeMult),
      top: (y * size.height) + dy - (150 * sizeMult),
      child: Container(
        width: 300 * sizeMult,
        height: 300 * sizeMult,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.0)],
          ),
        ),
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
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  AppLifecycleState _notificationState = AppLifecycleState.resumed;

  // New state variables for menu
  bool _isMenuOpen = false;
  late AnimationController _menuAnimationController;
  late Animation<Offset> _menuOffsetAnimation;

  // New state variables for audio recording
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  final AudioRecorder _audioRecorder = AudioRecorder(); // From 'record' package
  final AudioPlayer _audioPlayer = AudioPlayer(); // For water click sound

  // Orb interactivity state
  Offset _orbOffset = Offset.zero;
  bool _isOrbPressed = false;
  bool _showTextField = false; // New: Toggle text field
  
  // History state - Grouped by "Chat Sessions"
  bool _showHistory = false;
  final List<List<Map<String, dynamic>>> _chatSessions = [];

  final String apiUrl = "https://service-cv3f.onrender.com/api/v1/ask";
  final String notificationUrl = "https://service-cv3f.onrender.com/api/v1/notifications";
  final String secret = "glyph123";
  Timer? _notificationPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _initializeNotifications();
      });
    });

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), 
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeOut));

    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkForNotifications();
    });
  }

  Future<void> _checkForNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(notificationUrl),
        headers: {"X-Glyph-Secret": secret},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List notifications = data['notifications'] ?? [];
        if (notifications.isNotEmpty) {
          for (var note in notifications) {
            setState(() {
              _messages.add({
                "role": "glyph", 
                "text": note['message'] ?? "",
                "isThought": note['type'] == "autonomous_thought"
              });
              if (_notificationState != AppLifecycleState.resumed) {
                _showNotification('Glyph (Pensamiento)', note['message'] ?? "");
              }
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint("Error al consultar notificaciones: $e");
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );
      
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      final iosPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint("⚠️ Notificaciones no iniciadas: $e");
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
    const NotificationDetails platformDetails = NotificationDetails(iOS: iosDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _waveController.dispose();
    _menuAnimationController.dispose();
    _notificationPollingTimer?.cancel();
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _notificationState = state;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleMenu() {
    _playWaterSound();
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  void _toggleHistory() {
    _playWaterSound();
    setState(() {
      _showHistory = !_showHistory;
      _isMenuOpen = false;
      if (!_showHistory) {
        _menuAnimationController.reverse();
      }
    });
  }

  Future<void> _playWaterSound() async {
    try {
      await _audioPlayer.play(AssetSource('water_click.mp3'));
    } catch (e) {
      debugPrint("Error al reproducir sonido: $e");
    }
  }

  Future<void> _pickImage() async {
    _playWaterSound();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, 
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileBytes = await File(filePath).readAsBytes();
      final base64String = base64Encode(fileBytes);
      final fileName = result.files.single.name;

      setState(() {
        _isMenuOpen = false; 
        _messages.add({"role": "user", "text": "Imagen adjunta: $fileName"});
        _isThinking = true;
      });
      _scrollToBottom();

      await _sendMultimodalData(
        question: "Interpreta la imagen adjunta: $fileName",
        base64Image: base64String,
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final String path = p.join(tempDir.path, 'glyph_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration = _recordDuration + const Duration(seconds: 1);
          });
        });
      }
    } catch (e) {
      _showError("Error al iniciar grabación: $e");
    }
  }

  Future<String?> _stopRecording() async {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });
    final path = await _audioRecorder.stop();
    if (path != null) {
      final fileBytes = await File(path).readAsBytes();
      return base64Encode(fileBytes);
    }
    return null;
  }

  Future<void> _sendMultimodalData({
    String question = "",
    String? base64Image,
    String? base64Video,
    String? base64Audio,
  }) async {
    if (question.isEmpty && base64Image == null && base64Video == null && base64Audio == null) return;

    setState(() {
      _isThinking = true;
    });
    _scrollToBottom();

    try {
      final Map<String, dynamic> body = {"question": question};
      if (base64Image != null) body["base64_image"] = base64Image;
      if (base64Video != null) body["base64_video"] = base64Video;
      if (base64Audio != null) body["base64_audio"] = base64Audio;

      final response = await http
          .post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json", "X-Glyph-Secret": secret}, body: jsonEncode(body)).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          _showError(data['error'] ?? 'Error servidor');
        } else {
          setState(() {
            if (data['metacognition'] != null && data['metacognition'].toString().isNotEmpty) {
              _messages.add({
                "role": "glyph", 
                "text": data['metacognition'],
                "isThought": true
              });
            }
            _messages.add({"role": "glyph", "text": data['message'] ?? "Sin respuesta."});
            if (_notificationState != AppLifecycleState.resumed) {
              _showNotification('Glyph', data['message'] ?? "Sin respuesta.");
            }
          });
          _scrollToBottom();
        }
      } else {
        _showError('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Enlace fallido: $e');
    } finally {
      setState(() => _isThinking = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() => _messages.add({"role": "user", "text": text}));
    _scrollToBottom();
    await _sendMultimodalData(question: text);
  }

  void _showError(String err) {
    setState(() => _messages.add({"role": "glyph", "text": '⚠️ $err'}));
    _scrollToBottom();
  }

  void _unfocus() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
  }

  void _startNewChat() {
    if (_messages.isNotEmpty) {
      setState(() {
        _chatSessions.add(List.from(_messages));
        _messages.clear();
        _showHistory = false;
        _isMenuOpen = false;
        _menuAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true, 
      body: GestureDetector(
        onTap: _unfocus, 
        child: Stack(
          children: [
            MeshGradientBackground(animation: _waveController),
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg["role"] == "user";
                        final isThought = msg["isThought"] ?? false;
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isThought 
                                ? Colors.cyanAccent.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: isUser ? 0.15 : 0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isThought 
                                  ? Colors.cyanAccent.withValues(alpha: 0.3) 
                                  : Colors.white.withValues(alpha: 0.1)
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isThought)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text("PENSAMIENTO", style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                Text(msg["text"], style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontStyle: isThought ? FontStyle.italic : FontStyle.normal)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showTextField)
                          Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          autofocus: true,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(hintText: "Pregunta a Glyph...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
                                          onSubmitted: (_) => _handleSend(),
                                        ),
                                      ),
                                      IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _handleSend),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onPanUpdate: (details) => setState(() => _orbOffset += details.delta),
                          onPanEnd: (details) => setState(() => _orbOffset = Offset.zero),
                          onTapDown: (_) { _playWaterSound(); setState(() => _isOrbPressed = true); },
                          onTapUp: (_) => setState(() => _isOrbPressed = false),
                          onTap: () => setState(() => _showTextField = !_showTextField),
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressEnd: (_) async {
                            final base64Audio = await _stopRecording();
                            if (base64Audio != null) {
                              setState(() => _messages.add({"role": "user", "text": "Audio enviado para Gemma 4"}));
                              await _sendMultimodalData(question: "Analiza este audio con Gemma 4.", base64Audio: base64Audio);
                            }
                          },
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_pulseController, _waveController]),
                            builder: (context, _) {
                              return CustomPaint(
                                size: const Size(180, 180),
                                painter: GlassOrbPainter(
                                  animationValue: _pulseController.value,
                                  offset: _orbOffset,
                                  isThinking: _isThinking,
                                  isPressed: _isOrbPressed,
                                  isRecording: _isRecording,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: IconButton(
                icon: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _menuAnimationController, color: Colors.white),
                onPressed: _toggleMenu,
              ),
            ),
            if (_isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SlideTransition(
                      position: _menuOffsetAnimation,
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight,
                        decoration: BoxDecoration(color: const Color(0xFF0D0D0F).withValues(alpha: 0.98), border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 100),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Text("GLYPH SOBERANO", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, letterSpacing: 3))),
                            const SizedBox(height: 30),
                            _buildMenuItem(Icons.add_rounded, "Nuevo Chat", _startNewChat),
                            _buildMenuItem(Icons.image_outlined, "Añadir Imagen", _pickImage),
                            _buildMenuItem(Icons.history_rounded, "Historial", _toggleHistory),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_showHistory)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("RECIENTES", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              IconButton(onPressed: _toggleHistory, icon: const Icon(Icons.close_rounded, color: Colors.white)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(30),
                            itemCount: _chatSessions.length,
                            itemBuilder: (context, index) {
                              final session = _chatSessions[index];
                              final title = session.isNotEmpty ? session.first["text"] : "Chat vacío";
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white54, size: 20),
                                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                onTap: () { setState(() { _messages.clear(); _messages.addAll(session); _showHistory = false; }); },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }
}
