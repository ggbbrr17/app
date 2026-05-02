import 'dart:ui';
import 'dart:io'; // For File operations
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';

void main() => runApp(const GlyphMobileApp());

class GlyphMobileApp extends StatelessWidget {
  const GlyphMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glyph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false),
      home: const ChatScreen(),
    );
  }
}

class MorphingBlobPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isThinking;

  MorphingBlobPainter(this.animationValue, this.color, this.isThinking);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();

    const int points = 8;
    for (int i = 0; i <= points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final amp = isThinking ? 18.0 : 6.0;
      final speedMultiplier = isThinking ? 2.0 : 1.0;
      final deformation = math.sin(animationValue * 2 * math.pi * speedMultiplier + i) * amp;
      final currentRadius = radius + deformation;
      final x = center.dx + math.cos(angle) * currentRadius;
      final y = center.dy + math.sin(angle) * currentRadius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MorphingBlobPainter oldDelegate) => true;
}

class MeshGradientBackground extends StatelessWidget {
  final Animation<double> animation;
  const MeshGradientBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // movimiento ralentizado y orgánico
          final a = animation.value;
          return Stack(
            children: [
              // Fondo Gris Niebla Profundo (Elegante y profesional)
              Container(color: const Color(0xFF050505)),

              // Luz Aurora Boreal (más luminosa e interactiva)
              Align(
                alignment: Alignment(
                  math.sin(a * 2 * math.pi) * 0.9, 
                  math.cos(a * 2 * math.pi * 0.7),
                ),
                child: Container(
                  width: 700,
                  height: 700,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF00FBFF).withValues(alpha: 0.6), const Color(0xFF00FBFF).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),

              // Luz Plasma Lima (derecha)
              Align(
                alignment: Alignment(
                  math.cos(a * 2 * math.pi * 0.5), 
                  math.sin(a * 2 * math.pi * 1.2),
                ),
                child: Container(
                  width: 800,
                  height: 800,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFFCCFF00).withValues(alpha: 0.5), const Color(0xFFCCFF00).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),

              // Luz Éter Violeta (suave y luminosa)
              Align(
                alignment: Alignment(
                  math.sin(a * 2 * math.pi * 0.8), 
                  math.cos(a * 2 * math.pi * 0.4),
                ),
                child: Container(
                  width: 1200,
                  height: 1200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFFBD00FF).withValues(alpha: 0.55), const Color(0xFFBD00FF).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),

              // Refinado Blur para elegancia profesional
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ],
          );
        },
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
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();
  String _lastResponse = "";
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late AnimationController _disintegrateController;
  late AnimationController _entryController;
  late Animation<double> _entryScale;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _bubbleAlive = true;
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

  final String apiUrl = "https://service-cv3f.onrender.com/api/v1/ask";
  final String secret = "glyph123";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _disintegrateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _entryScale = CurvedAnimation(parent: _entryController, curve: Curves.elasticOut);
    _entryController.forward();

    // Initialize menu animation controller
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start off-screen to the left
      end: Offset.zero, // End at its natural position
    ).animate(CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeOut));
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(iOS: initializationSettingsDarwin);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings).catchError((e) {
      debugPrint('Notification init error: $e');
      return false;
    });
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
    _rotationController.dispose();
    _waveController.dispose();
    _disintegrateController.dispose();
    _menuAnimationController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    _entryController.dispose();
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

  // New methods for menu
  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  // New methods for file picking
  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media, // Allows images and videos
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileBytes = await File(filePath).readAsBytes();
      final base64String = base64Encode(fileBytes);
      final fileName = result.files.single.name;

      String? base64Image;
      String? base64Video;

      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png') || fileName.endsWith('.gif')) {
        base64Image = base64String;
      } else if (fileName.endsWith('.mp4') || fileName.endsWith('.mov') || fileName.endsWith('.avi')) {
        base64Video = base64String;
      } else {
        _showError("Tipo de archivo no soportado para interpretación: $fileName");
        return;
      }

      setState(() {
        _isMenuOpen = false; // Close menu after selection
        _messages.add({"role": "user", "text": "Adjunto: $fileName"});
        _isThinking = true;
      });
      _scrollToBottom();

      await _sendMultimodalData(
        question: "Interpreta el archivo adjunto: $fileName",
        base64Image: base64Image,
        base64Video: base64Video,
      );
    }
  }

  // New methods for audio recording
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: 'audio.m4a'); // Or a temporary path
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

  // Modified _handleSend to _sendMultimodalData
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
          .post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json", "X-Glyph-Secret": secret}, body: jsonEncode(body)).timeout(const Duration(seconds: 60)); // Increased timeout for large files

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          _showError(data['error'] ?? 'Error servidor');
        } else {
          setState(() {
            _messages.add({"role": "glyph", "text": data['message'] ?? "Sin respuesta."});
            _lastResponse = data['message'] ?? "";
            if (_notificationState != AppLifecycleState.resumed) {
              _showNotification('Glyph', _lastResponse);
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

  // Original _handleSend now calls _sendMultimodalData
  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    
    setState(() {
      _isExpanded = false;
      _lastResponse = "";
      _messages.add({"role": "user", "text": text});
    });

    _scrollToBottom();
    await _sendMultimodalData(question: text);
  }

  void _showError(String err) {
    setState(() {
      _messages.add({"role": "glyph", "text": '⚠️ $err'});
      _lastResponse = 'Error: $err'; // Ahora el usuario podrá verlo en la burbuja
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          MeshGradientBackground(animation: _waveController),
          
          // Menú Hamburguesa Profesional (Esquina superior izquierda)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: IconButton(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 22, height: 2, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 5),
                  Container(width: 18, height: 2, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 5),
                  Container(width: 22, height: 2, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                ],
              ),
              onPressed: _toggleMenu,
            ),
          ),

          // Menú Lateral Dinámico con Glassmorphism
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SlideTransition(
                      position: _menuOffsetAnimation,
                      child: Container(
                        width: screenWidth * 0.7,
                        height: screenHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0C).withValues(alpha: 0.9),
                          border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 80),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                              child: Text("GLYPH MENU", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                              leading: const Icon(Icons.perm_media_outlined, color: Colors.white),
                              title: const Text("Agregar Imagen/Video", style: TextStyle(color: Colors.white)),
                              onTap: _pickMedia,
                            ),
                          ],
                        ),
                      ),
                    ), // Closes SlideTransition
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Column( // Cambiado a MainAxisSize.max implícito por Expanded
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg["role"] == "user";
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    msg["text"],
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, // Closes itemBuilder
                  ), // Closes ListView.builder
                ),
                
                // Audio recording indicator
                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.4 + (0.6 * _pulseController.value)), shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text("REC: ${_recordDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_recordDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}", 
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                  ),

                GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else {
                      setState(() {
                        _isExpanded = true;
                        _isMenuOpen = false;
                      });
                    }
                  },
                  onDoubleTap: () => setState(() => _bubbleAlive = !_bubbleAlive),
                  onLongPressStart: (details) async {
                    if (!_isExpanded) {
                      await _startRecording();
                    }
                  },
                  onLongPressEnd: (details) async {
                    if (_isRecording) {
                      final base64Audio = await _stopRecording();
                      if (base64Audio != null) {
                        setState(() {
                          _messages.add({"role": "user", "text": "Audio adjunto."});
                          _isThinking = true;
                        });
                        _scrollToBottom();
                        await _sendMultimodalData(question: "Interpreta el audio adjunto.", base64Audio: base64Audio);
                      }
                    }
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _rotationController, _waveController, _entryController, _disintegrateController]),
                    builder: (context, _) {
                      final pulse = _pulseController.value;
                      final scale = _isExpanded ? 1.0 : (1.0 + (pulse * 0.08)) * _entryScale.value;
                      final dis = _disintegrateController.value;
                      return Transform.scale(
                        scale: scale * (1.0 - 0.65 * dis),
                        child: Opacity(
                          opacity: 1.0 - dis,
                          child: Container(
                            width: _isExpanded ? screenWidth * 0.92 : 120,
                            height: _isExpanded ? 75 : 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_isExpanded ? 24 : 60),
                              color: _isExpanded ? Colors.black.withValues(alpha: 0.5) : (_isRecording ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04)),
                              boxShadow: [
                                if (!_isExpanded) BoxShadow(
                                  color: _isRecording ? Colors.redAccent.withValues(alpha: 0.2) : (_isThinking ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)), 
                                  blurRadius: _isThinking ? 35 : 20, 
                                  spreadRadius: (pulse * 4) + (_isRecording ? 2 : 0)
                                ),
                              ],
                              border: Border.all(color: Colors.white.withValues(alpha: _isRecording ? 0.4 : (_isThinking ? 0.4 : 0.1)), width: 0.7),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_isExpanded ? 24 : 60),
                              child: Stack(
                                children: [
                                  if (!_isExpanded)
                                    Align(
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                                child: CustomPaint(
                                                    painter: MorphingBlobPainter(
                                                        _waveController.value,
                                                        _isRecording
                                                            ? Colors.redAccent
                                                                .withValues(alpha: 0.5)
                                                            : (_isThinking
                                                                ? Colors.white.withValues(alpha: 0.7)
                                                                : Colors.white.withValues(alpha: 0.18)),
                                                        _isThinking || _isRecording))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (_isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Center(
                                        child: TextField(
                                          controller: _controller,
                                          autofocus: true,
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                                          decoration: const InputDecoration(
                                            hintText: '',
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                          ),
                                          onSubmitted: (_) async {
                                            await _disintegrateController.forward();
                                            await _handleSend();
                                            _disintegrateController.reset();
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
