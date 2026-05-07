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
    
    // Animación más lenta (ciclo de 15 segundos en lugar de 1.2)
    final slowAnim = animationValue; 
    final pulse = math.sin(slowAnim * 2 * math.pi) * 0.03;
    final currentRadius = baseRadius * (1.0 + pulse + (isPressed ? 0.1 : 0.0));

    if (isThinking) {
      // NUEVA ANIMACIÓN PENSANDO: Remolino de luz interna
      for (int i = 0; i < 5; i++) {
        final double phase = (slowAnim * 4 * math.pi) + (i * 1.2);
        final double radiusMult = 0.2 + (0.1 * i);
        final swirlOffset = Offset(
          math.sin(phase) * (currentRadius * radiusMult),
          math.cos(phase) * (currentRadius * radiusMult)
        );
        
        canvas.drawCircle(
          center + swirlOffset,
          8.0 - i,
          Paint()
            ..shader = RadialGradient(
              colors: [Colors.cyanAccent.withValues(alpha: 0.4), Colors.transparent],
            ).createShader(Rect.fromCircle(center: center + swirlOffset, radius: 8.0))
        );
      }
    }

    // REFLEJOS VARIABLES (No repetitivos)
    final colors = isRecording 
        ? [Colors.redAccent, Colors.orangeAccent]
        : [Colors.cyanAccent, const Color(0xFFC6FF00), const Color(0xFF7B1FA2)];

    for (int i = 0; i < colors.length; i++) {
      // Uso de frecuencias distintas para evitar repetición obvia
      final double phase = (slowAnim * 2 * math.pi * (1.0 + i * 0.1)) + (i * 2.1);
      final double opacity = (math.sin(phase * 0.7) + 1.0) / 2.0 * 0.25;
      
      final blobOffset = Offset(
        math.sin(phase * 0.6) * (currentRadius * 0.3), 
        math.cos(phase * 0.4) * (currentRadius * 0.3)
      );
      
      final blobPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: opacity),
            colors[i].withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center + blobOffset, radius: currentRadius * 0.8));
      
      canvas.drawCircle(center + blobOffset, currentRadius, blobPaint..blendMode = BlendMode.screen);
    }

    // Bordes de cristal y transparencia premium
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(center, currentRadius, rimPaint);

    // Brillo sutil superior
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));
    canvas.drawCircle(center, currentRadius * 0.9, highlightPaint);
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
            // Línea Superior
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              top: isOpen ? 23 : 16,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 400),
                turns: isOpen ? 0.125 : 0,
                child: Container(width: 26, height: 2, color: Colors.white),
              ),
            ),
            // Línea Central (Desaparece)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isOpen ? 0.0 : 1.0,
              child: Container(width: 14, height: 2, color: Colors.white),
            ),
            // Línea Inferior
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              bottom: isOpen ? 23 : 16,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 400),
                turns: isOpen ? -0.125 : 0,
                child: Container(width: 26, height: 2, color: Colors.white),
              ),
            ),
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
      builder: (context, child) {
        final t = animation.value * 2 * math.pi;
        return Container(
          decoration: const BoxDecoration(color: Color(0xFF050508)),
          child: Stack(
            children: [
              // Aurora Cian
              _buildAurora(context, const Color(0xFF00E5FF), 0.2, 0.3, t, 1.2),
              // Aurora Lima
              _buildAurora(context, const Color(0xFFC6FF00), 0.8, 0.4, t + 2.0, 1.5),
              // Aurora Violeta Etea
              _buildAurora(context, const Color(0xFF7B1FA2), 0.5, 0.7, t + 4.0, 1.8),
              
              // Capa de profundidad final
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAurora(BuildContext context, Color color, double x, double y, double t, double sizeMult) {
    final size = MediaQuery.of(context).size;
    final dx = math.sin(t * 0.5) * 100;
    final dy = math.cos(t * 0.3) * 100;
    
    return Positioned(
      left: (x * size.width) + dx - (200 * sizeMult),
      top: (y * size.height) + dy - (200 * sizeMult),
      child: Container(
        width: 400 * sizeMult,
        height: 400 * sizeMult,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.3), Colors.transparent],
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

  // Pendientes para Multimodal
  String? _pendingImageBase64;
  String? _pendingImageName;

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

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

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
    _notificationPollingTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _menuAnimationController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    WidgetsBinding.instance.removeObserver(this);
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
        _showTextField = true; // Abrimos la barra para que el usuario escriba
        _pendingImageBase64 = base64String;
        _pendingImageName = fileName;
      });
      _scrollToBottom();
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
    if (text.isEmpty && _pendingImageBase64 == null) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    
    final String? imgBase64 = _pendingImageBase64;
    final String? imgName = _pendingImageName;

    setState(() {
      _showTextField = false;
      String userText = text;
      if (imgName != null) userText = "📸 $imgName\n$text";
      _messages.add({"role": "user", "text": userText});
      _pendingImageBase64 = null; // Limpiamos pendientes
      _pendingImageName = null;
    });
    _scrollToBottom();
    await _sendMultimodalData(question: text, base64Image: imgBase64);
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
            // Background Aurora Boreal
            MeshGradientBackground(animation: _waveController),
            
            // Header
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedHamburger(
                    isOpen: _isMenuOpen,
                    onTap: () {
                      setState(() {
                        _isMenuOpen = !_isMenuOpen;
                        if (_isMenuOpen) {
                          _menuAnimationController.forward();
                        } else {
                          _menuAnimationController.reverse();
                        }
                      });
                    },
                  ),
                  if (!_isMenuOpen)
                    IconButton(
                      icon: Icon(
                        _showHistory ? Icons.chat_bubble_outline : Icons.history,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _showHistory = !_showHistory;
                        });
                      },
                    ),
                ],
              ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 100),
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
                            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40),
                            child: Column(
                              children: [
                                if (_pendingImageName != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.image, color: Colors.cyanAccent, size: 16),
                                        const SizedBox(width: 8),
                                        Text(_pendingImageName!, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => setState(() { _pendingImageName = null; _pendingImageBase64 = null; }),
                                          child: const Icon(Icons.close, color: Colors.white54, size: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          autofocus: true,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            hintText: "", 
                                            border: InputBorder.none
                                          ),
                                          onSubmitted: (_) => _handleSend(),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.send_rounded, color: Colors.white70), 
                                        onPressed: _handleSend
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Solo mostramos el Orbe si NO estamos escribiendo y NO estamos pensando (o si estamos pensando pero el texto ya se envió)
                        if (!_showTextField && !_isThinking)
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
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 20, height: 2, color: Colors.white),
                      const SizedBox(height: 5),
                      Container(width: 12, height: 2, color: Colors.white), // Línea corta
                      const SizedBox(height: 5),
                      Container(width: 20, height: 2, color: Colors.white),
                    ],
                  ),
                ),
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
